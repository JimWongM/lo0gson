`timescale 1ns / 1ps

module mem(                          // 访存级
    input              clk,          // 时钟
    input              resetn,
    input              MEM_valid,    // 访存级有效信号
    input      [178:0] EXE_MEM_bus_r,// EXE->MEM总线
	input      [35:0]   tlb_mem_bus,
	input              EXE_over,
    output             MEM_over,     // MEM模块执行完成
    output     [168:0] MEM_WB_bus,   // MEM->WB总线
    output     [156:0] MEM_CP0_bus,
	output     [33:0]   mem_tlb_bus,
    //5级流水新增接口
    input              MEM_allow_in, // MEM级允许下级进入
    output     [  4:0] MEM_wdest,    // MEM级要写回寄存器堆的目标地址号
     
	////旁路用到的信号
	output      [ 31:0] MEM_rs_value,     //来自于MEM总线上result的值,decode模块中可能会用到（旁路）
    output              MEM_bypass_en,
	//中断
	input				cancel, 	
    //展示PC
    output     [ 31:0] MEM_pc,
	
	output   data_req,
	output [31:0] vdata_addr,
	input wire dm_load_launched,
	input wire rvalid_dm,
	input wire[255:0] axi_rdata,

	output [31:0]    cache_axi_addr,
	output  [255:0]   cache_axi_wdata,
	output  [3:0]   cache_dm_wen,
	output     cache_axi_wr,
	output   [7:0]   cache_awlen,
	output   [7:0]   cache_arlen
	
);
//-----{EXE->MEM总线}begin
    //访存需要用到的load/store信息
    wire [13 :0] mem_control;  //MEM需要使用的控制信号##########################4.22
    wire [31:0] store_data;   //store操作的存的数据
    
    //EXE结果和HI/LO数据
    wire [31:0] exe_result;
    wire [31:0] hi_result;
	
    wire        hi_write;
    wire        lo_write;
    
    //写回需要用到的信息
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall和eret在写回级有特殊的操作 
    wire       eret;
	wire       Break;//########################4.22
	wire trap;
	wire inst_madd;//7.11 需要使得lo_result 和hi_result 与原来的结果相加	
    wire       rf_wen;    //写回的寄存器写使能
    wire [4:0] rf_wdest;  //写回的目的寄存器
    wire data_related_en;
    wire addr_exc;
	wire ri;
	wire ov_exc;
	wire is_ds;
    //pc
	wire inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR;
	wire [2:0] tlb_fetch_exc;
    wire [31:0] pc;    
    assign {mem_control,
            store_data,
            data_related_en,
            hi_result,
            exe_result,
            hi_write,
            lo_write,
            mfhi,
            mflo,
            mtc0,
            mfc0,
            cp0r_addr,
            syscall,
            eret,
			Break,
			trap,
			addr_exc,
			ri,
			ov_exc,
			is_ds,
			inst_madd,
            rf_wen,
            rf_wdest,
			inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,
			tlb_fetch_exc,
            pc         } = EXE_MEM_bus_r;  
//-----{EXE->MEM总线}end

	 //wire mem_mmu_valid ;


      wire[ 31:0] dm_rdata;     // 访存读数据
      wire    [ 31:0] dm_addr;     // 访存读写地址
      reg  [3:0] dm_wen;       // 访存写使能
      reg[ 31:0] dm_wdata;    // 访存写数据
//-----{load/store访存}begin
    wire inst_load;  //load操作
    wire inst_store; //store操作
    //wire ls_word;    //load/store为字节还是字,0:byte;1:word
    wire lb_sign;    //load一字节为有符号load
	wire lh_sign;//#########################4.21
	wire lb,lh,lw,lwl,lwr;//###########4.24
    wire sw,sh,sb,swl,swr;	//#############4.24
	
    assign {inst_load,inst_store,sw,sh,sb,swl,swr,lb,lh,lw,lwl,lwr,lb_sign,lh_sign} = mem_control;//############4.24
	wire ls_word=sw;
    //访存读写地址
    assign dm_addr = exe_result;
    
	//与MMU有关的控制信号
	wire store_load;
	assign store_load = inst_store | inst_load;
	wire core_valid;//内核态地址
	wire mapped_valid;//映射过的地址
	assign core_valid = (dm_addr[31:30] == 2'b10);
	
	reg [19:0] data_vaddr_hi;
	reg [19:0] data_addr_hi;
	always @(posedge clk)
	begin
		if(!resetn)
		begin	
			data_vaddr_hi <= 20'hbfc00;
			data_addr_hi <= 20'h1fc00;
		end
		else if(tlb_mem_over & ~(|tlb_mem_exc))
		begin
			data_vaddr_hi <= dm_addr[31:12];
			data_addr_hi <= {3'b000,tlb_mem_paddr[28:12]};
		end
	end
	wire [31:0] data_paddr;
	assign data_paddr = core_valid ? {3'b000, dm_addr[28:0]} :
									mapped_valid ? {data_addr_hi,dm_addr[11:0]} : {3'b000,tlb_mem_paddr[28:0]};
	
	
	assign mapped_valid = (data_vaddr_hi == dm_addr[31:12]);
	wire mapped_addr;
	assign mapped_addr = ~(core_valid | mapped_valid);
	wire [31:0] data_vaddr ;//数据的虚地址
	wire tlb_mem_valid ; //有效信号
	assign data_vaddr = dm_addr ;
	assign tlb_mem_valid = MEM_valid & store_load & ~tlb_mem_over & mapped_addr & ~(|final_addr_exc);
	//mmu_mem_valid 有效的时候，即当MEM有效，并且取或者存有效，并且地址不异常，同时MMU级与MEM有关的信号没有结束
	//为了保持数值的稳定，将MEM_over信号传给mmu，只有当MEM结束的时候，才能结束最后的结果
	//assign mmu_mem_valid = MEM_valid & ~mmu_mem_over & (inst_store | inst_load);
	assign mem_tlb_bus = {data_vaddr,tlb_mem_valid,inst_store};
	
	wire tlb_mem_over;
	wire [2:0] tlb_mem_exc;
	wire [31:0] tlb_mem_paddr;
	assign {tlb_mem_over , tlb_mem_exc , tlb_mem_paddr} = tlb_mem_bus;

	//store操作的写使能
    always @ (*)    // 内存写使能信号
    begin
        if (MEM_valid && inst_store&&~cancel&&(final_addr_exc==2'd0)) // 访存级有效时,且为store操作
        begin
            if (ls_word)
            begin
                dm_wen <= 4'b1111; // 存储字指令，写使能全1
            end
            else if(sb)
            begin // SB指令，需要依据地址底两位，确定对应的写使能
                case (dm_addr[1:0])
                    2'b00   : dm_wen <= 4'b0001;
                    2'b01   : dm_wen <= 4'b0010;
                    2'b10   : dm_wen <= 4'b0100;
                    2'b11   : dm_wen <= 4'b1000;
                    default : dm_wen <= 4'b0000;
                endcase
            end
             else if(swl)
            begin // SWL指令，需要依据地址底两位，确定对应的写使能
                case (dm_addr[1:0])
                    2'b00   : dm_wen <= 4'b0001;
                    2'b01   : dm_wen <= 4'b0011;
                    2'b10   : dm_wen <= 4'b0111;
                    2'b11   : dm_wen <= 4'b1111;
                    default : dm_wen <= 4'b0000;
                endcase
            end
             else if(swr)
            begin // SWR指令，需要依据地址底两位，确定对应的写使能
                case (dm_addr[1:0])
                    2'b00   : dm_wen <= 4'b1111;
                    2'b01   : dm_wen <= 4'b1110;
                    2'b10   : dm_wen <= 4'b1100;
                    2'b11   : dm_wen <= 4'b1000;
                    default : dm_wen <= 4'b0000;
                endcase
            end
			else if(sh)//SH
			begin
				case (dm_addr[1])
                    1'b0     : dm_wen <= 4'b0011;
                    1'b1     : dm_wen <= 4'b1100;
                    default   : dm_wen <= 4'b0000;
				endcase
			end			
        end
        else
        begin
            dm_wen <= 4'b0000;
        end
    end 
    
    //store操作的写数据#########################4.23
    always @ (*)  
    begin
        case ({sw,sh,sb,swl,swr,dm_addr[1:0]})//#############增加总线宽度sw sh sb swl swr 
			7'b1000000   : dm_wdata <= store_data;//sw
			7'b0100000   : dm_wdata <= {dm_rdata[31:16], store_data[15:0]};//sh
			7'b0100010   : dm_wdata <= {store_data[15:0], dm_rdata[15:0]};//sh
            7'b0010000   : dm_wdata <= store_data;//sb
            7'b0010001   : dm_wdata <= {dm_rdata[31:16], store_data[7:0], dm_rdata[7:0]};//sb
            7'b0010010   : dm_wdata <= {dm_rdata[31:24], store_data[7:0], dm_rdata[15:0]};//sb
            7'b0010011   : dm_wdata <= {store_data[7:0], dm_rdata[23:0]};  //sb
			7'b0001000   : dm_wdata <= {dm_rdata[31:8],store_data[31:24]};//swl
			7'b0001001   : dm_wdata <= {dm_rdata[31:16],store_data[31:16]};//swl
			7'b0001010   : dm_wdata <= {dm_rdata[31:24],store_data[31:8]};//swl
			7'b0001011   : dm_wdata <= store_data;//swl
			7'b0000100   : dm_wdata <= store_data;//swr
			7'b0000101   : dm_wdata <= {store_data[23:0],dm_rdata[7:0]};//swr
			7'b0000110   : dm_wdata <= {store_data[15:0],dm_rdata[15:0]};//swr
			7'b0000111   : dm_wdata <= {store_data[7:0],dm_rdata[23:0]};//swr
            default : dm_wdata <= store_data;
        endcase
    end
    //######################end

	 wire        load_sign_b;
	 wire        load_sign_h;
	 wire	[31:0]	 lb_result;
	 wire   [31:0]   lh_result;
	 
	 wire   [31:0]   lwl_result;
	 wire   [31:0]   lwr_result;
	 wire   [31:0]   load_result;
	 
	 assign load_sign_b = (dm_addr[1:0]==2'd0) ? dm_rdata[ 7] :
                        (dm_addr[1:0]==2'd1) ? dm_rdata[15] :
                        (dm_addr[1:0]==2'd2) ? dm_rdata[23] : dm_rdata[31] ;
	 assign load_sign_h = (dm_addr[1:0]==2'd0) ? dm_rdata[15] : dm_rdata[31] ;
    assign lb_result[31:8]={24{lb_sign&load_sign_b}};
	 assign lb_result[7:0]=(dm_addr[1:0]==2'd0) ? dm_rdata[ 7:0 ] :
                    (dm_addr[1:0]==2'd1) ? dm_rdata[15:8 ] :
                    (dm_addr[1:0]==2'd2) ? dm_rdata[23:16] :
                                           dm_rdata[31:24] ;
										   
	  assign lh_result[31:16]={16{lh_sign&load_sign_h}};
	  assign lh_result[15:0]=(dm_addr[1:0]==2'd0) ? dm_rdata[ 15:0 ] :dm_rdata[ 31:16 ];
      
	  assign lwl_result=(dm_addr[1:0]==2'd0) ? {dm_rdata[ 7:0 ],store_data[23:0]} :
                (dm_addr[1:0]==2'd1) ? {dm_rdata[ 15:0 ],store_data[15:0]}:
                (dm_addr[1:0]==2'd2) ? {dm_rdata[ 23:0 ],store_data[7:0]}:
                                       dm_rdata[31:0] ;
	  
      assign lwr_result=(dm_addr[1:0]==2'd0) ? dm_rdata[31:0]  :
                (dm_addr[1:0]==2'd1) ? {store_data[31:24],dm_rdata[31:8]}:
                (dm_addr[1:0]==2'd2) ? {store_data[31:16],dm_rdata[31:16]}:
                                       {store_data[31:8],dm_rdata[31:24]};                          
	 //增加总线宽度	lb lh lwl lwr 											  
	  assign load_result=lb?lb_result:lh?lh_result:lwl?lwl_result:lwr?lwr_result:dm_rdata[31:0];
	 
	 
	 //-----{load/store访存}end#########################end


    reg MEM_valid_r;
   always @(posedge clk)
    begin
        if (MEM_allow_in)
        begin
            MEM_valid_r <= 1'b0;
        end
        else
        begin
            MEM_valid_r <= MEM_valid;
        end
    end
	reg cache_over_r;
	wire cache_over;
	always @(posedge clk)
    begin
        if (MEM_allow_in)
        begin
            cache_over_r <= 1'b0;
        end
        else if(cache_over)
        begin
            cache_over_r<= 1'b1;
        end
    end
    //assign MEM_over = inst_load ? MEM_valid_r : MEM_valid;
	//assign MEM_over = cache_over_r;
	assign MEM_over = store_load&(final_addr_exc== 2'b00) ? MEM_valid & (cache_over_r | (|tlb_mem_exc)):MEM_valid;
    //如果数据ram为异步读的，则MEM_valid即是MEM_over信号，
    //即load一拍完成
//-----{MEM执行完成}end

//-----{MEM模块的dest值}begin
   //只有在MEM模块有效时，其写回目的寄存器号才有意义
    assign MEM_wdest = rf_wdest & {5{MEM_valid}};
//-----{MEM模块的dest值}end
 //{inst_load,inst_store,sw,sh,sb,swl,swr,lb,lh,lwl,lwr,lb_sign,lh_sign}
	
	wire lw_addr_exc;
	wire lh_addr_exc;
	wire sw_addr_exc;
	wire sh_addr_exc;
	wire [31:0] badvaddr;
	assign lw_addr_exc = (inst_load &&lw&& (dm_addr[1:0] != 2'b00)) ? 1'b1 : 1'b0;
	assign lh_addr_exc = (inst_load && lh&& (dm_addr[0] != 1'b0)) ? 1'b1 : 1'b0;
	assign sw_addr_exc = (inst_store &&sw&& (dm_addr[1:0] != 2'b00)) ? 1'b1 : 1'b0;
 	assign sh_addr_exc = (inst_store &&sh&& (dm_addr[0] != 1'b0)) ? 1'b1 : 1'b0;
    
	wire [1:0] final_addr_exc;
	assign final_addr_exc = addr_exc ? 2'b11 : (lw_addr_exc|lh_addr_exc) ? 2'b10 : (sw_addr_exc|sh_addr_exc) ? 2'b01 : 2'b00;
	 assign badvaddr = dm_addr;
    
	wire load_addr_exc;
    assign load_addr_exc = 	(final_addr_exc==2'b00) ? 1'b0 : 1'b1;


//-----{MEM->WB总线}begin
    wire [31:0] mem_result; //MEM传到WB的result为load结果或EXE结果
    assign mem_result = inst_load ? load_result : exe_result;
    assign MEM_rs_value = mem_result;
    assign MEM_WB_bus = {inst_madd,rf_wen,rf_wdest,                   // WB需要使用的信号
                         hi_result,                        // 最终要写回寄存器的数据
                         mem_result,                         // 乘法低32位结果，新增
                         hi_write,lo_write,                 // HI/LO写使能，新增
                         mfhi,mflo,                         // WB需要使用的信号,新增
                         mtc0,mfc0,cp0r_addr,syscall,eret,Break,trap, // WB需要使用的信号,新增
						 final_addr_exc,ri,ov_exc, is_ds,badvaddr,
						 tlb_fetch_exc,tlb_mem_exc,inst_store,//传到CP0 和WB 级的异常信号
						 inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,
                         pc};                               // PC值
	assign MEM_CP0_bus = {cp0r_addr,badvaddr,mem_result,syscall,
												Break,trap,final_addr_exc,ov_exc,ri,mtc0,eret,is_ds,
												tlb_fetch_exc,tlb_mem_exc,inst_store,
												inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,pc,data_vaddr};
	
	
	wire Dcache_request;
	assign Dcache_request = MEM_valid & store_load & ~tlb_mem_valid;
	//将rvalid_dm_r锁存一拍					 
/* 	reg rvalid_dm_r;
	always @(posedge clk)
    begin
        if (!resetn)
        begin
            rvalid_dm_r <= 1'b0;
        end
        else if(rvalid_dm)
        begin
            rvalid_dm_r<= 1'b1;
        end
		else
		begin
		 rvalid_dm_r <= 1'b0;
		end
    end */
	
//-----{MEM->WB总线}begin
  Dcache Dcache_module(
	.clk(clk),
	.resetn(resetn),
	
	.EXE_over(EXE_over),
	.MEM_allow_in(MEM_allow_in),
	
	.cache_request(Dcache_request),
	.cache_wr(inst_store),
	.dm_wen(dm_wen),
	.dm_addr(data_paddr),
	.dm_wdata(dm_wdata),
	.data_from_cache(dm_rdata),
	.cache_over(cache_over),
	//.cancel(cancel),
	
	.data_req(data_req),
	.vdata_addr(vdata_addr),
	.dm_load_launched(dm_load_launched),
	.rvalid_dm(rvalid_dm),
	.axi_rdata(axi_rdata), //I,128
	
	//.buffer_wen(buffer_wen),
	//.buffer_data(buffer_data),
	//.is_buffer_full(is_buffer_full),
	.is_sw(sw),
	
	.load_addr_exc(load_addr_exc),
	.cancel(cancel),
	.cache_axi_addr(cache_axi_addr),  //o,32
	.cache_axi_wdata(cache_axi_wdata),//o,128
	.cache_dm_wen(cache_dm_wen),//o,4
     .cache_axi_wr(cache_axi_wr),//o,1
	 .cache_awlen(cache_awlen),
	 .cache_arlen(cache_arlen)
	//output reg cache_over
);
//-----{展示MEM模块的PC值}begin
    assign MEM_pc = pc;
    assign MEM_bypass_en= data_related_en;
	//wire[3:0] dm_final_wen;
	// assign dm_final_wen = dm_wen & {4{~cancel}};
//-----{展示MEM模块的PC值}end


endmodule



