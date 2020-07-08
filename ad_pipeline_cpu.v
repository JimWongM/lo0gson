`timescale 1ns / 1ps

module mycpu_top(
   input int,
    input aclk,           // ʱ��
    input aresetn,        // ��λ�źţ��͵�ƽ��Ч

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


//------------------------{5����ˮ�����ź�}begin-------------------------//
    wire [31:0] IF_pc;
    wire [31:0] IF_inst;
    wire [31:0] ID_pc;
    wire [31:0] EXE_pc;
    wire [31:0] MEM_pc;
    wire [31:0] WB_pc;
    
    //5����ˮ��
    wire [31:0] cpu_5_valid;
    wire [31:0] HI_data;
    wire [31:0] LO_data;
    //5ģ���valid�ź�
    reg IF_valid;
    reg ID_valid;
    reg EXE_valid;
    reg MEM_valid;
    reg WB_valid;
	reg CP0_valid;
    //5ģ��ִ������ź�,���Ը�ģ������
   // wire IF_over;
    wire ID_over;
    wire EXE_over;
    wire MEM_over;
    wire WB_over;
	wire CP0_over;
    //5ģ��������һ��ָ�����
    wire IF_allow_in;
    wire ID_allow_in;
    wire EXE_allow_in;
    wire MEM_allow_in;
    wire WB_allow_in;
	wire CP0_allow_in;
    //wire IF_finished;	 
 	wire IF_over ;
	assign IF_over = IF_finished ;	
    wire cancel;    // ȡ���Ѿ�ȡ��������������ˮ��ִ�е�ָ��
    
    //������������ź�:������Ч���򱾼�ִ��������¼��������
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
	//assign inst_sram_en = {IF_valid};//ȡ���׶�����######5.7
    // assign data_sram_en = {MEM_valid};//�ô�׶��õ�#######5.7
	 
	 
    //չʾ5����valid�ź�
    assign cpu_5_valid =  {12'd0         ,{4{IF_valid }},{4{ID_valid}},
                          {4{EXE_valid}},{4{MEM_valid}},{4{WB_valid}}};
//-------------------------{5����ˮ�����ź�}end--------------------------//

//--------------------------{5����ĞS��}begin---------------------------//
   
	
	wire [ 68:0] IF_ID_bus;   // IF->ID���S��
    wire [197:0] ID_EXE_bus;  // ID->EXE���S��
    wire [178:0] EXE_MEM_bus; // EXE->MEM���S��
    wire [168:0] MEM_WB_bus;  // MEM->WB���S��
	wire [156:0] MEM_CP0_bus;
	wire [67: 0] CP0_WB_bus;
	wire [32:0] fetch_tlb_bus;
	wire [33:0] mem_tlb_bus;
	wire [164:0] cp0_tlb_bus;
	wire [162:0] tlb_cp0_bus;
	wire [35:0]  tlb_mem_bus;
	wire [35:0]  tlb_fetch_bus;	

    //�������������ź�
    reg [ 68:0] IF_ID_bus_r;
    reg [197:0] ID_EXE_bus_r;
    reg [178:0] EXE_MEM_bus_r;
    reg [168:0] MEM_WB_bus_r;
	reg [156:0] MEM_CP0_bus_r;
    //IF��ID�������Ņ�
    always @(posedge clk)
    begin
        if(IF_over && ID_allow_in)
        begin
            IF_ID_bus_r <= IF_ID_bus;
        end
    end
    //ID��EXE�������Ņ�
    always @(posedge clk)
    begin
        if(ID_over && EXE_allow_in)
        begin
            ID_EXE_bus_r <= ID_EXE_bus;
        end
    end
    //EXE��MEM�������Ņ�
    always @(posedge clk)
    begin
        if(EXE_over && MEM_allow_in)
        begin
            EXE_MEM_bus_r <= EXE_MEM_bus;
        end
    end    
    //MEM��WB�������Ņ�
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
//---------------------------{5����ĞS��}end----------------------------//

//--------------------------{���������ź�}begin--------------------------//
    //��ת����
    wire [ 32:0] jbr_bus;    



    //ID��EXE��MEM��WB����
    wire [ 4:0] EXE_wdest;
    wire [ 4:0] MEM_wdest;
    wire [ 4:0] WB_wdest;
	
	wire rs_wait;
	wire rt_wait;
    
	wire	   [ 31:0] EXE_rs_value;   //������EXE/MEM������result�ķ�
    wire       [ 31:0] MEM_rs_value;     //������MEM������result�ķ�
    //wire 		MemRead;  //ID/EX.MEMRead�Ƿ���Ч
	wire    EXE_bypass_en;
	wire    MEM_bypass_en;
	
    //ID��regfile����
    wire [ 4:0] rs;
    wire [ 4:0] rt;   
    wire [31:0] rs_value;
    wire [31:0] rt_value;
    
    //WB��regfile����
    wire  [3:0] rf_wen;
    wire [ 4:0] rf_wdest;
    wire [31:0] rf_wdata;    
    
    //WB��IF��Ľ����ź�
    wire [32:0] exc_bus;
//---------------------------{���������ź�}end---------------------------//
// ----------{axi}begin------------------------------------------ //
   wire[31:0] data_addr;
    wire rvalid_inst;
    reg rvalid_dm;
    assign data_addr = vdata_addr;
    reg wdata_unfinished;//����дδ��ɶ��ȶ���ͬһλ�ã�!!review,������bvalidΪд��ɱ�־?
    reg waiting_data;
//  assign ldata_unfinished = waiting_data | waiting_inst;

//dylan:��дʱ������ǰ�ű� ������������ѳ��� ��ɽ�����һ����T
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
	 
	 
	 //----------------------���������ַ���ֽ׶�(rid=4'd1}---------------
		reg[3:0]  addr_shakehand_state;
		wire shakehand_success;
		reg cancel_ar ; //��ַ���ֳɹ��������cancel�źţ����cancel�ź�����������֮����Ҫ����
		assign shakehand_success = (addr_shakehand_state==3'd1 | addr_shakehand_state==3'd2 | addr_shakehand_state ==3'd3);
		reg[31:0]  inst_addr_queue[1:0]; //��ָ��؈}���У�Ϊ�˽��cancel�����⣬�ڵ؈}���ֳɹ��Ժ󣬰Ѷ�ָ��؈}�������������ݵ�������ӣ��ó��ӵĵ؈}����axi_pc_base
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
			//��confreg��ַ����
			else if((rready&rvalid&(inst_rstate==4'd0)&(rid==4'd0)&~rlast)  | (rready&rvalid&(inst_rstate==4'd9)&(rid==4'd0)&~rlast) ) //����
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
			else if ((addr_shakehand_state==3'd0) & inst_en & (arvalid == 1'b0)& ~data_req) //���ʱæû�����ֳɹ������Բ�������cancel_ar
			begin
   
				arid <= 4'd0;
				araddr <= inst_addr;
			    inst_addr_queue[queue_count_r]<=inst_addr;
				queue_count_r<=queue_count_r+1'b1;  //���
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
                addr_shakehand_state<=3'd0;  //�ص�0״�ᣬ�ȴ���һ�ε؈}����
			
			end
		end
	


//----------------------------{end}----------------------------------------

//------------------{��ָ��?��begin}-----------------------------------
assign rready = inst_rready | data_rready;


reg[3:0] inst_rstate;
reg cancel_read; //�����״̬�й�����cancel_read
wire real_cancel;
reg inst_rready;
	//reg base_changed;
//��������£�inst_rstate��״̬����Ϊ9,0,1,2,3,4,5,6,7,8��9��?
//ע�⣬����(����)״��Ϊ9
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
		else if (~rready&rvalid&(inst_rstate==4'd9)&(rid==4'd0)&~rlast)  //��һ��rvalid�������ʱrreadyӦ��Ϊ�͵�ƽ����د��ʱ�����ڿ�ʼ��rready���,��0״�Ὺʼ����ָ������
		begin
		    inst_rready<=1'b1;
			inst_rstate<=4'd0;
		end
		else if (rready&rvalid&(inst_rstate==4'd9)&(rid==4'd0)&~rlast) //inst_rstate==1'd1��ʱ��queue_count_rֻ����Ϊ0��1,��Ȼ��������
        begin	
		    inst_rready<=1'b1;
			rdata_inst[0]<=rdata;
			axi_pc_base<=inst_addr_queue[0][31:5]; //��ͷ����
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
		else if (rready&rvalid&(inst_rstate==4'd0)&(rid==4'd0)&~rlast) //inst_rstate==1'd1��ʱ��queue_count_rֻ����Ϊ0��1,��Ȼ��������
        begin	
			rdata_inst[0]<=rdata;
			axi_pc_base<=inst_addr_queue[0][31:5]; //��ͷ����
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

//--------------------{��ָ��?��end}------------------------------------------
//-------------------{������?��begin} ------------------------------------
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
		//Ϊ�˽����ָ��Ͷ����ݽ����ص����
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


	
//--------------------{����Icache  begin}---------------------------------------
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

	//��cancel��valid_revisedͬʱ������ʱ��rvalid_instҲ�ޔ�
	//���ڵȴ���Ч��ȡָ��ʱæ��rvalid_inst_cancel���ɸߵ�ƽ��ֱ��rvalid_inst�������˶�ʱ��ȡ����ָ��Ȼ����Ч�ģ�IF_over�Խ�Ϊ�͵�ƽ
 
    //rready�����̸��µ�IP�˵ģ�IP�˷���rvali��û�յ�rready��һֱ��rvali?
	
	//��֪���ǵڼ����޸ģ���Ϊ����rvalid_inst���ܻ��cancel�ź�د���{
	//����ִ���˲���ִ�е�ָ��޸�ʵ��Ϊ����״�����Ǩ�ƣ�Ǩ��״����د
	//��ΪIF_over����͸��IF_allow_in
	//״�W0����IF_OVERد����ź�
	//״�W1:״�W0����waiting_inst����ת�����Ņ�
	//״�W2:״�W1����rvalid_inst����ת����״��
	//״�W3:״�W1���յ�rvalid_inst&cancel��ת����״�W
	//״�W4��״��1���յ�cancel�źź���ת����״��
	//״�W5��״��3���յ�rvalid_ins�źź���ת����״��
	//״�W6:״�W4���յ�rvalid_inst�źź���ת�����Ņ�
	//״�W7��״��6�յ�rvalid_inst�ź����ת����״��
	 //�¼�د��״��9:״�W0����waiting_inst&cancel����ת�����Ņ�,�¸�״��Ϊ4
	//���У�״��2,5,7���¸�����IF_OVERΪ�ߵ�ƽ�����ص�״�W0

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
		else if ((awstate==4'd0)&cache_axi_wr& (awvalid == 1'b0)&(cache_awlen==8'd7))//load������store
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
		else if ((awstate==4'd0)&cache_axi_wr& (awvalid  == 1'b0) &(cache_awlen==8'd0))//load������store
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


//-------------------------{��ģ��ʵ����}begin---------------------------//
    wire next_fetch; //��������ȡָģ�飬��Ҫ������PC��
    //IF�������ʱ��������PCֵ��ȡ��د��ָ��
	
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
    fetch IF_module(             // ȡָ��
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
        
        //5����ˮ�����Ӆ�
        .exc_bus   (exc_bus   ),  // I, 32
        .is_ds     (inst_jbr  ),  // I, 1
        .ID_pc     (ID_pc     ),
        //չʾPC��ȡ����ָ��
	
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

    decode ID_module(               // ������
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
        
        //5����ˮ��
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
		
        //չʾPC
        .ID_pc       (ID_pc       ) // O, 32
    ); 

    exe EXE_module(                   // ִ����
        .EXE_valid   (EXE_valid   ),  // I, 1
        .ID_EXE_bus_r(ID_EXE_bus_r),  // I, 180
        .EXE_over    (EXE_over    ),  // O, 1 
        .EXE_MEM_bus (EXE_MEM_bus ),  // O, 196
        
        //5����ˮ��
        .clk         (clk         ),  // I, 1
        .EXE_wdest   (EXE_wdest   ),  // O, 5
        
		//.MemRead(MemRead),
		.EXE_rs_value(EXE_rs_value),
		.EXE_bypass_en(EXE_bypass_en),
        //չʾPC
        .EXE_pc      (EXE_pc      )   // O, 32
    );

    mem MEM_module(                     // �ô���
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
        
        //5����ˮ�����Ӆ�
        .MEM_allow_in (MEM_allow_in ),  // I, 1
        .MEM_wdest    (MEM_wdest    ),  // O, 5
        
		.MEM_rs_value(MEM_rs_value),
		.MEM_bypass_en(MEM_bypass_en),
		.cancel(cancel),
        //չʾPC
        .MEM_pc       (MEM_pc       ),   // O, 32
        
		.data_req(data_req),
	    .vdata_addr(vdata_addr),
	    .dm_load_launched(dm_load_launched),
	    .rvalid_dm(rvalid_dm),//O,1
	    .axi_rdata(rdata_load),	//O,128
	   // .buffer_wen(buffer_wen),
	   // .buffer_data(buffer_data),
	    //.is_buffer_full( is_buffer_full),
		//cache��axi��?д�����WҪ���ź�
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
 
    wb WB_module(                     // д����
        .WB_valid    (WB_valid    ),  // I, 1
        .MEM_WB_bus_r(MEM_WB_bus_r),  // I, 119
		.CP0_WB_bus_r(CP0_WB_bus),
        .rf_wen      (rf_wen      ),  // O, 1
        .rf_wdest    (rf_wdest    ),  // O, 5
        .rf_wdata    (rf_wdata    ),  // O, 32
        .WB_over     (WB_over     ),  // O, 1
        
        //5����ˮ�����Ӆ�
        .clk         (clk         ),  // I, 1
        .resetn      (resetn      ),  // I, 1
        .exc_bus     (exc_bus     ),  // O, 32
        .WB_wdest    (WB_wdest    ),  // O, 5
        .cancel      (cancel      ),  // O, 1
        
        //չʾPC��HI/LO��
        .WB_pc       (WB_pc       ),  // O, 32
        .HI_data     (HI_data     ),  // O, 32
        .LO_data     (LO_data     )   // O, 32
    );

    //inst_rom inst_rom_module(         // ָ��洢��
    //    .clka       (aclk           ),  // I, 1 ,ʱ��
    //    .addra      (inst_addr[9:2]),  // I, 8 ,ָ���ַ
    //    .douta      (inst          )   // O, 32,ָ��
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

    regfile rf_module(        // �Ĵ�����ģ��
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

//--------------------------{��ģ��ʵ����}end----------------------------//
endmodule
