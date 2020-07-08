`timescale 1ns / 1ps

module mem(                          // �ô漶
    input              clk,          // ʱ��
    input              resetn,
    input              MEM_valid,    // �ô漶��Ч�ź�
    input      [178:0] EXE_MEM_bus_r,// EXE->MEM����
	input      [35:0]   tlb_mem_bus,
	input              EXE_over,
    output             MEM_over,     // MEMģ��ִ�����
    output     [168:0] MEM_WB_bus,   // MEM->WB����
    output     [156:0] MEM_CP0_bus,
	output     [33:0]   mem_tlb_bus,
    //5����ˮ�����ӿ�
    input              MEM_allow_in, // MEM�������¼�����
    output     [  4:0] MEM_wdest,    // MEM��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
     
	////��·�õ����ź�
	output      [ 31:0] MEM_rs_value,     //������MEM������result��ֵ,decodeģ���п��ܻ��õ�����·��
    output              MEM_bypass_en,
	//�ж�
	input				cancel, 	
    //չʾPC
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
//-----{EXE->MEM����}begin
    //�ô���Ҫ�õ���load/store��Ϣ
    wire [13 :0] mem_control;  //MEM��Ҫʹ�õĿ����ź�##########################4.22
    wire [31:0] store_data;   //store�����Ĵ������
    
    //EXE�����HI/LO����
    wire [31:0] exe_result;
    wire [31:0] hi_result;
	
    wire        hi_write;
    wire        lo_write;
    
    //д����Ҫ�õ�����Ϣ
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall��eret��д�ؼ�������Ĳ��� 
    wire       eret;
	wire       Break;//########################4.22
	wire trap;
	wire inst_madd;//7.11 ��Ҫʹ��lo_result ��hi_result ��ԭ���Ľ�����	
    wire       rf_wen;    //д�صļĴ���дʹ��
    wire [4:0] rf_wdest;  //д�ص�Ŀ�ļĴ���
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
//-----{EXE->MEM����}end

	 //wire mem_mmu_valid ;


      wire[ 31:0] dm_rdata;     // �ô������
      wire    [ 31:0] dm_addr;     // �ô��д��ַ
      reg  [3:0] dm_wen;       // �ô�дʹ��
      reg[ 31:0] dm_wdata;    // �ô�д����
//-----{load/store�ô�}begin
    wire inst_load;  //load����
    wire inst_store; //store����
    //wire ls_word;    //load/storeΪ�ֽڻ�����,0:byte;1:word
    wire lb_sign;    //loadһ�ֽ�Ϊ�з���load
	wire lh_sign;//#########################4.21
	wire lb,lh,lw,lwl,lwr;//###########4.24
    wire sw,sh,sb,swl,swr;	//#############4.24
	
    assign {inst_load,inst_store,sw,sh,sb,swl,swr,lb,lh,lw,lwl,lwr,lb_sign,lh_sign} = mem_control;//############4.24
	wire ls_word=sw;
    //�ô��д��ַ
    assign dm_addr = exe_result;
    
	//��MMU�йصĿ����ź�
	wire store_load;
	assign store_load = inst_store | inst_load;
	wire core_valid;//�ں�̬��ַ
	wire mapped_valid;//ӳ����ĵ�ַ
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
	wire [31:0] data_vaddr ;//���ݵ����ַ
	wire tlb_mem_valid ; //��Ч�ź�
	assign data_vaddr = dm_addr ;
	assign tlb_mem_valid = MEM_valid & store_load & ~tlb_mem_over & mapped_addr & ~(|final_addr_exc);
	//mmu_mem_valid ��Ч��ʱ�򣬼���MEM��Ч������ȡ���ߴ���Ч�����ҵ�ַ���쳣��ͬʱMMU����MEM�йص��ź�û�н���
	//Ϊ�˱�����ֵ���ȶ�����MEM_over�źŴ���mmu��ֻ�е�MEM������ʱ�򣬲��ܽ������Ľ��
	//assign mmu_mem_valid = MEM_valid & ~mmu_mem_over & (inst_store | inst_load);
	assign mem_tlb_bus = {data_vaddr,tlb_mem_valid,inst_store};
	
	wire tlb_mem_over;
	wire [2:0] tlb_mem_exc;
	wire [31:0] tlb_mem_paddr;
	assign {tlb_mem_over , tlb_mem_exc , tlb_mem_paddr} = tlb_mem_bus;

	//store������дʹ��
    always @ (*)    // �ڴ�дʹ���ź�
    begin
        if (MEM_valid && inst_store&&~cancel&&(final_addr_exc==2'd0)) // �ô漶��Чʱ,��Ϊstore����
        begin
            if (ls_word)
            begin
                dm_wen <= 4'b1111; // �洢��ָ�дʹ��ȫ1
            end
            else if(sb)
            begin // SBָ���Ҫ���ݵ�ַ����λ��ȷ����Ӧ��дʹ��
                case (dm_addr[1:0])
                    2'b00   : dm_wen <= 4'b0001;
                    2'b01   : dm_wen <= 4'b0010;
                    2'b10   : dm_wen <= 4'b0100;
                    2'b11   : dm_wen <= 4'b1000;
                    default : dm_wen <= 4'b0000;
                endcase
            end
             else if(swl)
            begin // SWLָ���Ҫ���ݵ�ַ����λ��ȷ����Ӧ��дʹ��
                case (dm_addr[1:0])
                    2'b00   : dm_wen <= 4'b0001;
                    2'b01   : dm_wen <= 4'b0011;
                    2'b10   : dm_wen <= 4'b0111;
                    2'b11   : dm_wen <= 4'b1111;
                    default : dm_wen <= 4'b0000;
                endcase
            end
             else if(swr)
            begin // SWRָ���Ҫ���ݵ�ַ����λ��ȷ����Ӧ��дʹ��
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
    
    //store������д����#########################4.23
    always @ (*)  
    begin
        case ({sw,sh,sb,swl,swr,dm_addr[1:0]})//#############�������߿��sw sh sb swl swr 
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
	 //�������߿��	lb lh lwl lwr 											  
	  assign load_result=lb?lb_result:lh?lh_result:lwl?lwl_result:lwr?lwr_result:dm_rdata[31:0];
	 
	 
	 //-----{load/store�ô�}end#########################end


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
    //�������ramΪ�첽���ģ���MEM_valid����MEM_over�źţ�
    //��loadһ�����
//-----{MEMִ�����}end

//-----{MEMģ���destֵ}begin
   //ֻ����MEMģ����Чʱ����д��Ŀ�ļĴ����Ų�������
    assign MEM_wdest = rf_wdest & {5{MEM_valid}};
//-----{MEMģ���destֵ}end
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


//-----{MEM->WB����}begin
    wire [31:0] mem_result; //MEM����WB��resultΪload�����EXE���
    assign mem_result = inst_load ? load_result : exe_result;
    assign MEM_rs_value = mem_result;
    assign MEM_WB_bus = {inst_madd,rf_wen,rf_wdest,                   // WB��Ҫʹ�õ��ź�
                         hi_result,                        // ����Ҫд�ؼĴ���������
                         mem_result,                         // �˷���32λ���������
                         hi_write,lo_write,                 // HI/LOдʹ�ܣ�����
                         mfhi,mflo,                         // WB��Ҫʹ�õ��ź�,����
                         mtc0,mfc0,cp0r_addr,syscall,eret,Break,trap, // WB��Ҫʹ�õ��ź�,����
						 final_addr_exc,ri,ov_exc, is_ds,badvaddr,
						 tlb_fetch_exc,tlb_mem_exc,inst_store,//����CP0 ��WB �����쳣�ź�
						 inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,
                         pc};                               // PCֵ
	assign MEM_CP0_bus = {cp0r_addr,badvaddr,mem_result,syscall,
												Break,trap,final_addr_exc,ov_exc,ri,mtc0,eret,is_ds,
												tlb_fetch_exc,tlb_mem_exc,inst_store,
												inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,pc,data_vaddr};
	
	
	wire Dcache_request;
	assign Dcache_request = MEM_valid & store_load & ~tlb_mem_valid;
	//��rvalid_dm_r����һ��					 
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
	
//-----{MEM->WB����}begin
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
//-----{չʾMEMģ���PCֵ}begin
    assign MEM_pc = pc;
    assign MEM_bypass_en= data_related_en;
	//wire[3:0] dm_final_wen;
	// assign dm_final_wen = dm_wen & {4{~cancel}};
//-----{չʾMEMģ���PCֵ}end


endmodule



