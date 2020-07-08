`timescale 1ns / 1ps

module mycpu_top(
   input int,
    input aclk,           // 时钟
    input aresetn,        // 复位信号，低电平有效

    output reg [3 :0] arid,
    output reg [31:0] araddr,
    output reg[7 :0] arlen,
    output [2 :0] arsize,
    output [1 :0] arburst,
    output [1 :0] arlock,
    output [3 :0] arcache,
    output [2 :0] arprot,
    output reg    arvalid,
    input         arready,

    input  [3 :0] rid,
    input  [31:0] rdata,
    input  [1 :0] rresp,
    input         rlast,
    input         rvalid,
    output wire     rready,

    output [3 :0] awid,
    output reg [31:0] awaddr,
    output reg [7 :0] awlen,
    output [2 :0] awsize,
    output [1 :0] awburst,
    output [1 :0] awlock,
    output [3 :0] awcache,
    output [2 :0] awprot,
    output reg    awvalid,
    input         awready,

    output [3 :0] wid,
    output reg [31:0] wdata,
    output reg [3 :0] wstrb,
    output reg       wlast,
    output reg    wvalid,
    input         wready,

    input  [3 :0] bid,
    input  [1 :0] bresp,
    input         bvalid,
    output reg    bready,
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
    );
    
wire clk;
IBUF clk_buf
(
	.O(clk),
	.I(aclk)
);	
	
wire resetn;
IBUF reset_buf
(
    .O (resetn),
    .I (aresetn)
);


//------------------------{5级流水控制信号}begin-------------------------//
    wire [31:0] IF_pc;
    wire [31:0] IF_inst;
    wire [31:0] ID_pc;
    wire [31:0] EXE_pc;
    wire [31:0] MEM_pc;
    wire [31:0] WB_pc;
    
    //5级流水新墿
    wire [31:0] cpu_5_valid;
    wire [31:0] HI_data;
    wire [31:0] LO_data;
    //5模块的valid信号
    reg IF_valid;
    reg ID_valid;
    reg EXE_valid;
    reg MEM_valid;
    reg WB_valid;
	reg CP0_valid;
    //5模块执行完成信号,来自各模块的输出
   // wire IF_over;
    wire ID_over;
    wire EXE_over;
    wire MEM_over;
    wire WB_over;
	wire CP0_over;
    //5模块允许下一级指令进兿
    wire IF_allow_in;
    wire ID_allow_in;
    wire EXE_allow_in;
    wire MEM_allow_in;
    wire WB_allow_in;
	wire CP0_allow_in;
    //wire IF_finished;	 
 	wire IF_over ;
	assign IF_over = IF_finished ;	
    wire cancel;    // 取消已经取出的正在其他流水级执行的指仿
    
    //各级允许进入信号:本级无效，或本级执行完成且下级允许进兿
    assign IF_allow_in  = (IF_over & ID_allow_in) | cancel;
    assign ID_allow_in  = ~ID_valid  | (ID_over  & EXE_allow_in);
    assign EXE_allow_in = ~EXE_valid | (EXE_over & MEM_allow_in);
    assign MEM_allow_in = ~MEM_valid | (MEM_over & WB_allow_in );
    assign WB_allow_in  = ~WB_valid  | WB_over;
	assign CP0_allow_in = ~CP0_valid | CP0_over;
	


wire[31:0] inst_addr;
wire inst_jbr;
wire data_req;
wire [31:0] vdata_addr;
wire cache_axi_wr;
wire[31:0] cache_axi_addr;	
wire[255:0] cache_axi_wdata;  //o,32
wire[31:0] wdata_addr;
wire[3:0] cache_dm_wen;//o,4




assign wdata_addr = cache_axi_addr;

   always @(posedge clk)
    begin
        if (!resetn)
        begin
            IF_valid <= 1'b0;
        end
        else
        begin
            IF_valid <= 1'b1;
        end
    end
	
    //ID_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            ID_valid <= 1'b0;
        end
        else if (ID_allow_in)
        begin
            ID_valid <= IF_over;
        end
    end
    
    //EXE_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            EXE_valid <= 1'b0;
        end
        else if (EXE_allow_in)
        begin
            EXE_valid <= ID_over;
        end
    end
    
    //MEM_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            MEM_valid <= 1'b0;
        end
        else if (MEM_allow_in)
        begin
            MEM_valid <= EXE_over;
        end
    end
    
    //WB_valid
    always @(posedge clk)
    begin
        if (!resetn || cancel)
        begin
            WB_valid <= 1'b0;
        end
        else if (WB_allow_in)
        begin
            WB_valid <= MEM_over;
        end
    end
	
	always @(posedge clk)
	begin
		if(!resetn || cancel)
		begin
			CP0_valid <=1'b0;
		end
		else if (CP0_allow_in)
		begin
			CP0_valid <= MEM_over;
		end
	end	
	//assign inst_sram_en = {IF_valid};//取忼阶段用刿######5.7
    // assign data_sram_en = {MEM_valid};//访存阶段用到#######5.7
	 
	 
    //展示5级的valid信号
    assign cpu_5_valid =  {12'd0         ,{4{IF_valid }},{4{ID_valid}},
                          {4{EXE_valid}},{4{MEM_valid}},{4{WB_valid}}};
//-------------------------{5级流水控制信号}end--------------------------//

//--------------------------{5级间的濻线}begin---------------------------//
   
	
	wire [ 68:0] IF_ID_bus;   // IF->ID级濻线
    wire [197:0] ID_EXE_bus;  // ID->EXE级濻线
    wire [178:0] EXE_MEM_bus; // EXE->MEM级濻线
    wire [168:0] MEM_WB_bus;  // MEM->WB级濻线
	wire [156:0] MEM_CP0_bus;
	wire [67: 0] CP0_WB_bus;
	wire [32:0] fetch_tlb_bus;
	wire [33:0] mem_tlb_bus;
	wire [164:0] cp0_tlb_bus;
	wire [162:0] tlb_cp0_bus;
	wire [35:0]  tlb_mem_bus;
	wire [35:0]  tlb_fetch_bus;	

    //锁存以上总线信号
    reg [ 68:0] IF_ID_bus_r;
    reg [197:0] ID_EXE_bus_r;
    reg [178:0] EXE_MEM_bus_r;
    reg [168:0] MEM_WB_bus_r;
	reg [156:0] MEM_CP0_bus_r;
    //IF到ID的锁存信叿
    always @(posedge clk)
    begin
        if(IF_over && ID_allow_in)
        begin
            IF_ID_bus_r <= IF_ID_bus;
        end
    end
    //ID到EXE的锁存信叿
    always @(posedge clk)
    begin
        if(ID_over && EXE_allow_in)
        begin
            ID_EXE_bus_r <= ID_EXE_bus;
        end
    end
    //EXE到MEM的锁存信叿
    always @(posedge clk)
    begin
        if(EXE_over && MEM_allow_in)
        begin
            EXE_MEM_bus_r <= EXE_MEM_bus;
        end
    end    
    //MEM到WB的锁存信叿
    always @(posedge clk)
    begin
        if(MEM_over && WB_allow_in)
        begin
            MEM_WB_bus_r <= MEM_WB_bus;
        end
    end

	always @(posedge clk)
	begin
		if(MEM_over && CP0_allow_in)
		begin
			MEM_CP0_bus_r <= MEM_CP0_bus;
		end
	end
//---------------------------{5级间的濻线}end----------------------------//

//--------------------------{其他交互信号}begin--------------------------//
    //跳转总线
    wire [ 32:0] jbr_bus;    



    //ID与EXE、MEM、WB交互
    wire [ 4:0] EXE_wdest;
    wire [ 4:0] MEM_wdest;
    wire [ 4:0] WB_wdest;
	
	wire rs_wait;
	wire rt_wait;
    
	wire	   [ 31:0] EXE_rs_value;   //来自于EXE/MEM总线上result的忿
    wire       [ 31:0] MEM_rs_value;     //来自于MEM总线上result的忿
    //wire 		MemRead;  //ID/EX.MEMRead是否有效
	wire    EXE_bypass_en;
	wire    MEM_bypass_en;
	
    //ID与regfile交互
    wire [ 4:0] rs;
    wire [ 4:0] rt;   
    wire [31:0] rs_value;
    wire [31:0] rt_value;
    
    //WB与regfile交互
    wire  [3:0] rf_wen;
    wire [ 4:0] rf_wdest;
    wire [31:0] rf_wdata;    
    
    //WB与IF间的交互信号
    wire [32:0] exc_bus;
//---------------------------{其他交互信号}end---------------------------//
// ----------{axi}begin------------------------------------------ //
   wire[31:0] data_addr;
    wire rvalid_inst;
    reg rvalid_dm;
    assign data_addr = vdata_addr;
    reg wdata_unfinished;//避免写未完成而先读了同一位置＿!!review,暂且以bvalid为写完成标志?
    reg waiting_data;
//  assign ldata_unfinished = waiting_data | waiting_inst;

//dylan:读写时，若当前信避 无请求或握手已成势 则可进行下一个请汿
// ----------{ar}begin
    //assign arlen = 8'd0;
    assign arburst = 2'b01;
    assign arlock = 2'd0;
    assign arcache = 4'd0;
    assign arprot = 3'd0;

    assign arsize = 3'b010;
     
    wire [7:0] cache_arlen;
	wire [7:0] cache_awlen;
    reg inst_launched;
    reg dm_load_launched;
    reg waiting_inst;
	wire inst_en;
   
    reg [255:0] rdata_load;

//	reg[31:0] addr_is_reading;
	reg[31:0] addr_is_writing;
	
	//wire[7:0] Icache_arlen;
	
	 reg [31:0] rdata_inst[7:0];
	 reg [26:0] axi_pc_base;
	 reg  inst_valid[7:0];
	 wire[290:0] axi_buffer_bus;
	 assign axi_buffer_bus = {inst_valid[7],inst_valid[6],inst_valid[5],inst_valid[4],inst_valid[3],inst_valid[2],inst_valid[1],inst_valid[0],
	                          rdata_inst[7],rdata_inst[6],rdata_inst[5],rdata_inst[4],rdata_inst[3],rdata_inst[2],rdata_inst[1],rdata_inst[0],axi_pc_base};
	 
	 
	 //----------------------数据请求地址握手阶段(rid=4'd1}---------------
		reg[3:0]  addr_shakehand_state;
		wire shakehand_success;
		reg cancel_ar ; //地址握手成功后，如果有cancel信号，则把cancel信号锁存起来，之后需要用刿
		assign shakehand_success = (addr_shakehand_state==3'd1 | addr_shakehand_state==3'd2 | addr_shakehand_state ==3'd3);
		reg[31:0]  inst_addr_queue[1:0]; //读指令地坿队列，为了解决cancel的问题，在地坿握手成功以后，把读指令地坿放入队列里，读数据到达则出队，用出队的地坿更新axi_pc_base
		reg[1:0] queue_count_r;
		always @(posedge clk)
		begin
			if (!resetn)
			begin
				arvalid <= 1'b0;
				araddr <= 32'd0;
				arlen<=8'd0;
				inst_launched <= 1'b0;
				dm_load_launched <= 1'b0;
				addr_shakehand_state<=3'd0;
				cancel_ar<=1'b0;
				inst_addr_queue[1]<=32'd0;
				inst_addr_queue[0]<=32'd0;
				queue_count_r<=2'd0;
			end
			//非confreg地址握手
			else if((rready&rvalid&(inst_rstate==4'd0)&(rid==4'd0)&~rlast)  | (rready&rvalid&(inst_rstate==4'd9)&(rid==4'd0)&~rlast) ) //出队
			begin
			   queue_count_r <= queue_count_r -1;
			   //queue_count_r<=queue_count;
			   inst_addr_queue[0]<=inst_addr_queue[1];//
			end
		    else if ((addr_shakehand_state==3'd0)&data_req &~((data_addr==addr_is_writing)&wdata_unfinished)&(cache_arlen==8'd7)  )
		    begin
				arid <= 4'd1;
				araddr <= data_addr;
				arvalid <= 1'b1;
				dm_load_launched <= 1'b1;
				arlen<=cache_arlen;
				addr_shakehand_state<=3'd1;
			end
           else if ((addr_shakehand_state==3'd0)&data_req &~((data_addr==addr_is_writing)&wdata_unfinished)&(cache_arlen==8'd0)  )
			begin
				arid <= 4'd1;
				araddr <= data_addr;
				arvalid <= 1'b1;
				dm_load_launched <= 1'b1;		
				addr_shakehand_state<=3'd2;
				arlen<=cache_arlen;
				//addr_is_reading<=data_addr;
			end
           else if ((addr_shakehand_state==4'd0) & inst_en & (arvalid == 1'b0)& ~data_req&cancel )
			begin
				arid <= 4'd0;
				araddr <= 32'd0;
			//cancel_r<=1'b1;
				arvalid <= 1'b0;
				arlen<=4'd0;
				addr_shakehand_state<=3'd0;
			end
			else if ((addr_shakehand_state==3'd0) & inst_en & (arvalid == 1'b0)& ~data_req) //这个时忙没有握手成功，可以不用锁存cancel_ar
			begin
   
				arid <= 4'd0;
				araddr <= inst_addr;
			    inst_addr_queue[queue_count_r]<=inst_addr;
				queue_count_r<=queue_count_r+1'b1;  //入队
				arvalid <= 1'b1;
				inst_launched <= 1'b1;
				//waiting_inst <= 1'b1;		
				arlen<=4'd7;
				addr_shakehand_state<=3'd3;
			end
			else if((shakehand_success)&arvalid & arready )
			begin
			   
			  
				araddr <= 32'd0;
				arvalid <= 1'b0;
				inst_launched <= 1'b0;
				dm_load_launched <= 1'b0;
                addr_shakehand_state<=3'd0;  //回到0状濁，等待下一次地坿握手
			
			end
		end
	


//----------------------------{end}----------------------------------------

//------------------{读指令?道begin}-----------------------------------
assign rready = inst_rready | data_rready;


reg[3:0] inst_rstate;
reg cancel_read; //锁存读状态中过来的cancel_read
wire real_cancel;
reg inst_rready;
	//reg base_changed;
//正常情况下，inst_rstate的状态可以为9,0,1,2,3,4,5,6,7,8＿9。?
//注意，起姿(空闲)状濁为9
integer j;
always @(posedge clk)
		begin
			if (!resetn)
			begin
				 for(j=0;j<7;j=j+1)
				begin
					rdata_inst[j]<=32'd0;
					inst_valid[j]<=1'b0;
				end
				axi_pc_base<=27'd0;
				inst_rstate<=4'd9;
				//cancel_r<=1'b0;		
				inst_rready<=1'b0;
		end
		else if (~rready&rvalid&(inst_rstate==4'd9)&(rid==4'd0)&~rlast)  //第一个rvalid到达，但此时rready应该为低电平，下丿个时钟周期开始把rready变高,仿0状濁开始接受指令数捿
		begin
		    inst_rready<=1'b1;
			inst_rstate<=4'd0;
		end
		else if (rready&rvalid&(inst_rstate==4'd9)&(rid==4'd0)&~rlast) //inst_rstate==1'd1的时候，queue_count_r只可能为0房1,不然则有问题
        begin	
		    inst_rready<=1'b1;
			rdata_inst[0]<=rdata;
			axi_pc_base<=inst_addr_queue[0][31:5]; //队头出队
			//base_changed<=1'b1;
			inst_valid[0]<=1'b1;
			inst_valid[1]<=1'b0;
			inst_valid[2]<=1'b0;
			inst_valid[3]<=1'b0;
			inst_valid[4]<=1'b0;
			inst_valid[5]<=1'b0;
			inst_valid[6]<=1'b0;
			inst_valid[7]<=1'b0;
			//rready<=1'b0;
			inst_rstate<=4'd1;
		end
		else if (rready&rvalid&(inst_rstate==4'd0)&(rid==4'd0)&~rlast) //inst_rstate==1'd1的时候，queue_count_r只可能为0房1,不然则有问题
        begin	
			rdata_inst[0]<=rdata;
			axi_pc_base<=inst_addr_queue[0][31:5]; //队头出队
			//base_changed<=1'b1;
			inst_valid[0]<=1'b1;
			inst_valid[1]<=1'b0;
			inst_valid[2]<=1'b0;
			inst_valid[3]<=1'b0;
			inst_valid[4]<=1'b0;
			inst_valid[5]<=1'b0;
			inst_valid[6]<=1'b0;
			inst_valid[7]<=1'b0;
			//rready<=1'b0;
			inst_rstate<=4'd1;
		end
		else if (rready&rvalid&(inst_rstate==4'd1)&(rid==4'd0)&~rlast)
        begin
            // base_changed<=1'b0;
			rdata_inst[1]<=rdata;
			//inst_valid[1]<=1'b1;
			inst_valid[1]<=1'b1;
			//rready<=1'b0;
			inst_rstate<=4'd2;
        end
		else if (rready&rvalid&(inst_rstate==4'd2)&(rid==4'd0)&~rlast)
        begin
          
			rdata_inst[2]<=rdata;
			//inst_valid[2]<=1'b1;
			inst_valid[2]<=1'b1;
			//rready<=1'b0;
			inst_rstate<=4'd3;
        end
		else if (rready&rvalid&(inst_rstate==4'd3)&(rid==4'd0)&~rlast)
        begin
          
			rdata_inst[3]<=rdata;
			inst_valid[3]<=1'b1;
			inst_rstate<=4'd4;
        end
		else if (rready&rvalid&(inst_rstate==4'd4)&(rid==4'd0)&~rlast)
        begin
			rdata_inst[4]<=rdata;
			//inst_valid[4]<=1'b1;
			inst_valid[4]<=1'b1;
			//rready<=1'b0;
			inst_rstate<=4'd5;
		end
		else if (rready&rvalid&(inst_rstate==4'd5)&(rid==4'd0)&~rlast)
        begin
			rdata_inst[5]<=rdata;
			//inst_valid[5]<=1'b1;
			inst_valid[5]<=1'b1;
			inst_rstate<=4'd6;
		end
		else if (rready&rvalid&(inst_rstate==4'd6)&(rid==4'd0)&~rlast)
        begin
			rdata_inst[6]<=rdata;
			inst_valid[6]<=1'b1;
			//rready<=1'b0;
			inst_rstate<=4'd7;
		end
		
		else if (rready&rvalid&(inst_rstate==4'd7)&(rid==4'd0)&rlast)
        begin
			rdata_inst[7]<=rdata;
			//inst_valid[7]<=1'b1;
			inst_valid[7]<=1'b1;
			inst_rready<=1'b0;
			inst_rstate<=4'd9;
		end
	end

//--------------------{读指令?道end}------------------------------------------
//-------------------{读数据?道begin} ------------------------------------
reg[3:0] data_rstate;

reg data_rready;
  always @(posedge clk)
    begin
        if (!resetn)
        begin
			rdata_load<=256'd0;
			data_rstate<=4'd9;
			data_rready<=1'b0;
			rvalid_dm<=1'b0;
		end
		else if((data_rstate==4'd9)&dm_load_launched)
		begin
			rvalid_dm<=1'b0;
		end
		//为了解决读指令和读数据交错返回的情况
		else if (rready & rvalid&(data_rstate==4'd9)&(rid==4'd1)&rlast)
		begin
			rdata_load<={rdata,rdata,rdata,rdata,rdata,rdata,rdata,rdata};
			data_rstate<=4'd9;
			data_rready<=1'b0;
			rvalid_dm<=1'b1;
		end
		else if (rready & rvalid&(data_rstate==4'd9)&(rid==4'd1)&~rlast)
		begin
			rdata_load[31:0]<=rdata;
			data_rstate<=4'd1;
			data_rready<=1'b1;
		end
		else if (~rready & rvalid&(data_rstate==4'd9)&(rid==4'd1))
		begin
			data_rready<=1'b1;
			data_rstate<=4'd0;
		end
		else if (rready&rvalid&(data_rstate==4'd0)&(rid==4'd1)&rlast)
        begin
			rdata_load<={rdata,rdata,rdata,rdata,rdata,rdata,rdata,rdata};
			data_rstate<=4'd9;
			data_rready<=1'b0;
			rvalid_dm<=1'b1;
		end
		else if (rready&rvalid&(data_rstate==4'd0)&(rid==4'd1)&~rlast)
        begin    
			rdata_load[31:0]<=rdata;
			data_rstate<=4'd1;
        end
		else if (rready&rvalid&(data_rstate==4'd1)&(rid==4'd1)&rlast)
        begin
            
			rdata_load[255:32]<={rdata,rdata,rdata,rdata,rdata,rdata,rdata};
			data_rstate<=4'd9;	
			data_rready<=1'b0;
			rvalid_dm<=1'b1;
       end
	   else if (rready&rvalid&(data_rstate==4'd1)&(rid==4'd1)&~rlast)
        begin
            
			rdata_load[63:32]<=rdata;
			data_rstate<=4'd2;
        end
       else if (rready&rvalid&(data_rstate==4'd2)&(rid==4'd1)&rlast)
        begin
            
			rdata_load[255:64]<={rdata,rdata,rdata,rdata,rdata,rdata};
			data_rstate<=4'd9;
			data_rready<=1'b0;
			rvalid_dm<=1'b1;
        end
		else if (rready&rvalid&(data_rstate==4'd2)&(rid==4'd1)&~rlast)
        begin
            
			rdata_load[95:64]<=rdata;
			//rready<=1'b0;
			data_rstate<=4'd3;
			
        end
		else if (rready&rvalid&(data_rstate==4'd3)&(rid==4'd1)&rlast)
        begin
            
			rdata_load[255:96]<={rdata,rdata,rdata,rdata,rdata};
			data_rstate<=4'd9;
			data_rready<=1'b0;
			rvalid_dm<=1'b1;
        end
		else if (rready&rvalid&(data_rstate==4'd3)&(rid==4'd1)&~rlast)
        begin
            
			rdata_load[127:96]<=rdata;
			data_rstate<=4'd4;
			
        end
		else if (rready&rvalid&(data_rstate==4'd4)&(rid==4'd1)&rlast)
        begin
            
			rdata_load[255:128]<={rdata,rdata,rdata,rdata};
			data_rstate<=4'd9;
			data_rready<=1'b0;
			rvalid_dm<=1'b1;
        end
		else if (rready&rvalid&(data_rstate==4'd4)&(rid==4'd1)&~rlast)
        begin
            
			rdata_load[159:128]<=rdata;
			data_rstate<=4'd5;
			
        end
		else if (rready&rvalid&(data_rstate==4'd5)&(rid==4'd1)&rlast)
        begin
            
			rdata_load[255:160]<={rdata,rdata,rdata};
			data_rstate<=4'd9;
			data_rready<=1'b0;
			rvalid_dm<=1'b1;
        end
		else if (rready&rvalid&(data_rstate==4'd5)&(rid==4'd1)&~rlast)
        begin
            
			rdata_load[191:160]<=rdata;
			data_rstate<=4'd6;
			
        end
		else if (rready&rvalid&(data_rstate==4'd6)&(rid==4'd1)&rlast)
        begin
            
			rdata_load[255:192]<={rdata,rdata};
			data_rstate<=4'd9;
			data_rready<=1'b0;
			rvalid_dm<=1'b1;
        end
		else if (rready&rvalid&(data_rstate==4'd6)&(rid==4'd1)&~rlast)
        begin
            
			rdata_load[223:192]<=rdata;
			data_rstate<=4'd7;
			
        end
		else if (rready&rvalid&(data_rstate==4'd7)&(rid==4'd1)&rlast)
        begin
            
			rdata_load[255:224]<=rdata;
			data_rstate<=4'd9;
			data_rready<=1'b0;
			rvalid_dm<=1'b1;
        end		
	end


	
//--------------------{更新Icache  begin}---------------------------------------
	wire update_finished;
	reg Icache_wr;
	reg[255:0]  axi_Icache_insts;
	reg[31:0]   update_inst_addr;
	reg[2:0]   update_state;
	wire update = (inst_valid[3]&inst_valid[2]&inst_valid[1]&inst_valid[0])&(inst_valid[7]&inst_valid[6]&inst_valid[5]&inst_valid[4]) ? 1'b1 : 1'b0;
	always @(posedge clk)
    begin
        if (!resetn)
        begin
            update_state <= 3'd0;
			update_inst_addr<=32'd0;
			Icache_wr<=1'b0;
        end
        else if ((update_state==3'd0)&update&inst_launched&(axi_pc_base!=inst_addr[31:5]))
        begin
            update_inst_addr<={axi_pc_base,5'b00000};
			Icache_wr<=1'b1;
			axi_Icache_insts<={rdata_inst[7],rdata_inst[6],rdata_inst[5],rdata_inst[4],rdata_inst[3],rdata_inst[2],rdata_inst[1],rdata_inst[0]};
			update_state <= 3'd1;
        end
        else if((update_state==3'd1)&update_finished)
        begin
            update_state <= 3'd0;
			Icache_wr<=1'b0;
        end
		/*
		else if((update_state==3'd3))
		begin
			update_state <= 3'd0;
			//Icache_wr <= 1'b0;
		end
		*/
    end

	//当cancel和valid_revised同时到来的时候，rvalid_inst也无敿
	//当在等待无效的取指的时忙，rvalid_inst_cancel会变成高电平，直到rvalid_inst到来，此段时间取到的指依然是无效的，IF_over仍将为低电平
 
    //rready是立刻更新到IP核的，IP核发出rvali后没收到rready会一直发rvali?
	
	//不知道是第几次修改，因为发现rvalid_inst可能会跟cancel信号丿起到辿
	//导致执行了不该执行的指令，修改实现为有限状濁机的迁移，迁移状濁如丿
	//因为IF_over后面就跟睿IF_allow_in
	//状濿0：跟IF_OVER丿起的信号
	//状濿1:状濿0接收waiting_inst后跳转到的信叿
	//状濿2:状濿1接收rvalid_inst后跳转到的状怿
	//状濿3:状濿1接收到rvalid_inst&cancel跳转到的状濿
	//状濿4：状怿1接收到cancel信号后跳转到的状怿
	//状濿5：状怿3接收到rvalid_ins信号后跳转到的状怿
	//状濿6:状濿4接收到rvalid_inst信号后跳转到的信叿
	//状濿7：状怿6收到rvalid_inst信后后跳转到的状怿
	 //新加丿个状怿9:状濿0接收waiting_inst&cancel后跳转到的信叿,下个状濁为4
	//其中，状怿2,5,7的下个周期IF_OVER为高电平，跳回到状濿0

// ----------{aw}begin
    assign awid = 4'd1;
   // assign awlen = 8'd0;
    assign awburst = 2'b01;
    assign awlock = 2'd0;
    assign awcache = 4'd0;
    assign awprot = 3'd0;

    assign awsize = 3'b101;
	
	
	
	reg[3:0] awstate;

	reg write_is_launched;
	reg[255:0] data_to_write;
    always @(posedge clk)
    begin
        if (!resetn)
        begin
            awvalid <= 1'b0;
            awaddr <= 32'd0;
			wstrb <= 4'd0;
			wvalid <= 1'b0;
            wdata_unfinished <= 1'b0;
			 addr_is_writing<=32'dX;
			bready <= 1'b1;
			awstate<=4'd0;
			wlast<=1'b0;
			awlen<=8'd0;
			data_to_write<=256'd0;
        end
		else if ((awstate==4'd0)&cache_axi_wr& (awvalid == 1'b0)&(cache_awlen==8'd7))//load优先于store
        begin
            awaddr <= wdata_addr;
            awvalid <= 1'b1;
			awstate<=4'd1;
			wstrb<=4'hf;
			addr_is_writing<=wdata_addr;
			wdata_unfinished<=1'b1;
			awlen<=cache_awlen;
			data_to_write<=cache_axi_wdata;
        end
		else if ((awstate==4'd0)&cache_axi_wr& (awvalid  == 1'b0) &(cache_awlen==8'd0))//load优先于store
        begin
            awaddr <= wdata_addr;
            awvalid <= 1'b1;
			awstate<=4'd2;
			wstrb<=cache_dm_wen;
			addr_is_writing<=wdata_addr;
			wdata_unfinished<=1'b1;
            awlen<=cache_awlen;		
            data_to_write<=cache_axi_wdata;		
        end
		else if ((awstate==4'd1)&awvalid & awready)
        begin
            awaddr <= 32'd0;
            awvalid <= 1'b0;
			awaddr <= 32'd0;
			wdata<=data_to_write[31:0];
			
			wvalid<=1'b1;
			//bready<=1'b1;
            awstate<=4'd3;	    		
        end
		else if ((awstate==4'd2)&awvalid & awready)
        begin
            awaddr <= 32'd0;
            awvalid <= 1'b0;
			awaddr <= 32'd0;
			wdata<=data_to_write[31:0];
			
			wvalid<=1'b1;
			//bready<=1'b1;
            awstate<=4'd4;
			wlast<=1'b1;
  			write_is_launched<=1'b1;
        end
		else if((awstate==4'd3)&wvalid&wready)
		begin
			//wvalid<=1'b0;
			//awstate<=4'd5;
			wdata<=data_to_write[63:32];
			wvalid<=1'b1;
            awstate<=4'd5;	
		end			
		else if((awstate==4'd5)&wvalid&wready)
		begin
			wdata<=data_to_write[95:64];
			wvalid<=1'b1;
            awstate<=4'd6;	
		end
		else if((awstate==4'd6)&wvalid&wready)
		begin
			wdata<=data_to_write[127:96];
			wvalid<=1'b1;
            awstate<=4'd7;	
        end	
		else if((awstate==4'd7)&wvalid&wready)
		begin
			wdata<=data_to_write[159:128];
			wvalid<=1'b1;
            awstate<=4'd8;	
        end	
		else if((awstate==4'd8)&wvalid&wready)
		begin
			wdata<=data_to_write[191:160];
			wvalid<=1'b1;
            awstate<=4'd9;	
        end	
		else if((awstate==4'd9)&wvalid&wready)
		begin
			wdata<=data_to_write[223:192];
			wvalid<=1'b1;
            awstate<=4'd10;	
        end	
		else if((awstate==4'd10)&wvalid&wready)
		begin
			wdata<=data_to_write[255:224];
			wvalid<=1'b1;
            awstate<=4'd15;	
			wlast<=1'b1;
			//bready<=1'b1;
        end			
        else if((awstate==4'd15)&wvalid&wready)
        begin
         
         
            awvalid <= 1'b0;
            awaddr <= 32'd0;
			wstrb <= 4'd0;
			wvalid <= 1'b0;
             wdata<=32'd0;
			//awstate<=4'd11;
			wlast<=1'b0;
			write_is_launched<=1'b0;
		    addr_is_writing<=32'dX;
		     wdata_unfinished <= 1'b0;
			awstate<=4'd0;
		end
		else if((awstate==4'd4)&wvalid&wready)
		begin
			
        
            awvalid <= 1'b0;
            awaddr <= 32'd0;
			wstrb <= 4'd0;
			wvalid <= 1'b0;
            wdata<=32'd0;
			//bready <= 1'b0;
			//awstate<=4'd11;
			wlast<=1'b0;
			write_is_launched<=1'b0;
		    addr_is_writing<=32'dX;
		     wdata_unfinished <= 1'b0;
			awstate<=4'd0;
		end	 
    end
    
// ----------{w}begin
    assign wid = 4'd1;
   
// ----------{axi}end------------------------------------------ //


//-------------------------{各模块实例化}begin---------------------------//
    wire next_fetch; //即将运行取指模块，需要先锁存PC倿
    //IF允许进入时，即锁存PC值，取下丿条指仿
	
    assign next_fetch = IF_allow_in;
	/*
	always @(posedge clk)
    begin
        if (!resetn)
        begin
            inst_en <= 1'b1;
        end
        else if(next_fetch)
        begin
            inst_en <= 1'b1;
        end
        else if (inst_en & inst_launched)
        begin
            inst_en <= 1'b0;
        end
    end
	*/
    fetch IF_module(             // 取指线
        .clk       (clk       ),  // I, 1
        .resetn    (resetn    ),  // I, 1
        .IF_valid  (IF_valid  ),  // I, 1
        .cancel    (cancel),
        .next_fetch(next_fetch),  // I, 1
		.tlb_fetch_bus(tlb_fetch_bus),
		.ID_allow_in(ID_allow_in),
		
        //.inst      (inst      ),  // I, 32
        .jbr_bus   (jbr_bus   ),  // I, 33
        //.inst_addr (inst_addr ),  // O, 32
		
        .IF_over   (IF_finished   ),  // O, 1
        .IF_ID_bus (IF_ID_bus ),  // O, 64
		.fetch_tlb_bus(fetch_tlb_bus),
        
        //5级流水新增接叿
        .exc_bus   (exc_bus   ),  // I, 32
        .is_ds     (inst_jbr  ),  // I, 1
        .ID_pc     (ID_pc     ),
        //展示PC和取出的指令
	
		.inst_en    (inst_en),
		.axi_inst_addr(inst_addr),
		//.Icache_arlen (Icache_arlen),
		.axi_buffer_bus(axi_buffer_bus),
		.inst_load_launched(inst_launched),
		.Icache_wr(Icache_wr),
		.axi_Icache_insts(axi_Icache_insts),
		.update_inst_addr(update_inst_addr),
		.update_finished(update_finished),
		//.insts(insts),
       // .rvalid_inst (real_inst_valid),
		
        .IF_pc     (IF_pc     ),  // O, 32
        .IF_inst   (IF_inst   )   // O, 32
    );

    decode ID_module(               // 译码线
        .ID_valid   (ID_valid   ),  // I, 1
        .IF_ID_bus_r(IF_ID_bus_r),  // I, 64
        .rs_value   (rs_value   ),  // I, 32
        .rt_value   (rt_value   ),  // I, 32
        .rs         (rs         ),  // O, 5
        .rt         (rt         ),  // O, 5
        .jbr_bus    (jbr_bus    ),  // O, 33
        .inst_jbr   (inst_jbr   ),  // O, 1
        .ID_over    (ID_over    ),  // O, 1
        .ID_EXE_bus (ID_EXE_bus ),  // O, 180
        
        //5级流水新墿
        .IF_over     (IF_over    ),// I, 1
        .EXE_wdest   (EXE_wdest   ),// I, 5
        .MEM_wdest   (MEM_wdest   ),// I, 5
        .WB_wdest    (WB_wdest    ),// I, 5
        
		.EXE_over(EXE_over),
		.MEM_over(MEM_over),
		.EXE_rs_value(EXE_rs_value),
		.MEM_rs_value(MEM_rs_value),
		.MEM_bypass_en(MEM_bypass_en),
		.EXE_bypass_en(EXE_bypass_en),
		//.MemRead(MemRead),
		
        //展示PC
        .ID_pc       (ID_pc       ) // O, 32
    ); 

    exe EXE_module(                   // 执行线
        .EXE_valid   (EXE_valid   ),  // I, 1
        .ID_EXE_bus_r(ID_EXE_bus_r),  // I, 180
        .EXE_over    (EXE_over    ),  // O, 1 
        .EXE_MEM_bus (EXE_MEM_bus ),  // O, 196
        
        //5级流水新墿
        .clk         (clk         ),  // I, 1
        .EXE_wdest   (EXE_wdest   ),  // O, 5
        
		//.MemRead(MemRead),
		.EXE_rs_value(EXE_rs_value),
		.EXE_bypass_en(EXE_bypass_en),
        //展示PC
        .EXE_pc      (EXE_pc      )   // O, 32
    );

    mem MEM_module(                     // 访存线
        .clk          (clk          ),  // I, 1 
        .resetn (resetn),
        .MEM_valid    (MEM_valid    ),  // I, 1
        .EXE_MEM_bus_r(EXE_MEM_bus_r),  // I, 196
		.tlb_mem_bus(tlb_mem_bus),
		.EXE_over(EXE_over),
		//.WB_allow_in(WB_allow_in),
		//.CP0_allow_in(CP0_allow_in),
        //.dm_rdata     (dm_rdata     ),  // I, 32
        //.dm_addr      (dm_addr      ),  // O, 32
        //.dm_wen       (dm_wen       ),  // O, 4 
        //.dm_wdata     (dm_wdata     ),  // O, 32
		//####################5.7
		/*.dm_rdata     (data_sram_rdata),
        .dm_addr      (data_sram_addr),
        .dm_wen       (data_sram_wen),
        .dm_wdata     (data_sram_wdata),
		*/
        .MEM_over     (MEM_over     ),  // O, 1
        .MEM_WB_bus   (MEM_WB_bus   ),  // O, 119
		.MEM_CP0_bus(MEM_CP0_bus),
		.mem_tlb_bus(mem_tlb_bus),
        
        //5级流水新增接叿
        .MEM_allow_in (MEM_allow_in ),  // I, 1
        .MEM_wdest    (MEM_wdest    ),  // O, 5
        
		.MEM_rs_value(MEM_rs_value),
		.MEM_bypass_en(MEM_bypass_en),
		.cancel(cancel),
        //展示PC
        .MEM_pc       (MEM_pc       ),   // O, 32
        
		.data_req(data_req),
	    .vdata_addr(vdata_addr),
	    .dm_load_launched(dm_load_launched),
	    .rvalid_dm(rvalid_dm),//O,1
	    .axi_rdata(rdata_load),	//O,128
	   // .buffer_wen(buffer_wen),
	   // .buffer_data(buffer_data),
	    //.is_buffer_full( is_buffer_full),
		//cache向axi发?写请求霿要的信号
		.cache_axi_addr(cache_axi_addr),  //I,32
		.cache_axi_wdata(cache_axi_wdata),//I,128
	    .cache_dm_wen(cache_dm_wen),//I,4
		.cache_axi_wr(cache_axi_wr),//I,1
		.cache_awlen(cache_awlen),//I,8
	    .cache_arlen(cache_arlen)//I,8
		//.write_is_launched(write_is_launched)
		//.wdata_unfinished(wdata_unfinished)
    );  
   /*
    write_buffer  write_buffer(
    .aclk(aclk),
	.resetn(resetn),
	
    .buffer_wen(buffer_wen),
	.buffer_data(buffer_data),
	.is_buffer_full(is_buffer_full),
	
	
	.wdata_addr(buffer_wdata_vaddr),
	.wdata_buffer(wdata_buffer),
	//output reg          buffer_data_req,
	.buffer_data_wr(buffer_data_wr),
	.wdata_unfinished(buffer_wdata_unfinished)
   // .is_buffer_full( is_buffer_full)
	
);	*/
 
    wb WB_module(                     // 写回线
        .WB_valid    (WB_valid    ),  // I, 1
        .MEM_WB_bus_r(MEM_WB_bus_r),  // I, 119
		.CP0_WB_bus_r(CP0_WB_bus),
        .rf_wen      (rf_wen      ),  // O, 1
        .rf_wdest    (rf_wdest    ),  // O, 5
        .rf_wdata    (rf_wdata    ),  // O, 32
        .WB_over     (WB_over     ),  // O, 1
        
        //5级流水新增接叿
        .clk         (clk         ),  // I, 1
        .resetn      (resetn      ),  // I, 1
        .exc_bus     (exc_bus     ),  // O, 32
        .WB_wdest    (WB_wdest    ),  // O, 5
        .cancel      (cancel      ),  // O, 1
        
        //展示PC和HI/LO倿
        .WB_pc       (WB_pc       ),  // O, 32
        .HI_data     (HI_data     ),  // O, 32
        .LO_data     (LO_data     )   // O, 32
    );

    //inst_rom inst_rom_module(         // 指令存储噿
    //    .clka       (aclk           ),  // I, 1 ,时钟
    //    .addra      (inst_addr[9:2]),  // I, 8 ,指令地址
    //    .douta      (inst          )   // O, 32,指令
    //);
	cp0 CP0_module(
		.clk(clk),
		.resetn(resetn),
		.CP0_valid(CP0_valid),
		.cancel(cancel),
		.MEM_CP0_bus_r(MEM_CP0_bus_r),//I
		.tlb_cp0_bus(tlb_cp0_bus),
		.CP0_over(CP0_over),
		//.cancel(cancel),
		.CP0_WB_bus(CP0_WB_bus),//O
		.cp0_tlb_bus(cp0_tlb_bus)
	);

	tlb TLB_module(
		.clk(clk),
		.resetn(resetn),
		.next_fetch(next_fetch),
		.MEM_allow_in(MEM_allow_in),
		.EXE_over(EXE_over),
		.fetch_tlb_bus(fetch_tlb_bus),
		.mem_tlb_bus(mem_tlb_bus),
		.cp0_tlb_bus(cp0_tlb_bus),
		.tlb_cp0_bus(tlb_cp0_bus),
		.tlb_fetch_bus(tlb_fetch_bus),
		.tlb_mem_bus(tlb_mem_bus)
	);

    regfile rf_module(        // 寄存器堆模块
        .clk    (clk      ),  // I, 1
        .wen    (rf_wen   ),  // I, 1
        .raddr1 (rs       ),  // I, 5
        .raddr2 (rt       ),  // I, 5
        .waddr  (rf_wdest ),  // I, 5
        .wdata  (rf_wdata ),  // I, 32
        .rdata1 (rs_value ),  // O, 32
        .rdata2 (rt_value )  // O, 32

    );
    
	//########################5.7
	assign debug_wb_pc = WB_pc;
    assign debug_wb_rf_wen = rf_wen;
    assign debug_wb_rf_wdata = rf_wdata;
    assign debug_wb_rf_wnum = rf_wdest;

//--------------------------{各模块实例化}end----------------------------//
endmodule
