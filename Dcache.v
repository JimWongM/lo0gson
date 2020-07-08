`timescale 1ns / 1ps

//
// Description: 
// A simple Icache module for IF to fetch instructions.For it is read-only,we don't need write strategy,but we do need think about miss.
// For our Icache,it is defined as a directly-mapped cache,whose size is 8KB and block size is 4byte.
// the number of total entries is computed as follows:
// 16KB/4*4 = 1K
// the number of bits for index:
// n=log L = log 1K = 10
// the number of bits for tag:
// 32-10-2=20
// therefore, for a given address[31:0],
// tag = address[31:12]
// index = address[11:2]
// 
// 
// the size of per entry is: 4*8(data)+1(valid)+tag(20)=53
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
// 7.9日更新:
// 在替换dirty位有效的cache项时，直接写回，而不写入写缓冲区
// 在读写confreg地址时，直接向axi发送请求
//////////////////////////////////////////////////////////////////////////////////

module Dcache(
	input wire 			clk,
	input wire          resetn,
	
	input wire         EXE_over ,
	input wire         MEM_allow_in,
	
	input wire cache_request,
	input wire cache_wr,
	input wire[3:0] dm_wen,
	input wire[31:0] dm_addr,
	input wire[31:0] dm_wdata,
	output reg[31:0] data_from_cache,
	output reg cache_over,
	
	output reg data_req,
	output reg[31:0] vdata_addr,
	input wire dm_load_launched,
	input wire rvalid_dm,
	
	//2019/7/10
	input wire[255:0] axi_rdata,

	input wire is_sw,
	input wire load_addr_exc,
	input wire cancel,
	//发送写请求需要的信号
	output    reg[31:0]       cache_axi_addr,
	output    reg[255:0]    cache_axi_wdata,
	output reg[3:0]       cache_dm_wen,
	//output reg          buffer_data_req,
	output reg           cache_axi_wr,
	output reg[7:0]           cache_awlen,
	output reg[7:0]           cache_arlen
	//input  wire           wdata_unfinished
	
	
	
);

`define confreg_addr_1  24'h1faf80    //bfaf8000~bfaf801c

`define LED_ADDR       32'h1faff000   //32'hbfaf_f000 

`define LED_RG0_ADDR   32'h1faff004   //32'hbfaf_f004 

`define LED_RG1_ADDR   32'h1faff008   //32'hbfaf_f008    //bfaff000~bfaff008 

`define NUM_ADDR       32'h1faff010   //32'hbfaf_f010  

`define confreg_addr_2  28'h1faff02   //bfaff020~bfaff02c

`define TIMER_ADDR     32'h1fafe000   //32'hbfaf_e000 

`define IO_SIMU_ADDR      32'h1fafffec  //32'hbfaf_ffec

`define confreg_addr_3   28'h1faffff   //bfaffff0~bfaffffc

wire [8:0] is_confreg_addr;
assign is_confreg_addr[0] = (dm_addr[31:8] == `confreg_addr_1) ? 1'b1 : 1'b0;
assign is_confreg_addr[1] = (dm_addr[31:0] == `LED_ADDR) ? 1'b1 : 1'b0;
assign is_confreg_addr[2] = (dm_addr[31:0] == `LED_RG0_ADDR) ? 1'b1 : 1'b0;
assign is_confreg_addr[3] = (dm_addr[31:0] == `LED_RG1_ADDR) ? 1'b1 : 1'b0;
assign is_confreg_addr[4] = (dm_addr[31:0] == `NUM_ADDR) ? 1'b1 : 1'b0;
assign is_confreg_addr[5] = (dm_addr[31:4] == `confreg_addr_2) ? 1'b1 : 1'b0;
assign is_confreg_addr[6] = (dm_addr[31:0] == `TIMER_ADDR) ? 1'b1 : 1'b0;
assign is_confreg_addr[7] = (dm_addr[31:0] == `IO_SIMU_ADDR) ? 1'b1 : 1'b0;
assign is_confreg_addr[8] = (dm_addr[31:4] == `confreg_addr_3) ? 1'b1 : 1'b0;
  

wire [6:0] index;
wire [19:0] tag;
wire [2:0] offset;//块大小为8字

wire[3:0]  hit_hit; //四路组相连

wire [19:0]  cache_tag0;
wire  cache_valid0 ;
wire  dirty_bit0 ;
wire[255:0] curr_entry0;

wire[19:0]  cache_tag1;
wire cache_valid1 ;
wire  dirty_bit1 ;
wire[255:0] curr_entry1;

wire[19:0]  cache_tag2;
wire  cache_valid2 ;
wire  dirty_bit2 ;
wire[255:0] curr_entry2;

wire  [19:0]  cache_tag3;
wire  cache_valid3 ;
wire  dirty_bit3 ;
wire[255:0] curr_entry3;

//data from 4 caches
//24
wire [279:0] curr_entry_wire0;
wire [279:0] curr_entry_wire1;
wire [279:0] curr_entry_wire2;
wire [279:0] curr_entry_wire3;

wire [1:0] LRU0;
wire [1:0] LRU1;
wire [1:0] LRU2;
wire [1:0] LRU3;

assign {cache_valid0,dirty_bit0,LRU0,cache_tag0,curr_entry0} = curr_entry_wire0;
assign {cache_valid1,dirty_bit1,LRU1,cache_tag1,curr_entry1} = curr_entry_wire1;
assign {cache_valid2,dirty_bit2,LRU2,cache_tag2,curr_entry2} = curr_entry_wire2;
assign {cache_valid3,dirty_bit3,LRU3,cache_tag3,curr_entry3} = curr_entry_wire3; 


reg[3:0]  state ;
reg[279:0] cache_wdata0;
reg[279:0] cache_wdata1;
reg[279:0] cache_wdata2;
reg[279:0] cache_wdata3;



assign index = dm_addr[11:5];
assign tag = dm_addr[31:12];
assign offset = dm_addr[4:2];



assign hit_hit  = cache_valid0&(tag==cache_tag0) ? 4'h1 : 
				  cache_valid1&(tag==cache_tag1) ? 4'h2 :
				  cache_valid2&(tag==cache_tag2) ? 4'h4 :				  
				  cache_valid3&(tag==cache_tag3) ? 4'h8 : 4'h0;

//如果是读命中直接把hit_data给data_from_cache就行了
wire[255:0] hit_data;
assign hit_data = (hit_hit == 4'h1) ? curr_entry0 :
				  (hit_hit == 4'h2) ? curr_entry1 :
				  (hit_hit == 4'h4) ? curr_entry2 :
				  (hit_hit == 4'h8) ? curr_entry3 :  256'd0;
wire[31:0]  hit_data_data;
assign hit_data_data = (offset==3'b000) ? hit_data[31:0] :
                       (offset==3'b001) ? hit_data[63:32] :
                       (offset==3'b010) ? hit_data[95:64] : 
					   (offset==3'b011) ? hit_data[127:96]:
					   (offset==3'b100) ? hit_data[159:128]:
					   (offset==3'b101) ? hit_data[191:160]:
					   (offset==3'b110) ? hit_data[223:192]:hit_data[255:224];
				  

wire[3:0] dm_final_wen;
//wire[31:0] cache_final_wen;
assign dm_final_wen = dm_wen & {4{~cancel}};
                 

wire [31:0] write_hit_data;//写命中时写回的数据
assign write_hit_data =  (dm_final_wen==4'b0001) ?  {hit_data_data[31:8],dm_wdata[7:0]} :
						 (dm_final_wen==4'b0010) ?  {hit_data_data[31:16],dm_wdata[15:8],hit_data_data[7:0]} :
						 (dm_final_wen==4'b0100) ?  {hit_data_data[31:24],dm_wdata[23:16],hit_data_data[15:0]} :
						 (dm_final_wen==4'b1000) ?  {dm_wdata[31:24],hit_data_data[23:0]} :
						 (dm_final_wen==4'b1110) ?  {dm_wdata[31:8],hit_data_data[7:0]} :
						 (dm_final_wen==4'b1100) ?  {dm_wdata[31:16],hit_data_data[15:0]} :
						 (dm_final_wen==4'b0011) ?  {hit_data_data[31:16],dm_wdata[15:0]} :
						 (dm_final_wen==4'b0111) ?  {hit_data_data[31:24],dm_wdata[23:0]} :
						 (dm_final_wen==4'b1111) ?  dm_wdata :  hit_data_data;


wire[255:0]  write_axi_data;  //写缺失时写回的数据
//wire[31:0]  axi_rdata; //真正要写的数据
wire[31:0] axi_single_rdata;
assign axi_single_rdata = 	(|is_confreg_addr) ?  axi_rdata[31:0] :
                        (offset==3'b000) ? axi_rdata[31:0] :
						(offset==3'b001) ?  axi_rdata[63:32] :
						(offset==3'b010) ? axi_rdata[95:64] :
						(offset==3'b011) ? axi_rdata[127:96]:
						(offset==3'b100) ? axi_rdata[159:128]:
						(offset==3'b101) ? axi_rdata[191:160]:
						(offset==3'b110) ? axi_rdata[223:192]: axi_rdata[255:224];						
wire[31:0] final_axi_wdata;
assign final_axi_wdata = (dm_final_wen==4'b0001) ?  {axi_single_rdata[31:8],dm_wdata[7:0]} :
						 (dm_final_wen==4'b0010) ?  {axi_single_rdata[31:16],dm_wdata[15:8],axi_single_rdata[7:0]} :
						 (dm_final_wen==4'b0100) ?  {axi_single_rdata[31:24],dm_wdata[23:16],axi_single_rdata[15:0]} :
						 (dm_final_wen==4'b1000) ?  {dm_wdata[31:24],axi_single_rdata[23:0]} :
						 (dm_final_wen==4'b1110) ?  {dm_wdata[31:8],axi_single_rdata[7:0]} :
						 (dm_final_wen==4'b1100) ?  {dm_wdata[31:16],axi_single_rdata[15:0]} :
						 (dm_final_wen==4'b0011) ?  {axi_single_rdata[31:16],dm_wdata[15:0]} :
						 (dm_final_wen==4'b0111) ?  {axi_single_rdata[31:24],dm_wdata[23:0]} :
						 (dm_final_wen==4'b1111) ?  dm_wdata :  axi_single_rdata;
						 
assign  write_axi_data = (offset==3'b000) ? {axi_rdata[255:32],final_axi_wdata} :
						 (offset==3'b001) ? {axi_rdata[255:64],final_axi_wdata,axi_rdata[31:0]} :
                         (offset==3'b010) ? {axi_rdata[255:96],final_axi_wdata,axi_rdata[63:0]} :
						 (offset==3'b011) ? {axi_rdata[255:128],final_axi_wdata,axi_rdata[95:0]}:
						 (offset==3'b100) ? {axi_rdata[255:160],final_axi_wdata,axi_rdata[127:0]}:
						 (offset==3'b101) ? {axi_rdata[255:192],final_axi_wdata,axi_rdata[159:0]}:
						 (offset==3'b110) ? {axi_rdata[255:224],final_axi_wdata,axi_rdata[191:0]} : {final_axi_wdata,axi_rdata[223:0]};  

wire[1:0] ULRU0;
wire[1:0] ULRU1;
wire[1:0] ULRU2;
wire[1:0] ULRU3;
assign ULRU0 = (~(|is_confreg_addr)&&cache_valid0) ?  LRU0+1'b1 : LRU0;
assign ULRU1 = (~(|is_confreg_addr)&&cache_valid1) ?  LRU1+1'b1 : LRU1;
assign ULRU2 = (~(|is_confreg_addr)&&cache_valid2) ?  LRU2+1'b1 : LRU2;
assign ULRU3 = (~(|is_confreg_addr)&&cache_valid3) ?  LRU3+1'b1 : LRU3;	

wire[1:0] RLRU0;
wire[1:0] RLRU1;
wire[1:0] RLRU2;
wire[1:0] RLRU3;
assign RLRU0 = ((cache_request&&(|hit_hit))&&hit_hit[0]) ? 2'b00 :
			               (hit_hit[1]&&(LRU1>LRU0)&&cache_valid0) ?  LRU0+1'b1 : 
						   (hit_hit[2]&&(LRU2>LRU0)&&cache_valid0) ?  LRU0+1'b1 :
						   (hit_hit[3]&&(LRU3>LRU0)&&cache_valid0) ? LRU0+1'b1 :  LRU0;
assign RLRU1 = ((cache_request&&(|hit_hit))&&hit_hit[1]) ? 2'b00 :
			               (hit_hit[0]&&(LRU0>LRU1)&&cache_valid1) ? LRU1+1'b1 : 
						   (hit_hit[2]&&(LRU2>LRU1)&&cache_valid1) ?  LRU1+1'b1 :
						   (hit_hit[3]&&(LRU3>LRU1)&&cache_valid1) ?  LRU1+1'b1 :  LRU1;
assign RLRU2 = ((cache_request&&(|hit_hit))&&hit_hit[2]) ? 2'b00 :
			               (hit_hit[1]&&(LRU1>LRU2)&&cache_valid2) ?  LRU2+1'b1 : 
						   (hit_hit[0]&&(LRU0>LRU2)&&cache_valid2) ?  LRU2+1'b1 :
						   (hit_hit[3]&&(LRU3>LRU2)&&cache_valid2) ?  LRU2+1'b1 :  LRU2;
						   
assign RLRU3 = ((cache_request&&(|hit_hit))&&hit_hit[3]) ? 2'b00 :
			               (hit_hit[1]&&(LRU1>LRU3)&&cache_valid3) ? LRU3+1'b1 : 
						   (hit_hit[2]&&(LRU2>LRU3)&&cache_valid3) ? LRU3+1'b1 :
						   (hit_hit[0]&&(LRU0>LRU3)&&cache_valid3) ? LRU3+1'b1 :  LRU3;				 


	reg[31:0] hit_count;
	reg Dcache_wren;
	reg[6:0] Dcache_windex;
	wire[6:0] cache_index;
	assign cache_index = Dcache_wren ? Dcache_windex : index;
   always @(posedge clk) 
   begin
		if(EXE_over & MEM_allow_in)
		begin
			cache_over <= 1'b0;
		end
        if(!resetn)
        begin 
			hit_count <= 0;
			Dcache_windex <= 7'd0;
			Dcache_wren <= 1'b0;
			cache_over <= 1'b0;
			state<=4'd0;  //防止写后命中。。。
		    //buffer_wen <= 1'b0;
		   // buffer_data <=63'd0;
		   // cache_addr <= 8'd0;
		    cache_wdata0 <= 279'd0 ;
			cache_wdata1 <= 279'd0 ;
			cache_wdata2 <= 279'd0 ;
			cache_wdata3 <= 279'd0 ;
			
			data_req<=1'b0;
			cache_axi_wr<=1'b0;
			cache_axi_addr<=32'd0;
			cache_axi_wdata<=255'd0;
			cache_dm_wen<=4'b0;
			cache_arlen<=8'd0;
			cache_awlen<=8'd0;
			
        end
		//地址错
		else if(load_addr_exc&&cache_request)
		begin
		    state<=4'd0;  
			data_req<=1'b0;
			cache_axi_wr<=1'b0;
			cache_axi_addr<=32'd0;
			cache_axi_wdata<=128'd0;
			cache_dm_wen<=4'd0;
			cache_arlen<=8'd0;
			cache_awlen<=8'd0;
			

		end
		else if((state==4'd0)&&cache_request&&~cache_wr&&~cache_over&&(|is_confreg_addr))//读confreg 地址
		begin
			state<= 4'd2;
			data_req <= 1'b1;
			vdata_addr <= dm_addr;
			cache_arlen<=8'd0;
			cache_awlen<=8'd0;
			
			
		end
		else if((state==4'd0)&&cache_request&&cache_wr&&~cache_over&&(|is_confreg_addr))//写confreg 地址数据
		begin
			cache_over <= 1'b1;
			cache_axi_wr<=1'b1;
			cache_axi_wdata<= {96'd0,dm_wdata};
			cache_axi_addr<= dm_addr;
			cache_dm_wen<=dm_final_wen;
			state<=4'd12;
			data_req <= 1'b0;
			cache_arlen<=8'd0;
			cache_awlen<=8'd0;
		end
		
		//读命中	
        else if((state==4'd0)&&cache_request&&(|hit_hit)&&~cache_wr)
		begin
			hit_count <= hit_count +1;
		    state<= 4'd10;
			Dcache_wren <= 1'b1;
			Dcache_windex <= index;
			cache_over <= 1'b1;
			//cache_wen <= 4'hf;
/* 			cache_wen[0] <= 19'h70000;
			cache_wen[1] <= 19'h70000;
			cache_wen[2] <= 19'h70000;
			cache_wen[3] <= 19'h70000; */
			//cache_wdata <= 127'd0 ;
			//更新LRU
			cache_wdata0 <= {cache_valid0,dirty_bit0,RLRU0,cache_tag0,curr_entry0};
			cache_wdata1 <= {cache_valid1,dirty_bit1,RLRU1,cache_tag1,curr_entry1};
			cache_wdata2 <= {cache_valid2,dirty_bit2,RLRU2,cache_tag2,curr_entry2};
			cache_wdata3 <= {cache_valid3,dirty_bit3,RLRU3,cache_tag3,curr_entry3};
			data_from_cache<=hit_data_data;
			

		end	
		//读缺失,替换时写回带脏位的cache块
		
		else if((state==4'd0)&&cache_request&&~(|hit_hit)&&~cache_wr)
		begin 
		    state<= 4'd2;
			data_req <= 1'b1;
			vdata_addr <= {dm_addr[31:5],5'd0};
			cache_arlen<=8'd7;
		    if((LRU0==2'b11)&&dirty_bit0)
			begin  
			  cache_axi_wr<=1'b1;
			  cache_axi_wdata<= curr_entry0;
			  cache_axi_addr<= {cache_tag0,index,5'd0}; 
			  cache_dm_wen<=4'b1111;
			  cache_awlen<=8'd7;
			 
			  
			end	    
			else if(LRU1 == 2'b11&&dirty_bit1)
			begin
			  cache_axi_wr<=1'b1;
			  cache_axi_wdata<= curr_entry1;
			  cache_axi_addr<= {cache_tag1,index,5'd0}; 
			  cache_dm_wen<=4'b1111;
			  cache_awlen<=8'd7;
			end
			else if(LRU2== 2'b11&&dirty_bit2)
			begin
			  cache_axi_wr<=1'b1;
			  cache_axi_wdata<= curr_entry2;
			  cache_axi_addr<= {cache_tag2,index,5'd0}; 
			  cache_dm_wen<=4'b1111;
			  cache_awlen<=8'd7;
			end 
			else if(LRU3 == 2'b11&&dirty_bit3)
			begin
			  cache_axi_wr<=1'b1;
			  cache_axi_wdata<= curr_entry3;
			  cache_axi_addr<= {cache_tag3,index,5'd0}; 
			  cache_dm_wen<=4'b1111;
			  cache_awlen<=8'd7;
			end
		end
		//写命中
		else if((state==4'd0)&&cache_request&&cache_wr&&(|hit_hit))
		begin
			hit_count <= hit_count +1;
			Dcache_wren <= 1'b1;
			cache_over <= 1'b1;
			Dcache_windex <= index;
		    state <= 4'd3;
			//cache_wen <= 4'hf;
			
			if(hit_hit[0])
			begin
			cache_wdata1 <= {cache_valid1,dirty_bit1,RLRU1,cache_tag1,curr_entry1};
			cache_wdata2 <= {cache_valid2,dirty_bit2,RLRU2,cache_tag2,curr_entry2};
			cache_wdata3 <= {cache_valid3,dirty_bit3,RLRU3,cache_tag3,curr_entry3};
			cache_wdata0[279:256] <= {cache_valid0,1'b1,RLRU0,cache_tag0};
				case(offset)
				3'b000: cache_wdata0[255:0] <= {curr_entry0[255:32],write_hit_data};
				3'b001: cache_wdata0[255:0] <= {curr_entry0[255:64],write_hit_data,curr_entry0[31:0]};
				3'b010: cache_wdata0[255:0] <= {curr_entry0[255:96],write_hit_data,curr_entry0[63:0]};
				3'b011: cache_wdata0[255:0] <= {curr_entry0[255:128],write_hit_data,curr_entry0[95:0]};
				3'b100: cache_wdata0[255:0] <= {curr_entry0[255:160],write_hit_data,curr_entry0[127:0]};
				3'b101: cache_wdata0[255:0] <= {curr_entry0[255:192],write_hit_data,curr_entry0[159:0]};
				3'b110: cache_wdata0[255:0] <= {curr_entry0[255:224],write_hit_data,curr_entry0[191:0]};
				default :cache_wdata0[255:0] <= {write_hit_data,curr_entry0[223:0]};
				endcase

			end
			else if(hit_hit[1])
			begin
			cache_wdata0 <= {cache_valid0,dirty_bit0,RLRU0,cache_tag0,curr_entry0};
			cache_wdata2 <= {cache_valid2,dirty_bit2,RLRU2,cache_tag2,curr_entry2};
			cache_wdata3 <= {cache_valid3,dirty_bit3,RLRU3,cache_tag3,curr_entry3};
			cache_wdata1[279:256] <= {cache_valid1,1'b1,RLRU1,cache_tag1};
				case(offset)
				3'b000: cache_wdata1[255:0] <= {curr_entry1[255:32],write_hit_data};
				3'b001: cache_wdata1[255:0] <= {curr_entry1[255:64],write_hit_data,curr_entry1[31:0]};
				3'b010: cache_wdata1[255:0] <= {curr_entry1[255:96],write_hit_data,curr_entry1[63:0]};
				3'b011: cache_wdata1[255:0] <= {curr_entry1[255:128],write_hit_data,curr_entry1[95:0]};
				3'b100: cache_wdata1[255:0] <= {curr_entry1[255:160],write_hit_data,curr_entry1[127:0]};
				3'b101: cache_wdata1[255:0] <= {curr_entry1[255:192],write_hit_data,curr_entry1[159:0]};
				3'b110: cache_wdata1[255:0] <= {curr_entry1[255:224],write_hit_data,curr_entry1[191:0]};
				default :cache_wdata1[255:0] <= {write_hit_data,curr_entry1[223:0]};
				endcase

			end
			else if(hit_hit[2])
			begin
			cache_wdata0 <= {cache_valid0,dirty_bit0,RLRU0,cache_tag0,curr_entry0};
			cache_wdata1 <= {cache_valid1,dirty_bit1,RLRU1,cache_tag1,curr_entry1};
			cache_wdata3 <= {cache_valid3,dirty_bit3,RLRU3,cache_tag3,curr_entry3};
			cache_wdata2[279:256] <= {cache_valid2,1'b1,RLRU2,cache_tag2};
				case(offset)
				3'b000: cache_wdata2[255:0] <= {curr_entry2[255:32],write_hit_data};
				3'b001: cache_wdata2[255:0] <= {curr_entry2[255:64],write_hit_data,curr_entry2[31:0]};
				3'b010: cache_wdata2[255:0] <= {curr_entry2[255:96],write_hit_data,curr_entry2[63:0]};
				3'b011: cache_wdata2[255:0] <= {curr_entry2[255:128],write_hit_data,curr_entry2[95:0]};
				3'b100: cache_wdata2[255:0] <= {curr_entry2[255:160],write_hit_data,curr_entry2[127:0]};
				3'b101: cache_wdata2[255:0] <= {curr_entry2[255:192],write_hit_data,curr_entry2[159:0]};
				3'b110: cache_wdata2[255:0] <= {curr_entry2[255:224],write_hit_data,curr_entry2[191:0]};
				default :cache_wdata2[255:0] <= {write_hit_data,curr_entry2[223:0]};
				endcase

			end
			else if(hit_hit[3])
			begin
			cache_wdata0 <= {cache_valid0,dirty_bit0,RLRU0,cache_tag0,curr_entry0};
			cache_wdata1 <= {cache_valid1,dirty_bit1,RLRU1,cache_tag1,curr_entry1};
			cache_wdata2 <= {cache_valid2,dirty_bit2,RLRU2,cache_tag2,curr_entry2};
			cache_wdata3[279:256] <= {cache_valid3,1'b1,RLRU3,cache_tag3};
				case(offset)
				3'b000: cache_wdata3[255:0] <= {curr_entry3[255:32],write_hit_data};
				3'b001: cache_wdata3[255:0] <= {curr_entry3[255:64],write_hit_data,curr_entry3[31:0]};
				3'b010: cache_wdata3[255:0] <= {curr_entry3[255:96],write_hit_data,curr_entry3[63:0]};
				3'b011: cache_wdata3[255:0] <= {curr_entry3[255:128],write_hit_data,curr_entry3[95:0]};
				3'b100: cache_wdata3[255:0] <= {curr_entry3[255:160],write_hit_data,curr_entry3[127:0]};
				3'b101: cache_wdata3[255:0] <= {curr_entry3[255:192],write_hit_data,curr_entry3[159:0]};
				3'b110: cache_wdata3[255:0] <= {curr_entry3[255:224],write_hit_data,curr_entry3[191:0]};
				default :cache_wdata3[255:0] <= {write_hit_data,curr_entry3[223:0]};
				endcase
			end 
		end
		//写缺失，跟读缺失逻辑相同，都要选择替换块，并向AXI发送读数据请求
		else if((state ==4'd0)&&cache_request&&cache_wr&&~(|hit_hit)&&~cache_over)
		begin
			state<= 4'd4;
			data_req <= 1'b1;
			vdata_addr <= {dm_addr[31:5],5'd0};
			cache_arlen<=8'd7;
		    if((LRU0==2'b11)&&dirty_bit0)
			begin  
			  cache_axi_wr<=1'b1;
			  cache_axi_wdata<= curr_entry0;
			  cache_axi_addr<= {cache_tag0,index,5'd0}; 
			  cache_dm_wen<=4'b1111;
			  cache_awlen<=8'd7;
			end	    
			else if(LRU1 == 2'b11&&dirty_bit1)
			begin
			  cache_axi_wr<=1'b1;
			  cache_axi_wdata<= curr_entry1;
			  cache_axi_addr<= {cache_tag1,index,5'd0}; 
			  cache_dm_wen<=4'b1111;
			  cache_awlen<=8'd7;
			end
			else if(LRU2 == 2'b11&&dirty_bit2)
			begin
			  cache_axi_wr<=1'b1;
			  cache_axi_wdata<= curr_entry2;
			  cache_axi_addr<= {cache_tag2,index,5'd0}; 
			  cache_dm_wen<=4'b1111;
			  cache_awlen<=8'd7;
			end 
			else if(LRU3 == 2'b11&&dirty_bit3)
			begin
			  cache_axi_wr<=1'b1;
			  cache_axi_wdata<= curr_entry3;
			  cache_axi_addr<= {cache_tag3,index,5'd0}; 
			  cache_dm_wen<=4'b1111;
			  cache_awlen<=8'd7;
			end
		
		end
		else if(dm_load_launched&&((state==4'd2 | state == 4'd4)))
		begin
		    state<=4'd5;
			data_req<=1'b0;
			cache_axi_wr<=1'b0;
		end
		else if(state==4'd5 && rvalid_dm&&(|is_confreg_addr))
		begin
		    state<=4'd6;
			data_from_cache<=axi_single_rdata;
			cache_over <= 1'b1;
		end
		else if(state==4'd5 && rvalid_dm&&~(|is_confreg_addr))
		begin
		   //AXI总线的数据已取到，更新cache状态
			state<=4'd6;
			cache_over <= 1'b1;
			Dcache_wren <= 1'b1;
			Dcache_windex <= index;
			//cache_wen <= 4'hf;
			//替换的是cache0
			if(LRU0==2'b11)
			begin
			  cache_wdata1 <= {cache_valid1,dirty_bit1,ULRU1,cache_tag1,curr_entry1};
			  cache_wdata2 <= {cache_valid2,dirty_bit2,ULRU2,cache_tag2,curr_entry2};
			  cache_wdata3 <= {cache_valid3,dirty_bit3,ULRU3,cache_tag3,curr_entry3};
			  if(cache_wr)
				begin
				//cache_wen[0] <= 19'h7ffff;
				cache_wdata0 <= {1'b1,1'b1,2'b00,tag,write_axi_data};
				end
			  else
				begin
				//cache_wen[0] <= 19'h7ffff;
				cache_wdata0 <= {1'b1,1'b0,2'b00,tag,axi_rdata};			
				data_from_cache<=axi_single_rdata;
				end
			end
			
			else if(LRU1==2'b11)
			begin
			  cache_wdata0 <= {cache_valid0,dirty_bit0,ULRU0,cache_tag0,curr_entry0};
			  cache_wdata2 <= {cache_valid2,dirty_bit2,ULRU2,cache_tag2,curr_entry2};
			  cache_wdata3 <= {cache_valid3,dirty_bit3,ULRU3,cache_tag3,curr_entry3};
			  if(cache_wr)
				begin
				//cache_wen[1] <= 19'h7ffff;
				cache_wdata1 <= {1'b1,1'b1,2'b00,tag,write_axi_data};
				end
			  else
				begin
				//cache_wen[1] <= 19'h7ffff;
				cache_wdata1 <= {1'b1,1'b0,2'b00,tag,axi_rdata};			
				data_from_cache<=axi_single_rdata;
				end
			end
			else if(LRU2==2'b11)
			begin
			  cache_wdata0 <= {cache_valid0,dirty_bit0,ULRU0,cache_tag0,curr_entry0};
			  cache_wdata1 <= {cache_valid1,dirty_bit1,ULRU1,cache_tag1,curr_entry1};
			  cache_wdata3 <= {cache_valid3,dirty_bit3,ULRU3,cache_tag3,curr_entry3};
			  if(cache_wr)
				begin
				//cache_wen[2] <= 19'h7ffff;
				cache_wdata2 <= {1'b1,1'b1,2'b00,tag,write_axi_data};
				end
			  else
				begin
				//cache_wen[2] <= 19'h7ffff;
				cache_wdata2 <= {1'b1,1'b0,2'b00,tag,axi_rdata};			
				data_from_cache<=axi_single_rdata;
				end
			end
			else if(LRU3==2'b11)
			begin
			  cache_wdata0 <= {cache_valid0,dirty_bit0,ULRU0,cache_tag0,curr_entry0};
			  cache_wdata2 <= {cache_valid2,dirty_bit2,ULRU2,cache_tag2,curr_entry2};
			  cache_wdata1 <= {cache_valid1,dirty_bit1,ULRU1,cache_tag1,curr_entry1};
			  if(cache_wr)
				begin
				//cache_wen[3] <= 19'h7ffff;
				cache_wdata3 <= {1'b1,1'b1,2'b00,tag,write_axi_data};
				end
			  else
				begin
				//cache_wen[3] <= 19'h7ffff;
				cache_wdata3 <= {1'b1,1'b0,2'b00,tag,axi_rdata};			
				data_from_cache<=axi_single_rdata;
				end
			end
		end
		//state10是读命中，state3是写命中，state6是读写缺失，state7
		else if((state==4'd10) | (state==4'd3)| (state==4'd6) |(state==4'd14) |(state==4'd15))
		begin
			state <= 4'd12;   //回到闲置状态
		end
/* 		else if(state==4'd11)
		begin
		   state<= 4'd12;
		end */
		else if(state==4'd12)
        begin
			Dcache_wren <= 1'b0;
            state<=4'd0;  
			data_req<=1'b0;
			cache_axi_wr<=1'b0;
			cache_axi_addr<=32'd0;
			cache_axi_wdata<=256'd0;
			cache_dm_wen<=4'd0;
			cache_arlen<=8'd0;
			cache_awlen<=8'd0;
			
		end
	end


	dist_ram Dcache_ram0(
	.a(cache_index),
	.d(cache_wdata0),
	.clk(clk),
	.we(Dcache_wren),
	.spo(curr_entry_wire0)
	);		

	dist_ram Dcache_ram1(
	.a(cache_index),
	.d(cache_wdata1),
	.clk(clk),
	.we(Dcache_wren),
	.spo(curr_entry_wire1)
	);		
	
	dist_ram Dcache_ram2(
	.a(cache_index),
	.d(cache_wdata2),
	.clk(clk),
	.we(Dcache_wren),
	.spo(curr_entry_wire2)
	);		
	
	dist_ram Dcache_ram3(
	.a(cache_index),
	.d(cache_wdata3),
	.clk(clk),
	.we(Dcache_wren),
	.spo(curr_entry_wire3)
	);		
     							 
endmodule