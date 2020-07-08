`timescale 1ns / 1ps

module tlb(                    // 取指级
    input             clk,       // 时钟
    input             resetn,    // 复位信号，低电平有效
	input             next_fetch,
	input             MEM_allow_in,
	input             EXE_over,
	input  [32:0]  fetch_tlb_bus,
	input  [33:0]  mem_tlb_bus,
	input  [164:0] cp0_tlb_bus,
	output [162:0] tlb_cp0_bus,
	output [35:0] tlb_fetch_bus,
	output [35:0] tlb_mem_bus
);

reg [26:0] entry_hi[31:0];
reg [11:0] page_mask[31:0];
reg G[31:0];
reg [24:0] entry_lo0[31:0];
reg [24:0] entry_lo1[31:0];



//正常查询的过程（指令地址转换）
wire tlb_fetch_valid;
wire [31:0] v_pc;
assign {v_pc , tlb_fetch_valid } = fetch_tlb_bus;

wire tlb_fetch_over;
wire tlb_fetch_refill;
wire tlb_fetch_invalid;
wire tlb_fetch_modified;
wire [31:0] tlb_pc_paddr;
assign tlb_fetch_bus = {tlb_fetch_over,tlb_fetch_refill,tlb_fetch_invalid,tlb_fetch_modified,tlb_pc_paddr};

//查询表项，是否命中
reg tlb_fetch_hit;
reg [4:0] tlb_fetch_index;
always @(posedge clk)
begin
	if((~resetn) | (~tlb_fetch_valid))
	begin
		tlb_fetch_hit <= 1'b0;
		tlb_fetch_index <= 5'd0;
	end
	else if((~(|page_mask[5'd0])) & (entry_hi[5'd0][26:8] == v_pc[31:13]) & ((G[5'd0]) |(entry_hi[5'd0][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd0;
	end
	else if((~(|page_mask[5'd1])) & (entry_hi[5'd1][26:8] == v_pc[31:13]) & ((G[5'd1]) |(entry_hi[5'd1][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd1;
	end
	else if((~(|page_mask[5'd2])) & (entry_hi[5'd2][26:8] == v_pc[31:13]) & ((G[5'd2]) |(entry_hi[5'd2][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd2;
	end
	else if((~(|page_mask[5'd3])) & (entry_hi[5'd3][26:8] == v_pc[31:13]) & ((G[5'd3]) |(entry_hi[5'd3][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd3;
	end
	else if((~(|page_mask[5'd4])) & (entry_hi[5'd4][26:8] == v_pc[31:13]) & ((G[5'd4]) |(entry_hi[5'd4][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd4;
	end
	else if((~(|page_mask[5'd5])) & (entry_hi[5'd5][26:8] == v_pc[31:13]) & ((G[5'd5]) |(entry_hi[5'd5][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd5;
	end
	else if((~(|page_mask[5'd6])) & (entry_hi[5'd6][26:8] == v_pc[31:13]) & ((G[5'd6]) |(entry_hi[5'd6][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd6;
	end
	else if((~(|page_mask[5'd7])) & (entry_hi[5'd7][26:8] == v_pc[31:13]) & ((G[5'd7]) |(entry_hi[5'd7][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd7;
	end
	else if((~(|page_mask[5'd8])) & (entry_hi[5'd8][26:8] == v_pc[31:13]) & ((G[5'd8]) |(entry_hi[5'd8][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd8;
	end
	else if((~(|page_mask[5'd9])) & (entry_hi[5'd9][26:8] == v_pc[31:13]) & ((G[5'd9]) |(entry_hi[5'd9][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd9;
	end
	else if((~(|page_mask[5'd10])) & (entry_hi[5'd10][26:8] == v_pc[31:13]) & ((G[5'd10]) |(entry_hi[5'd10][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd10;
	end
	else if((~(|page_mask[5'd11])) & (entry_hi[5'd11][26:8] == v_pc[31:13]) & ((G[5'd11]) |(entry_hi[5'd11][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd11;
	end
	else if((~(|page_mask[5'd12])) & (entry_hi[5'd12][26:8] == v_pc[31:13]) & ((G[5'd12]) |(entry_hi[5'd12][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd12;
	end
	else if((~(|page_mask[5'd13])) & (entry_hi[5'd13][26:8] == v_pc[31:13]) & ((G[5'd13]) |(entry_hi[5'd13][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd0;
	end
	else if((~(|page_mask[5'd14])) & (entry_hi[5'd14][26:8] == v_pc[31:13]) & ((G[5'd14]) |(entry_hi[5'd14][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd14;
	end
	else if((~(|page_mask[5'd15])) & (entry_hi[5'd15][26:8] == v_pc[31:13]) & ((G[5'd15]) |(entry_hi[5'd15][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd15;
	end
	else if((~(|page_mask[5'd16])) & (entry_hi[5'd16][26:8] == v_pc[31:13]) & ((G[5'd16]) |(entry_hi[5'd16][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd16;
	end
	else if((~(|page_mask[5'd17])) & (entry_hi[5'd17][26:8] == v_pc[31:13]) & ((G[5'd17]) |(entry_hi[5'd17][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd17;
	end
	else if((~(|page_mask[5'd18])) & (entry_hi[5'd18][26:8] == v_pc[31:13]) & ((G[5'd18]) |(entry_hi[5'd18][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd18;
	end
	else if((~(|page_mask[5'd19])) & (entry_hi[5'd19][26:8] == v_pc[31:13]) & ((G[5'd19]) |(entry_hi[5'd19][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd19;
	end
	else if((~(|page_mask[5'd20])) & (entry_hi[5'd20][26:8] == v_pc[31:13]) & ((G[5'd20]) |(entry_hi[5'd20][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd20;
	end
	else if((~(|page_mask[5'd21])) & (entry_hi[5'd21][26:8] == v_pc[31:13]) & ((G[5'd21]) |(entry_hi[5'd21][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd21;
	end
	else if((~(|page_mask[5'd22])) & (entry_hi[5'd22][26:8] == v_pc[31:13]) & ((G[5'd22]) |(entry_hi[5'd22][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd22;
	end
	else if((~(|page_mask[5'd23])) & (entry_hi[5'd23][26:8] == v_pc[31:13]) & ((G[5'd23]) |(entry_hi[5'd23][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd23;
	end
	else if((~(|page_mask[5'd24])) & (entry_hi[5'd24][26:8] == v_pc[31:13]) & ((G[5'd24]) |(entry_hi[5'd24][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd24;
	end
	else if((~(|page_mask[5'd25])) & (entry_hi[5'd25][26:8] == v_pc[31:13]) & ((G[5'd25]) |(entry_hi[5'd25][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd25;
	end	
	else if((~(|page_mask[5'd26])) & (entry_hi[5'd26][26:8] == v_pc[31:13]) & ((G[5'd26]) |(entry_hi[5'd26][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd26;
	end
	else if((~(|page_mask[5'd27])) & (entry_hi[5'd27][26:8] == v_pc[31:13]) & ((G[5'd27]) |(entry_hi[5'd27][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd27;
	end
	else if((~(|page_mask[5'd28])) & (entry_hi[5'd28][26:8] == v_pc[31:13]) & ((G[5'd28]) |(entry_hi[5'd28][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd28;
	end
	else if((~(|page_mask[5'd29])) & (entry_hi[5'd29][26:8] == v_pc[31:13]) & ((G[5'd29]) |(entry_hi[5'd29][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd29;
	end
	else if((~(|page_mask[5'd30])) & (entry_hi[5'd30][26:8] == v_pc[31:13]) & ((G[5'd30]) |(entry_hi[5'd30][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd30;
	end
	else if((~(|page_mask[5'd31])) & (entry_hi[5'd31][26:8] == v_pc[31:13]) & ((G[5'd31]) |(entry_hi[5'd31][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_fetch_hit <= 1'b1;
		tlb_fetch_index <= 5'd31;
	end
	else 
	begin
		tlb_fetch_hit <= 1'b0;
	end
end

/* assign {tlb_fetch_hit , tlb_fetch_index} = ((~(|page_mask[5'd0])) & (entry_hi[5'd0][26:8] == v_pc[31:13]) & ((G[5'd0]) |(entry_hi[5'd0][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd0} :
									((~(|page_mask[5'd1])) & (entry_hi[5'd1][26:8] == v_pc[31:13]) & ((G[5'd1]) |(entry_hi[5'd1][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd1} :
									((~(|page_mask[5'd2])) & (entry_hi[5'd2][26:8] == v_pc[31:13]) & ((G[5'd2]) |(entry_hi[5'd2][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd2} :
									((~(|page_mask[5'd3])) & (entry_hi[5'd3][26:8] == v_pc[31:13]) & ((G[5'd3]) |(entry_hi[5'd3][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd3} :
									((~(|page_mask[5'd4])) & (entry_hi[5'd4][26:8] == v_pc[31:13]) & ((G[5'd4]) |(entry_hi[5'd4][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd4} :
									((~(|page_mask[5'd5])) & (entry_hi[5'd5][26:8] == v_pc[31:13]) & ((G[5'd5]) |(entry_hi[5'd5][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd5} :
									((~(|page_mask[5'd6])) & (entry_hi[5'd6][26:8] == v_pc[31:13]) & ((G[5'd6]) |(entry_hi[5'd6][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd6} :
									((~(|page_mask[5'd7])) & (entry_hi[5'd7][26:8] == v_pc[31:13]) & ((G[5'd7]) |(entry_hi[5'd7][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd7} :
									((~(|page_mask[5'd8])) & (entry_hi[5'd8][26:8] == v_pc[31:13]) & ((G[5'd8]) |(entry_hi[5'd8][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd8} :
									((~(|page_mask[5'd9])) & (entry_hi[5'd9][26:8] == v_pc[31:13]) & ((G[5'd9]) |(entry_hi[5'd9][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd9} :
									((~(|page_mask[5'd10])) & (entry_hi[5'd10][26:8] == v_pc[31:13]) & ((G[5'd10]) |(entry_hi[5'd10][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd10} :
									((~(|page_mask[5'd11])) & (entry_hi[5'd11][26:8] == v_pc[31:13]) & ((G[5'd11]) |(entry_hi[5'd11][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd11} :
									((~(|page_mask[5'd12])) & (entry_hi[5'd12][26:8] == v_pc[31:13]) & ((G[5'd12]) |(entry_hi[5'd12][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd12} :
									((~(|page_mask[5'd13])) & (entry_hi[5'd13][26:8] == v_pc[31:13]) & ((G[5'd13]) |(entry_hi[5'd13][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd13} :
									((~(|page_mask[5'd14])) & (entry_hi[5'd14][26:8] == v_pc[31:13]) & ((G[5'd14]) |(entry_hi[5'd14][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd14} :
									((~(|page_mask[5'd15])) & (entry_hi[5'd15][26:8] == v_pc[31:13]) & ((G[5'd15]) |(entry_hi[5'd15][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd15} :
									((~(|page_mask[5'd16])) & (entry_hi[5'd16][26:8] == v_pc[31:13]) & ((G[5'd16]) |(entry_hi[5'd16][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd16} :
									((~(|page_mask[5'd17])) & (entry_hi[5'd17][26:8] == v_pc[31:13]) & ((G[5'd17]) |(entry_hi[5'd17][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd17} :
									((~(|page_mask[5'd18])) & (entry_hi[5'd18][26:8] == v_pc[31:13]) & ((G[5'd18]) |(entry_hi[5'd18][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd18} :
									((~(|page_mask[5'd19])) & (entry_hi[5'd19][26:8] == v_pc[31:13]) & ((G[5'd19]) |(entry_hi[5'd19][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd19} :
									((~(|page_mask[5'd20])) & (entry_hi[5'd20][26:8] == v_pc[31:13]) & ((G[5'd20]) |(entry_hi[5'd20][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd20} :
									((~(|page_mask[5'd21])) & (entry_hi[5'd21][26:8] == v_pc[31:13]) & ((G[5'd21]) |(entry_hi[5'd21][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd21} :
									((~(|page_mask[5'd22])) & (entry_hi[5'd22][26:8] == v_pc[31:13]) & ((G[5'd22]) |(entry_hi[5'd22][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd22} :
									((~(|page_mask[5'd23])) & (entry_hi[5'd23][26:8] == v_pc[31:13]) & ((G[5'd23]) |(entry_hi[5'd23][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd23} :
									((~(|page_mask[5'd24])) & (entry_hi[5'd24][26:8] == v_pc[31:13]) & ((G[5'd24]) |(entry_hi[5'd24][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd24} :
									((~(|page_mask[5'd25])) & (entry_hi[5'd25][26:8] == v_pc[31:13]) & ((G[5'd25]) |(entry_hi[5'd25][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd25} :
									((~(|page_mask[5'd26])) & (entry_hi[5'd26][26:8] == v_pc[31:13]) & ((G[5'd26]) |(entry_hi[5'd26][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd26} :
									((~(|page_mask[5'd27])) & (entry_hi[5'd27][26:8] == v_pc[31:13]) & ((G[5'd27]) |(entry_hi[5'd27][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd27} :
									((~(|page_mask[5'd28])) & (entry_hi[5'd28][26:8] == v_pc[31:13]) & ((G[5'd28]) |(entry_hi[5'd28][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd28} :
									((~(|page_mask[5'd29])) & (entry_hi[5'd29][26:8] == v_pc[31:13]) & ((G[5'd29]) |(entry_hi[5'd29][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd29} :
									((~(|page_mask[5'd30])) & (entry_hi[5'd30][26:8] == v_pc[31:13]) & ((G[5'd30]) |(entry_hi[5'd30][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd30} :
									((~(|page_mask[5'd31])) & (entry_hi[5'd31][26:8] == v_pc[31:13]) & ((G[5'd31]) |(entry_hi[5'd31][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd31} : {1'b0,5'd0};
 */

reg tlb_fetch_hit_r;
reg tlb_fetch_over_r;
reg[19:0] pfn;
reg[2:0] c;
reg v;
reg d;

reg assign_valid;

always @(posedge clk)
begin
	if(~resetn)
	begin
		tlb_fetch_hit_r <= 1'b0;
		tlb_fetch_over_r <= 1'b0;
		assign_valid <= 1'b0;
	end
	else if(next_fetch)
	begin
		tlb_fetch_hit_r <= 1'b0;
		tlb_fetch_over_r <= 1'b0;
		assign_valid <= 1'b0;
	end
	else if(tlb_fetch_valid & ~assign_valid)
	begin
		assign_valid <= 1'b1;
	end
	else if(assign_valid)
	begin
		tlb_fetch_over_r <= 1'b1;
		if(tlb_fetch_hit)
		begin
			tlb_fetch_hit_r <= 1'b1;
			if(v_pc[12])
			begin
				{pfn,c,d,v} <= entry_lo1[tlb_fetch_index][24:0];
			end
			else 
			begin
				{pfn,c,d,v} <= entry_lo0[tlb_fetch_index][24:0];
			end
		end
	end
end

assign tlb_fetch_invalid = tlb_fetch_over & ~v & tlb_fetch_hit_r;
assign tlb_fetch_modified = 1'b0;
assign tlb_fetch_refill = tlb_fetch_over & ~tlb_fetch_hit_r;
assign tlb_pc_paddr = {pfn , v_pc[11:0]}; 
assign tlb_fetch_over = tlb_fetch_over_r;
//###################end

//正常查询过程（数据地址转换）
wire tlb_mem_valid;
wire inst_store;
wire [31:0] data_vaddr;
assign {data_vaddr , tlb_mem_valid , inst_store} = mem_tlb_bus;

wire tlb_mem_over;
wire tlb_mem_refill;
wire tlb_mem_invalid;
wire tlb_mem_modified;
wire [31:0] tlb_data_paddr;
assign tlb_mem_bus = {tlb_mem_over , tlb_mem_refill , tlb_mem_invalid , tlb_mem_modified,tlb_data_paddr};


//查找过程
reg tlb_mem_hit;
reg [4:0] tlb_mem_index;

always @(posedge clk)
begin
	if((~resetn) | (~tlb_mem_valid))
	begin
		tlb_mem_hit <= 1'b0;
		tlb_mem_index <= 5'd0;
	end
	else if((~(|page_mask[5'd0])) & (entry_hi[5'd0][26:8] == data_vaddr[31:13]) & ((G[5'd0]) |(entry_hi[5'd0][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd0;
	end
	else if((~(|page_mask[5'd1])) & (entry_hi[5'd1][26:8] == data_vaddr[31:13]) & ((G[5'd1]) |(entry_hi[5'd1][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd1;
	end
	else if((~(|page_mask[5'd2])) & (entry_hi[5'd2][26:8] == data_vaddr[31:13]) & ((G[5'd2]) |(entry_hi[5'd2][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd2;
	end
	else if((~(|page_mask[5'd3])) & (entry_hi[5'd3][26:8] == data_vaddr[31:13]) & ((G[5'd3]) |(entry_hi[5'd3][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd3;
	end
	else if((~(|page_mask[5'd4])) & (entry_hi[5'd4][26:8] == data_vaddr[31:13]) & ((G[5'd4]) |(entry_hi[5'd4][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd4;
	end
	else if((~(|page_mask[5'd5])) & (entry_hi[5'd5][26:8] == data_vaddr[31:13]) & ((G[5'd5]) |(entry_hi[5'd5][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd5;
	end
	else if((~(|page_mask[5'd6])) & (entry_hi[5'd6][26:8] == data_vaddr[31:13]) & ((G[5'd6]) |(entry_hi[5'd6][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd6;
	end
	else if((~(|page_mask[5'd7])) & (entry_hi[5'd7][26:8] == data_vaddr[31:13]) & ((G[5'd7]) |(entry_hi[5'd7][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd7;
	end
	else if((~(|page_mask[5'd8])) & (entry_hi[5'd8][26:8] == data_vaddr[31:13]) & ((G[5'd8]) |(entry_hi[5'd8][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd8;
	end
	else if((~(|page_mask[5'd9])) & (entry_hi[5'd9][26:8] == data_vaddr[31:13]) & ((G[5'd9]) |(entry_hi[5'd9][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd9;
	end
	else if((~(|page_mask[5'd10])) & (entry_hi[5'd10][26:8] == data_vaddr[31:13]) & ((G[5'd10]) |(entry_hi[5'd10][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd10;
	end
	else if((~(|page_mask[5'd11])) & (entry_hi[5'd11][26:8] == data_vaddr[31:13]) & ((G[5'd11]) |(entry_hi[5'd11][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd11;
	end
	else if((~(|page_mask[5'd12])) & (entry_hi[5'd12][26:8] == data_vaddr[31:13]) & ((G[5'd12]) |(entry_hi[5'd12][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd12;
	end
	else if((~(|page_mask[5'd13])) & (entry_hi[5'd13][26:8] == data_vaddr[31:13]) & ((G[5'd13]) |(entry_hi[5'd13][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd0;
	end
	else if((~(|page_mask[5'd14])) & (entry_hi[5'd14][26:8] == data_vaddr[31:13]) & ((G[5'd14]) |(entry_hi[5'd14][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd14;
	end
	else if((~(|page_mask[5'd15])) & (entry_hi[5'd15][26:8] == data_vaddr[31:13]) & ((G[5'd15]) |(entry_hi[5'd15][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd15;
	end
	else if((~(|page_mask[5'd16])) & (entry_hi[5'd16][26:8] == data_vaddr[31:13]) & ((G[5'd16]) |(entry_hi[5'd16][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd16;
	end
	else if((~(|page_mask[5'd17])) & (entry_hi[5'd17][26:8] == data_vaddr[31:13]) & ((G[5'd17]) |(entry_hi[5'd17][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd17;
	end
	else if((~(|page_mask[5'd18])) & (entry_hi[5'd18][26:8] == data_vaddr[31:13]) & ((G[5'd18]) |(entry_hi[5'd18][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd18;
	end
	else if((~(|page_mask[5'd19])) & (entry_hi[5'd19][26:8] == data_vaddr[31:13]) & ((G[5'd19]) |(entry_hi[5'd19][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd19;
	end
	else if((~(|page_mask[5'd20])) & (entry_hi[5'd20][26:8] == data_vaddr[31:13]) & ((G[5'd20]) |(entry_hi[5'd20][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd20;
	end
	else if((~(|page_mask[5'd21])) & (entry_hi[5'd21][26:8] == data_vaddr[31:13]) & ((G[5'd21]) |(entry_hi[5'd21][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd21;
	end
	else if((~(|page_mask[5'd22])) & (entry_hi[5'd22][26:8] == data_vaddr[31:13]) & ((G[5'd22]) |(entry_hi[5'd22][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd22;
	end
	else if((~(|page_mask[5'd23])) & (entry_hi[5'd23][26:8] == data_vaddr[31:13]) & ((G[5'd23]) |(entry_hi[5'd23][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd23;
	end
	else if((~(|page_mask[5'd24])) & (entry_hi[5'd24][26:8] == data_vaddr[31:13]) & ((G[5'd24]) |(entry_hi[5'd24][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd24;
	end
	else if((~(|page_mask[5'd25])) & (entry_hi[5'd25][26:8] == data_vaddr[31:13]) & ((G[5'd25]) |(entry_hi[5'd25][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd25;
	end	
	else if((~(|page_mask[5'd26])) & (entry_hi[5'd26][26:8] == data_vaddr[31:13]) & ((G[5'd26]) |(entry_hi[5'd26][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd26;
	end
	else if((~(|page_mask[5'd27])) & (entry_hi[5'd27][26:8] == data_vaddr[31:13]) & ((G[5'd27]) |(entry_hi[5'd27][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd27;
	end
	else if((~(|page_mask[5'd28])) & (entry_hi[5'd28][26:8] == data_vaddr[31:13]) & ((G[5'd28]) |(entry_hi[5'd28][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd28;
	end
	else if((~(|page_mask[5'd29])) & (entry_hi[5'd29][26:8] == data_vaddr[31:13]) & ((G[5'd29]) |(entry_hi[5'd29][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd29;
	end
	else if((~(|page_mask[5'd30])) & (entry_hi[5'd30][26:8] == data_vaddr[31:13]) & ((G[5'd30]) |(entry_hi[5'd30][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd30;
	end
	else if((~(|page_mask[5'd31])) & (entry_hi[5'd31][26:8] == data_vaddr[31:13]) & ((G[5'd31]) |(entry_hi[5'd31][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_mem_hit <= 1'b1;
		tlb_mem_index <= 5'd31;
	end
	else 
	begin
		tlb_mem_hit <= 1'b0;
	end
end

/* assign {tlb_mem_hit , tlb_mem_index} = ((~(|page_mask[5'd0])) & (entry_hi[5'd0][26:8] == data_vaddr[31:13]) & ((G[5'd0]) |(entry_hi[5'd0][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd0} :
									((~(|page_mask[5'd1])) & (entry_hi[5'd1][26:8] == data_vaddr[31:13]) & ((G[5'd1]) |(entry_hi[5'd1][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd1} :
									((~(|page_mask[5'd2])) & (entry_hi[5'd2][26:8] == data_vaddr[31:13]) & ((G[5'd2]) |(entry_hi[5'd2][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd2} :
									((~(|page_mask[5'd3])) & (entry_hi[5'd3][26:8] == data_vaddr[31:13]) & ((G[5'd3]) |(entry_hi[5'd3][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd3} :
									((~(|page_mask[5'd4])) & (entry_hi[5'd4][26:8] == data_vaddr[31:13]) & ((G[5'd4]) |(entry_hi[5'd4][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd4} :
									((~(|page_mask[5'd5])) & (entry_hi[5'd5][26:8] == data_vaddr[31:13]) & ((G[5'd5]) |(entry_hi[5'd5][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd5} :
									((~(|page_mask[5'd6])) & (entry_hi[5'd6][26:8] == data_vaddr[31:13]) & ((G[5'd6]) |(entry_hi[5'd6][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd6} :
									((~(|page_mask[5'd7])) & (entry_hi[5'd7][26:8] == data_vaddr[31:13]) & ((G[5'd7]) |(entry_hi[5'd7][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd7} :
									((~(|page_mask[5'd8])) & (entry_hi[5'd8][26:8] == data_vaddr[31:13]) & ((G[5'd8]) |(entry_hi[5'd8][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd8} :
									((~(|page_mask[5'd9])) & (entry_hi[5'd9][26:8] == data_vaddr[31:13]) & ((G[5'd9]) |(entry_hi[5'd9][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd9} :
									((~(|page_mask[5'd10])) & (entry_hi[5'd10][26:8] == data_vaddr[31:13]) & ((G[5'd10]) |(entry_hi[5'd10][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd10} :
									((~(|page_mask[5'd11])) & (entry_hi[5'd11][26:8] == data_vaddr[31:13]) & ((G[5'd11]) |(entry_hi[5'd11][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd11} :
									((~(|page_mask[5'd12])) & (entry_hi[5'd12][26:8] == data_vaddr[31:13]) & ((G[5'd12]) |(entry_hi[5'd12][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd12} :
									((~(|page_mask[5'd13])) & (entry_hi[5'd13][26:8] == data_vaddr[31:13]) & ((G[5'd13]) |(entry_hi[5'd13][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd13} :
									((~(|page_mask[5'd14])) & (entry_hi[5'd14][26:8] == data_vaddr[31:13]) & ((G[5'd14]) |(entry_hi[5'd14][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd14} :
									((~(|page_mask[5'd15])) & (entry_hi[5'd15][26:8] == data_vaddr[31:13]) & ((G[5'd15]) |(entry_hi[5'd15][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd15} :
									((~(|page_mask[5'd16])) & (entry_hi[5'd16][26:8] == data_vaddr[31:13]) & ((G[5'd16]) |(entry_hi[5'd16][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd16} :
									((~(|page_mask[5'd17])) & (entry_hi[5'd17][26:8] == data_vaddr[31:13]) & ((G[5'd17]) |(entry_hi[5'd17][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd17} :
									((~(|page_mask[5'd18])) & (entry_hi[5'd18][26:8] == data_vaddr[31:13]) & ((G[5'd18]) |(entry_hi[5'd18][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd18} :
									((~(|page_mask[5'd19])) & (entry_hi[5'd19][26:8] == data_vaddr[31:13]) & ((G[5'd19]) |(entry_hi[5'd19][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd19} :
									((~(|page_mask[5'd20])) & (entry_hi[5'd20][26:8] == data_vaddr[31:13]) & ((G[5'd20]) |(entry_hi[5'd20][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd20} :
									((~(|page_mask[5'd21])) & (entry_hi[5'd21][26:8] == data_vaddr[31:13]) & ((G[5'd21]) |(entry_hi[5'd21][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd21} :
									((~(|page_mask[5'd22])) & (entry_hi[5'd22][26:8] == data_vaddr[31:13]) & ((G[5'd22]) |(entry_hi[5'd22][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd22} :
									((~(|page_mask[5'd23])) & (entry_hi[5'd23][26:8] == data_vaddr[31:13]) & ((G[5'd23]) |(entry_hi[5'd23][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd23} :
									((~(|page_mask[5'd24])) & (entry_hi[5'd24][26:8] == data_vaddr[31:13]) & ((G[5'd24]) |(entry_hi[5'd24][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd24} :
									((~(|page_mask[5'd25])) & (entry_hi[5'd25][26:8] == data_vaddr[31:13]) & ((G[5'd25]) |(entry_hi[5'd25][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd25} :
									((~(|page_mask[5'd26])) & (entry_hi[5'd26][26:8] == data_vaddr[31:13]) & ((G[5'd26]) |(entry_hi[5'd26][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd26} :
									((~(|page_mask[5'd27])) & (entry_hi[5'd27][26:8] == data_vaddr[31:13]) & ((G[5'd27]) |(entry_hi[5'd27][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd27} :
									((~(|page_mask[5'd28])) & (entry_hi[5'd28][26:8] == data_vaddr[31:13]) & ((G[5'd28]) |(entry_hi[5'd28][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd28} :
									((~(|page_mask[5'd29])) & (entry_hi[5'd29][26:8] == data_vaddr[31:13]) & ((G[5'd29]) |(entry_hi[5'd29][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd29} :
									((~(|page_mask[5'd30])) & (entry_hi[5'd30][26:8] == data_vaddr[31:13]) & ((G[5'd30]) |(entry_hi[5'd30][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd30} :
									((~(|page_mask[5'd31])) & (entry_hi[5'd31][26:8] == data_vaddr[31:13]) & ((G[5'd31]) |(entry_hi[5'd31][7:0]==tlb_entryhi[7:0]))) ?  {1'b1,5'd31} : {1'b0,5'd0}; */


reg tlb_mem_hit_r;
reg tlb_mem_over_r;
reg[19:0] pfn_mem;
reg v_mem;
reg [2:0] c_mem;
reg d_mem;
reg assign_mem_valid;

always @(posedge clk)
begin
	if(~resetn)
	begin
		tlb_mem_hit_r <= 1'b0;
		tlb_mem_over_r <= 1'b0;
		assign_mem_valid <= 1'b0;
	end
	else if(MEM_allow_in & EXE_over)
	begin
		tlb_mem_hit_r <= 1'b0;
		tlb_mem_over_r <= 1'b0;
		assign_mem_valid <= 1'b0;
	end
	else if(tlb_mem_valid & ~assign_mem_valid)
	begin
		assign_mem_valid <= 1'b1;
	end
	else if(assign_mem_valid)
	begin
		tlb_mem_over_r <= 1'b1;
		if(tlb_mem_hit)
		begin
			tlb_mem_hit_r <= 1'b1;
			if(data_vaddr[12])
			begin
				{pfn_mem,c_mem,d_mem,v_mem} <= entry_lo1[tlb_mem_index][24:0];
			end
			else 
			begin
				{pfn_mem,c_mem,d_mem,v_mem} <= entry_lo0[tlb_mem_index][24:0];
			end
		end
	end
end

assign tlb_mem_invalid = tlb_mem_over & ~v_mem & tlb_mem_hit_r;
assign tlb_mem_modified = tlb_mem_over & inst_store & ~d_mem & v_mem & tlb_mem_hit_r;
assign tlb_mem_refill = tlb_mem_over & ~tlb_mem_hit_r;
assign tlb_data_paddr = {pfn_mem , data_vaddr[11:0]}; 
assign tlb_mem_over = tlb_mem_over_r;
//###################end

//与TLB相关的指令执行过程
wire tlb_cp0_valid;
wire [31:0] tlb_index,tlb_entryhi,tlb_pagemask,tlb_entrylo0,tlb_entrylo1;
wire inst_TLBR,inst_TLBP,inst_TLBWI,inst_TLBWR;
assign {tlb_cp0_valid,
			 tlb_index,
			 tlb_entryhi,
			 tlb_pagemask,
			 tlb_entrylo0,
			 tlb_entrylo1,
			 inst_TLBR,
			 inst_TLBP,
			 inst_TLBWI,
			 inst_TLBWR} = cp0_tlb_bus;
			 
//wire [31:0] tlb_w_index;
wire tlb_index_wen;//即TLBP指令需要通过TLB的判断去修改CP0寄存器 index 的值
//wire tlb_index_hit;//TLBP指令查表项命中
wire tlb_inst_over;//tlb 相关指令执行结束信号


wire cp0_wen;//其它与cp0寄存器有关的信号的写入
wire [4:0] write_index;//选择需要写回的TLB 项
wire [31:0] tlb_w_entryhi;
wire [31:0] tlb_w_entrylo0;
wire [31:0] tlb_w_entrylo1;
wire [31:0] tlb_w_pagemask;

//实现TLBR指令的主体信号
assign write_index = tlb_index[4:0];
assign cp0_wen = (~(|tlb_index[31:5]))&&(inst_TLBR);
assign tlb_w_entryhi = {entry_hi[write_index][26:8],5'd0,entry_hi[write_index][7:0]};
assign tlb_w_entrylo0 = {6'd0,entry_lo0[write_index],G[write_index]};
assign tlb_w_entrylo1 = {6'd0,entry_lo1[write_index],G[write_index]};
assign tlb_w_pagemask = {7'd0,page_mask[write_index],13'd0};

//这里是实现TLBP的主体信号
//assign tlb_index_hit =  ;
assign tlb_index_wen = inst_TLBP;
//assign tlb_w_index = tlb_index_hit ? {27'd0,index_r} : {1'b1 , 31'd0};


assign tlb_cp0_bus = {tlb_w_index_r , tlb_index_wen , tlb_inst_over, 
									cp0_wen , tlb_w_entryhi,tlb_w_entrylo0,tlb_w_entrylo1,tlb_w_pagemask};

wire tlb_wen ;
assign tlb_wen = inst_TLBWI | inst_TLBWR;//这里基本实现这两条指令	



wire write_tlb;//TLBWI 和TLBWR 两条指令完成
assign write_tlb = (tlb_hi_over & tlb_mask_over & tlb_lo0_over & tlb_lo1_over & tlb_G_over ) ;

//assign tlb_inst_over = tlb_cp0_valid &( (write_tlb & tlb_wen) | (inst_TLBP & query_finished ) | inst_TLBR); 

wire query_finished;
//查询表项，是否命中 对比entryhi 与 tlb 每一项


reg[31:0] tlb_w_index_r;

always @(posedge clk)
begin
	if(~resetn)
	begin
		tlb_w_index_r <= 32'd0;
	end
	else if((~(|page_mask[5'd0])) & (entry_hi[5'd0][26:8] == tlb_entryhi[31:13]) & ((G[5'd0]) |(entry_hi[5'd0][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd0;
	end
	else if((~(|page_mask[5'd1])) & (entry_hi[5'd1][26:8] == tlb_entryhi[31:13]) & ((G[5'd1]) |(entry_hi[5'd1][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd1;
	end
	else if((~(|page_mask[5'd2])) & (entry_hi[5'd2][26:8] == tlb_entryhi[31:13]) & ((G[5'd2]) |(entry_hi[5'd2][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd2;
	end
	else if((~(|page_mask[5'd3])) & (entry_hi[5'd3][26:8] == tlb_entryhi[31:13]) & ((G[5'd3]) |(entry_hi[5'd3][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd3;
	end
	else if((~(|page_mask[5'd4])) & (entry_hi[5'd4][26:8] == tlb_entryhi[31:13]) & ((G[5'd4]) |(entry_hi[5'd4][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd4;
	end
	else if((~(|page_mask[5'd5])) & (entry_hi[5'd5][26:8] == tlb_entryhi[31:13]) & ((G[5'd5]) |(entry_hi[5'd5][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd5;
	end
	else if((~(|page_mask[5'd6])) & (entry_hi[5'd6][26:8] == tlb_entryhi[31:13]) & ((G[5'd6]) |(entry_hi[5'd6][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd6;
	end
	else if((~(|page_mask[5'd7])) & (entry_hi[5'd7][26:8] == tlb_entryhi[31:13]) & ((G[5'd7]) |(entry_hi[5'd7][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd7;
	end
	else if((~(|page_mask[5'd8])) & (entry_hi[5'd8][26:8] == tlb_entryhi[31:13]) & ((G[5'd8]) |(entry_hi[5'd8][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd8;
	end
	else if((~(|page_mask[5'd9])) & (entry_hi[5'd9][26:8] == tlb_entryhi[31:13]) & ((G[5'd9]) |(entry_hi[5'd9][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd9;
	end
	else if((~(|page_mask[5'd10])) & (entry_hi[5'd10][26:8] == tlb_entryhi[31:13]) & ((G[5'd10]) |(entry_hi[5'd10][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd10;
	end
	else if((~(|page_mask[5'd11])) & (entry_hi[5'd11][26:8] == tlb_entryhi[31:13]) & ((G[5'd11]) |(entry_hi[5'd11][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd11;
	end
	else if((~(|page_mask[5'd12])) & (entry_hi[5'd12][26:8] == tlb_entryhi[31:13]) & ((G[5'd12]) |(entry_hi[5'd12][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd12;
	end
	else if((~(|page_mask[5'd13])) & (entry_hi[5'd13][26:8] == tlb_entryhi[31:13]) & ((G[5'd13]) |(entry_hi[5'd13][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd0;
	end
	else if((~(|page_mask[5'd14])) & (entry_hi[5'd14][26:8] == tlb_entryhi[31:13]) & ((G[5'd14]) |(entry_hi[5'd14][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd14;
	end
	else if((~(|page_mask[5'd15])) & (entry_hi[5'd15][26:8] == tlb_entryhi[31:13]) & ((G[5'd15]) |(entry_hi[5'd15][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd15;
	end
	else if((~(|page_mask[5'd16])) & (entry_hi[5'd16][26:8] == tlb_entryhi[31:13]) & ((G[5'd16]) |(entry_hi[5'd16][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd16;
	end
	else if((~(|page_mask[5'd17])) & (entry_hi[5'd17][26:8] == tlb_entryhi[31:13]) & ((G[5'd17]) |(entry_hi[5'd17][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd17;
	end
	else if((~(|page_mask[5'd18])) & (entry_hi[5'd18][26:8] == tlb_entryhi[31:13]) & ((G[5'd18]) |(entry_hi[5'd18][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd18;
	end
	else if((~(|page_mask[5'd19])) & (entry_hi[5'd19][26:8] == tlb_entryhi[31:13]) & ((G[5'd19]) |(entry_hi[5'd19][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd19;
	end
	else if((~(|page_mask[5'd20])) & (entry_hi[5'd20][26:8] == tlb_entryhi[31:13]) & ((G[5'd20]) |(entry_hi[5'd20][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd20;
	end
	else if((~(|page_mask[5'd21])) & (entry_hi[5'd21][26:8] == tlb_entryhi[31:13]) & ((G[5'd21]) |(entry_hi[5'd21][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd21;
	end
	else if((~(|page_mask[5'd22])) & (entry_hi[5'd22][26:8] == tlb_entryhi[31:13]) & ((G[5'd22]) |(entry_hi[5'd22][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd22;
	end
	else if((~(|page_mask[5'd23])) & (entry_hi[5'd23][26:8] == tlb_entryhi[31:13]) & ((G[5'd23]) |(entry_hi[5'd23][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd23;
	end
	else if((~(|page_mask[5'd24])) & (entry_hi[5'd24][26:8] == tlb_entryhi[31:13]) & ((G[5'd24]) |(entry_hi[5'd24][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd24;
	end
	else if((~(|page_mask[5'd25])) & (entry_hi[5'd25][26:8] == tlb_entryhi[31:13]) & ((G[5'd25]) |(entry_hi[5'd25][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd25;
	end	
	else if((~(|page_mask[5'd26])) & (entry_hi[5'd26][26:8] == tlb_entryhi[31:13]) & ((G[5'd26]) |(entry_hi[5'd26][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd26;
	end
	else if((~(|page_mask[5'd27])) & (entry_hi[5'd27][26:8] == tlb_entryhi[31:13]) & ((G[5'd27]) |(entry_hi[5'd27][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd27;
	end
	else if((~(|page_mask[5'd28])) & (entry_hi[5'd28][26:8] == tlb_entryhi[31:13]) & ((G[5'd28]) |(entry_hi[5'd28][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd28;
	end
	else if((~(|page_mask[5'd29])) & (entry_hi[5'd29][26:8] == tlb_entryhi[31:13]) & ((G[5'd29]) |(entry_hi[5'd29][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd29;
	end
	else if((~(|page_mask[5'd30])) & (entry_hi[5'd30][26:8] == tlb_entryhi[31:13]) & ((G[5'd30]) |(entry_hi[5'd30][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd30;
	end
	else if((~(|page_mask[5'd31])) & (entry_hi[5'd31][26:8] == tlb_entryhi[31:13]) & ((G[5'd31]) |(entry_hi[5'd31][7:0]==tlb_entryhi[7:0])))
	begin
		tlb_w_index_r <= 32'd31;
	end
	else 
	begin
		tlb_w_index_r <= {1'b1,tlb_index[30:0]};
	end
end

/* assign {tlb_w_index,query_finished} = ((~(|page_mask[5'd0]))&(entry_hi[5'd0][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd0][7:0] == tlb_entryhi[7:0])|(G[32'd0]))) ? {27'd0,5'd0,1'b1} :
								   ((~(|page_mask[5'd1]))&(entry_hi[5'd1][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd1][7:0] == tlb_entryhi[7:0])|(G[32'd1]))) ? {27'd0,5'd1,1'b1} :
								   ((~(|page_mask[5'd2]))&(entry_hi[5'd2][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd2][7:0] == tlb_entryhi[7:0])|(G[32'd2]))) ? {27'd0,5'd2,1'b1} :
								   ((~(|page_mask[5'd3]))&(entry_hi[5'd3][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd3][7:0] == tlb_entryhi[7:0])|(G[32'd3]))) ? {27'd0,5'd3,1'b1} :
								   ((~(|page_mask[5'd4]))&(entry_hi[5'd4][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd4][7:0] == tlb_entryhi[7:0])|(G[32'd4]))) ? {27'd0,5'd4,1'b1} :
								   ((~(|page_mask[5'd5]))&(entry_hi[5'd5][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd5][7:0] == tlb_entryhi[7:0])|(G[32'd5]))) ? {27'd0,5'd5,1'b1} :
								   ((~(|page_mask[5'd6]))&(entry_hi[5'd6][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd6][7:0] == tlb_entryhi[7:0])|(G[32'd6]))) ? {27'd0,5'd6,1'b1} :
								   ((~(|page_mask[5'd7]))&(entry_hi[5'd7][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd7][7:0] == tlb_entryhi[7:0])|(G[32'd7]))) ? {27'd0,5'd7,1'b1} :
								   ((~(|page_mask[5'd8]))&(entry_hi[5'd8][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd8][7:0] == tlb_entryhi[7:0])|(G[32'd8]))) ? {27'd0,5'd8,1'b1} :
								   ((~(|page_mask[5'd9]))&(entry_hi[5'd9][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd9][7:0] == tlb_entryhi[7:0])|(G[32'd9]))) ? {27'd0,5'd9,1'b1} :
								   ((~(|page_mask[5'd10]))&(entry_hi[5'd10][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd10][7:0] == tlb_entryhi[7:0])|(G[32'd10]))) ? {27'd0,5'd10,1'b1} :
								   ((~(|page_mask[5'd11]))&(entry_hi[5'd11][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd11][7:0] == tlb_entryhi[7:0])|(G[32'd11]))) ? {27'd0,5'd11,1'b1} :
								   ((~(|page_mask[5'd12]))&(entry_hi[5'd12][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd12][7:0] == tlb_entryhi[7:0])|(G[32'd12]))) ? {27'd0,5'd12,1'b1} :
								   ((~(|page_mask[5'd13]))&(entry_hi[5'd13][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd13][7:0] == tlb_entryhi[7:0])|(G[32'd13]))) ? {27'd0,5'd13,1'b1} :
								   ((~(|page_mask[5'd14]))&(entry_hi[5'd14][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd14][7:0] == tlb_entryhi[7:0])|(G[32'd14]))) ? {27'd0,5'd14,1'b1} :
								   ((~(|page_mask[5'd15]))&(entry_hi[5'd15][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd15][7:0] == tlb_entryhi[7:0])|(G[32'd15]))) ? {27'd0,5'd15,1'b1} :
								   ((~(|page_mask[5'd16]))&(entry_hi[5'd16][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd16][7:0] == tlb_entryhi[7:0])|(G[32'd16]))) ? {27'd0,5'd16,1'b1} :
								   ((~(|page_mask[5'd17]))&(entry_hi[5'd17][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd17][7:0] == tlb_entryhi[7:0])|(G[32'd17]))) ? {27'd0,5'd17,1'b1} :
								   ((~(|page_mask[5'd18]))&(entry_hi[5'd18][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd18][7:0] == tlb_entryhi[7:0])|(G[32'd18]))) ? {27'd0,5'd18,1'b1} :
								   ((~(|page_mask[5'd19]))&(entry_hi[5'd19][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd19][7:0] == tlb_entryhi[7:0])|(G[32'd19]))) ? {27'd0,5'd19,1'b1} :
								   ((~(|page_mask[5'd20]))&(entry_hi[5'd20][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd20][7:0] == tlb_entryhi[7:0])|(G[32'd20]))) ? {27'd0,5'd20,1'b1} :
								   ((~(|page_mask[5'd21]))&(entry_hi[5'd21][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd21][7:0] == tlb_entryhi[7:0])|(G[32'd21]))) ? {27'd0,5'd21,1'b1} :
								   ((~(|page_mask[5'd22]))&(entry_hi[5'd22][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd22][7:0] == tlb_entryhi[7:0])|(G[32'd22]))) ? {27'd0,5'd22,1'b1} :
								   ((~(|page_mask[5'd23]))&(entry_hi[5'd23][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd23][7:0] == tlb_entryhi[7:0])|(G[32'd23]))) ? {27'd0,5'd23,1'b1} :
								   ((~(|page_mask[5'd24]))&(entry_hi[5'd24][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd24][7:0] == tlb_entryhi[7:0])|(G[32'd24]))) ? {27'd0,5'd24,1'b1} :
								   ((~(|page_mask[5'd25]))&(entry_hi[5'd25][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd25][7:0] == tlb_entryhi[7:0])|(G[32'd25]))) ? {27'd0,5'd25,1'b1} :
								   ((~(|page_mask[5'd26]))&(entry_hi[5'd26][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd26][7:0] == tlb_entryhi[7:0])|(G[32'd26]))) ? {27'd0,5'd26,1'b1} :
								   ((~(|page_mask[5'd27]))&(entry_hi[5'd27][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd27][7:0] == tlb_entryhi[7:0])|(G[32'd27]))) ? {27'd0,5'd27,1'b1} :
								   ((~(|page_mask[5'd28]))&(entry_hi[5'd28][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd28][7:0] == tlb_entryhi[7:0])|(G[32'd28]))) ? {27'd0,5'd28,1'b1} :
								   ((~(|page_mask[5'd29]))&(entry_hi[5'd29][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd29][7:0] == tlb_entryhi[7:0])|(G[32'd29]))) ? {27'd0,5'd29,1'b1} :
								   ((~(|page_mask[5'd30]))&(entry_hi[5'd30][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd30][7:0] == tlb_entryhi[7:0])|(G[32'd30]))) ? {27'd0,5'd30,1'b1} :
								   ((~(|page_mask[5'd31]))&(entry_hi[5'd31][26:8]==tlb_entryhi[31:13])&((entry_hi[5'd31][7:0] == tlb_entryhi[7:0])|(G[32'd31]))) ? {27'd0,5'd31,1'b1} :{1'b1 , tlb_index[30:0],1'b1}; */

reg query_finished_r;
always @(posedge clk)
begin
	if(~resetn || tlb_inst_over)
	begin
		query_finished_r <= 1'b0;
	end
	else if(tlb_cp0_valid)
	begin
		query_finished_r <=1'b1;
	end
end

reg tlb_inst_over_r;
assign tlb_inst_over = tlb_inst_over_r;
always @(posedge clk)
begin
	if(~resetn || tlb_inst_over)
	begin
		tlb_inst_over_r <=1'b0;
	end
	else if (tlb_cp0_valid)
	begin
		if((write_tlb & tlb_wen) | (inst_TLBP & query_finished_r ) | inst_TLBR)
		begin
			tlb_inst_over_r <=1'b1;
		end
	end
end


//写tlb表项 的 entryhi
integer hi_count;
reg tlb_hi_over;
always @(posedge clk)
begin
	if(~resetn )
	begin
		tlb_hi_over <=1'b0;
		for (hi_count = 0 ; hi_count <32 ; hi_count = hi_count+1)
		begin
			entry_hi[hi_count]<= 27'd0;
		end
	end
	else if(tlb_inst_over)
	begin
		tlb_hi_over <= 1'b0;
	end
	else if(tlb_wen && tlb_cp0_valid)
	begin
		entry_hi[tlb_index[4:0]][26:0] <= {tlb_entryhi[31:13] , tlb_entryhi[7:0]};
		tlb_hi_over <= 1'b1;
	end
end

//写tlb表项 的pagemask
integer mask_count;
reg tlb_mask_over;
always @(posedge clk)
begin
	if(~resetn)
	begin
		tlb_mask_over <=1'b0;
		for(mask_count = 0 ; mask_count < 32 ; mask_count = mask_count +1)
		begin
			page_mask[mask_count][11:0] <= 12'd0;
		end
	end
	else if(tlb_inst_over)
	begin
		tlb_mask_over <= 1'b0;
	end
	else if(tlb_wen && tlb_cp0_valid)
	begin
		page_mask[tlb_index[4:0]][11:0] <= tlb_pagemask[24:13];
		tlb_mask_over <= 1'b1;
	end
end

//写tlb表项 的entrylo0
integer lo0_count;
reg tlb_lo0_over;
always @(posedge clk)
begin
	if(~resetn)
	begin
		tlb_lo0_over <=1'b0;
		for(lo0_count = 0 ; lo0_count < 32 ; lo0_count = lo0_count+1)
		begin
			entry_lo0[lo0_count] <= 25'd0;
		end
	end
	else if(tlb_inst_over)
	begin
		tlb_lo0_over <= 1'b0;
	end
	else if(tlb_wen && tlb_cp0_valid)
	begin
		entry_lo0[tlb_index[4:0]][24:0] <= {((~(tlb_pagemask[22:13])) & tlb_entrylo0 [25:6]) , tlb_entrylo0[5:1]}  ;
		tlb_lo0_over <=1'b1;
	end
end

//写tlb表项 的entrylo1
integer lo1_count;
reg tlb_lo1_over;
always @(posedge clk)
begin
	if(~resetn )
	begin
		tlb_lo1_over <=1'b0;
		for(lo1_count = 0 ; lo1_count < 32 ; lo1_count = lo1_count +1)
		begin
			entry_lo1[lo1_count] <= 25'd0;
		end
	end
	else if(tlb_inst_over)
	begin
		tlb_lo1_over <= 1'b0;
	end
	else if(tlb_wen && tlb_cp0_valid)
	begin
		entry_lo1[tlb_index[4:0]][24:0] <= {((~(tlb_pagemask[22:13])) & tlb_entrylo1 [25:6]),tlb_entrylo1[5:1]}  ;
		tlb_lo1_over <=1'b1;
	end
end

//写tlb表项 的 G位
integer G_count;
reg tlb_G_over;
always @(posedge clk)
begin
	if(~resetn)
	begin
		tlb_G_over <=1'b0;
		for(G_count = 0 ; G_count < 32 ; G_count = G_count +1)
		begin
			G[G_count] <= 1'b0;
		end
	end
	else if(tlb_inst_over)
	begin
		tlb_G_over <= 1'b0;
	end
	else if(tlb_wen && tlb_cp0_valid)
	begin
		G[tlb_index[4:0]] <= tlb_entrylo0[0] & tlb_entrylo1[0];
		tlb_G_over <=1'b1;
	end
end
//###################end

endmodule