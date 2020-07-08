`timescale 1ns / 1ps

`define STARTADDR 32'Hbfc00000  // ������ʼ��ַΪ34H
module fetch(                    // ȡָ��
    input             clk,       // ʱ��
    input             resetn,    // ��λ�źţ��͵�ƽ��Ч
    input             IF_valid,  // ȡָ����Ч�ź�
    //input             WB_wdest,
    input             next_fetch,// ȡ��һ��ָ���������PCֵ
	input  [35:0]  tlb_fetch_bus,
	input              ID_allow_in,
    //input      [31:0] inst,      // inst_romȡ����ָ��
    input      [32:0] jbr_bus,   // ��ת����
    //output wire  [31:0] inst_addr, // ����inst_rom��ȡָ��ַ
    output wire        IF_over,   // IFģ��ִ�����
    output  wire   [68:0] IF_ID_bus, // IF->ID����
	output  [32:0]     fetch_tlb_bus,
    
    //5����ˮ�����ӿ�
    input  wire    [32:0] exc_bus,   // Exception pc����
    input wire          is_ds, //��ת�ź�
    input wire  [31:0]  ID_pc, 	
	
	//7.3
	input cancel ,
	
	//axiָ������
	output reg inst_en ,
	output reg[31:0]  axi_inst_addr,
	//output wire Icache_arlen,
	
	input wire[290:0] axi_buffer_bus,
	
	input wire inst_load_launched,
	//input wire[127:0] insts,
    input wire Icache_wr,
	input wire[255:0] axi_Icache_insts,
	input wire[31:0]  update_inst_addr,
	output reg update_finished,
    //չʾPC��ȡ����ָ��
    output     [31:0] IF_pc,
    output     [31:0] IF_inst
);

//-----{���������PC}begin
    wire [31:0] next_pc;
    wire [31:0] seq_pc;
    reg  [31:0] pc;
    
    //��תpc
    wire        jbr_taken;
    wire [31:0] jbr_target;
    assign {jbr_taken, jbr_target} = jbr_bus;  // ��ת���ߴ��Ƿ���ת��Ŀ���ַ
    
    //Exception PC
    wire        exc_valid;
    wire [31:0] exc_pc;
    assign {exc_valid,exc_pc} = exc_bus;
	wire no_mmu_valid;
    
    //pc+4
    assign seq_pc[31:2]    = pc[31:2] + 1'b1;  // ��һָ���ַ��PC=PC+4
    assign seq_pc[1:0]     = pc[1:0];

    // ��ָ�����Exception,��PCΪExceptio��ڵ�ַ
    //         ��ָ����ת����PCΪ��ת��ַ������Ϊpc+4
    assign next_pc = exc_valid ? exc_pc : 
                     jbr_taken ? jbr_target : seq_pc;

wire core_valid;//�ں�̬��ַ����Ч
assign core_valid = (pc[31:30] == 2'b10);
wire already_mapped;//�Ѿ�ӳ����ĵ�ַ
assign already_mapped = (pc[31:13] == inst_vaddr_hi) ;

wire tlb_fetch_valid;
assign tlb_fetch_valid = (~(core_valid | already_mapped)) & ~tlb_fetch_over & ~addr_exc ;
wire [31:0] v_pc;
assign v_pc = pc;
assign fetch_tlb_bus = {v_pc , tlb_fetch_valid};

wire tlb_fetch_over;
wire[2:0] tlb_fetch_exc;
wire[31:0] tlb_pc_paddr;

assign {tlb_fetch_over,tlb_fetch_exc,tlb_pc_paddr} = tlb_fetch_bus;

reg[19:0] inst_vaddr_hi;
reg[19:0] inst_addr_hi;
always @(posedge clk)
begin
	if(!resetn)
	begin
		inst_vaddr_hi <= 20'hbfc00;
		inst_addr_hi <= 20'h1fc00;
	end
	if(tlb_fetch_over & ~tlb_error)
	begin
		inst_vaddr_hi <= v_pc[31:12];
		inst_addr_hi <= tlb_pc_paddr[31:12];
	end
end

	
always @(posedge clk)    // PC���������
begin
	if (!resetn)
	begin
		pc <= `STARTADDR; // ��λ��ȡ������ʼ��ַ
	end
	else if (next_fetch & (core_valid | cancel))//�������ں�̬��ʱ��ʹ����һ��ַ��
	begin
		pc <= next_pc;    // ����λ��ȡ��ָ��
	end
	else if(next_fetch & already_mapped)//��ʹ���Ѿ�ӳ����ĵ�ַʱ������Ҫ��ӳ��
	begin
		pc <= {inst_addr_hi,next_pc[11:0]};
	end
	else if(tlb_fetch_over & ~tlb_error)
	begin
		pc <= tlb_pc_paddr;
	end
	else if(next_fetch)
	begin
		pc <= next_pc;
	end
end

wire tlb_error;
assign tlb_error = (|tlb_fetch_exc);
	
		//----------------{Ԥȡģ�� begin}-----------------------
	//wire[26:0] aix_pc_base; //axi�����б�����pc_base
	//wire[26:0] Icache_pc_base; //Icache�����б�����pc_base
	//wire[31:0] inst_paddr;
    //assign inst_paddr = no_mmu_valid ? {inst_paddr_hi[19:0] , pc[11:0]} : mmu_pc_paddr;
	wire[2:0] axi_pc_offset;
	assign axi_pc_offset=pc[4:2];
	wire[2:0]  Icache_pc_offset;
	assign Icache_pc_offset = pc[4:2];
	/*
	wire[2:0] next_axi_pc_offset;
	assign seq_pc_offset=next_pc[4:2];
	wire[1:0]  next_Icache_pc_offset;
	assign next_Icache_pc_offset = pc[3:2];
	*/
    wire[7:0] axi_inst_valids;
	wire[255:0] axi_insts;
	wire[26:0] axi_pc_base;
    assign {axi_inst_valids,axi_insts,axi_pc_base} = axi_buffer_bus;
	
	//wire[282:0] Icache_buffer_bus;
	//wire[3:0] Icache_inst_valids;
	wire[255:0] Icache_insts;
	assign Icache_insts = inst_from_cache;
	//wire[26:0] Icache_pc_base;
	//assign {Icache_insts,Icache_pc_base} = Icache_buffer_bus;
	
	//�ٶ���֧�ܲ�����
	wire next_change;
	assign next_change = ((seq_pc[31:5]==axi_pc_base)|(seq_pc[31:5]==Icache_pc_base)) ? 1'b0 : 1'b1;
	
	
	wire next_use_Icache_buffer ;
	assign next_use_Icache_buffer= (seq_pc[31:5]==Icache_pc_base);
	wire next_use_axi_buffer;
	assign next_use_axi_buffer = (seq_pc[31:5] == axi_pc_base);
	
	wire[2:0] seq_pc_offset;
	assign seq_pc_offset=seq_pc[4:2];
	wire quick_end ;
	assign quick_end = ((next_use_Icache_buffer) | ((next_use_axi_buffer)&&axi_inst_valids[seq_pc_offset]))&&(fetch_state==4'd0)&&next_fetch ? 1'b1 : 1'b0;
	wire[31:0] next_inst ;
	assign next_inst = (next_use_Icache_buffer&&(seq_pc_offset==3'b000))  ?  Icache_insts[31:0] :
	                   (next_use_Icache_buffer&&(seq_pc_offset==3'b001))  ?  Icache_insts[63:32] :
					   (next_use_Icache_buffer&&(seq_pc_offset==3'b010))  ?  Icache_insts[95:64] :
					   (next_use_Icache_buffer&&(seq_pc_offset==3'b011))  ?  Icache_insts[127:96] :
					   (next_use_Icache_buffer&&(seq_pc_offset==3'b100))  ?  Icache_insts[159:128] :
					   (next_use_Icache_buffer&&(seq_pc_offset==3'b101))  ?  Icache_insts[191:160] :
					   (next_use_Icache_buffer&&(seq_pc_offset==3'b110))  ?  Icache_insts[223:192] :
					   (next_use_Icache_buffer&&(seq_pc_offset==3'b111))  ?  Icache_insts[255:224] :
					   (next_use_axi_buffer&&axi_inst_valids[seq_pc_offset]&&(seq_pc_offset==3'b000))       ?  axi_insts[31:0] : 
					   (next_use_axi_buffer&&axi_inst_valids[seq_pc_offset]&&(seq_pc_offset==3'b001))       ?  axi_insts[63:32] :
					   (next_use_axi_buffer&&axi_inst_valids[seq_pc_offset]&&(seq_pc_offset==3'b010))       ?  axi_insts[95:64] :
					   (next_use_axi_buffer&&axi_inst_valids[seq_pc_offset]&&(seq_pc_offset==3'b011))       ?  axi_insts[127:96] :
					   (next_use_axi_buffer&&axi_inst_valids[seq_pc_offset]&&(seq_pc_offset==3'b100))       ?  axi_insts[159:128] :
					   (next_use_axi_buffer&&axi_inst_valids[seq_pc_offset]&&(seq_pc_offset==3'b101))       ?  axi_insts[191:160] :
					   (next_use_axi_buffer&&axi_inst_valids[seq_pc_offset]&&(seq_pc_offset==3'b110))       ?  axi_insts[223:192] :
					   (next_use_axi_buffer&&axi_inst_valids[seq_pc_offset]&&(seq_pc_offset==3'b111))       ?  axi_insts[255:224] :  32'd0;
   
   //for debug
   wire[26:0] pc_base;
   assign pc_base = pc[31:5];
	reg[3:0] fetch_state;
	wire Icache_hit;
	//wire Icache_over;				   
	wire change;
	assign change = ((pc[31:5]==axi_pc_base)|(pc[31:5]==Icache_pc_base)) ? 1'b0 : 1'b1;
	//wire use_Icache_buffer ;
	//assign use_Icache_buffer= ((pc[31:5]==Icache_pc_base)&(fetch_state!=4'd0));
	wire use_axi_buffer;
	//assign use_axi_buffer = ((pc[31:5] == axi_pc_base)&(fetch_state!=4'd0));
	assign use_axi_buffer =(pc[31:5] == axi_pc_base);
	wire real_use_axi_buffer;
	//assign use_axi_buffer = ((pc[31:5] == axi_pc_base)&(fetch_state!=4'd0));
	assign real_use_axi_buffer =(pc[31:5] == axi_pc_base)&&axi_inst_valids[axi_pc_offset];
	
	assign use_Icache_buffer=(pc[31:5]==Icache_pc_base);
	wire[31:0] fetch_inst;
	reg[3:0] Istate;
	assign fetch_inst =  					   
					   ((pc[31:5] == axi_pc_base)&&axi_inst_valids[axi_pc_offset]&&(axi_pc_offset==3'b000))       ?  axi_insts[31:0] : 
					   ((pc[31:5] == axi_pc_base)&&axi_inst_valids[axi_pc_offset]&&(axi_pc_offset==3'b001))       ?  axi_insts[63:32] :
					   ((pc[31:5] == axi_pc_base)&&axi_inst_valids[axi_pc_offset]&&(axi_pc_offset==3'b010))       ?  axi_insts[95:64] :
					   ((pc[31:5] == axi_pc_base)&&axi_inst_valids[axi_pc_offset]&&(axi_pc_offset==3'b011))       ?  axi_insts[127:96] :
					   ((pc[31:5] == axi_pc_base)&&axi_inst_valids[axi_pc_offset]&&(axi_pc_offset==3'b100))       ?  axi_insts[159:128] :
					   ((pc[31:5] == axi_pc_base)&&axi_inst_valids[axi_pc_offset]&&(axi_pc_offset==3'b101))       ?  axi_insts[191:160] :
					   ((pc[31:5] == axi_pc_base)&&axi_inst_valids[axi_pc_offset]&&(axi_pc_offset==3'b110))       ?  axi_insts[223:192] :
					   ((pc[31:5] == axi_pc_base)&&axi_inst_valids[axi_pc_offset]&&(axi_pc_offset==3'b111))       ?  axi_insts[255:224] :  
					   ((pc[31:5]==Icache_pc_base)&&(Icache_pc_offset==3'b000))  ?  Icache_insts[31:0] :
	                   ((pc[31:5]==Icache_pc_base)&&(Icache_pc_offset==3'b001)) ?  Icache_insts[63:32] :
					   ((pc[31:5]==Icache_pc_base)&&(Icache_pc_offset==3'b010)) ?  Icache_insts[95:64] :
					   ((pc[31:5]==Icache_pc_base)&&(Icache_pc_offset==3'b011)) ?  Icache_insts[127:96] : 
                       ((pc[31:5]==Icache_pc_base)&&(Icache_pc_offset==3'b100)) ?  Icache_insts[159:128] :
	                   ((pc[31:5]==Icache_pc_base)&&(Icache_pc_offset==3'b101)) ?  Icache_insts[191:160] :
					   ((pc[31:5]==Icache_pc_base)&&(Icache_pc_offset==3'b110)) ?  Icache_insts[223:192] :
					   ((pc[31:5]==Icache_pc_base)&&(Icache_pc_offset==3'b111)) ?  Icache_insts[255:224] : 32'd0;
	//--------------{ר�Ÿ�����axi��������ָ��}----------------
	//����Ԥȡ��ǰ{pc[31:5]+1'b1,pc[4:0]}��ַ��ָ��
	//wire Icache_hit;
	//wire Icache_over;
	
	reg[31:0] cache_inst_addr;
	
	
	reg Icache_request;
	//reg[31:0] prefetch_pc;
	always @(posedge clk)    // PC���������
    begin
        if (!resetn)
		begin
			inst_en<=1'b1;
			axi_inst_addr<=`STARTADDR;
			fetch_state<=4'd3;
			Icache_request <= 1'b0;
		end
		if(cancel)
		begin
			 fetch_state<=4'd0;
			  inst_en<=1'b0;
			  axi_inst_addr<=32'd0;
			  Icache_request<=1'b0;
		end
		else if((fetch_state==4'd0)&~tlb_fetch_valid&(((use_Icache_buffer) | (use_axi_buffer)&real_use_axi_buffer) | addr_exc))
		begin
		  fetch_state<=4'd0;
		end
		//��Чָ�δ˳��ȡ�أ���Ҫ��һ������̬ȥ�ȴ�
		else if((fetch_state==4'd0)&(use_axi_buffer)&~real_use_axi_buffer)
		begin
			fetch_state<=4'd1;
		end
		else if((fetch_state==4'd1)&(use_axi_buffer)&real_use_axi_buffer)
		begin
			fetch_state<=4'd0;
		end
		//�õ�IcacheΪ����״̬��Icache_request������֪�����ʲô����
		else if((fetch_state==4'd0)&~((use_Icache_buffer) | (use_axi_buffer))&~tlb_fetch_valid)
		begin
			Icache_request<=1'b1;
			cache_inst_addr<={pc[31:5],5'd0};
			fetch_state<=4'd2;
		end
		else if((fetch_state==4'd2)&~Icache_hit)
		begin
			inst_en<=1'b1;
			axi_inst_addr<={pc[31:5],5'd0};
			fetch_state<=4'd3;
			Icache_request<=1'b0;
		end 
		
		else if((fetch_state==4'd3)&inst_load_launched)
		begin
		    inst_en<=1'b0;
			fetch_state<=4'd5;
		
		end
		else if(use_Icache_buffer | real_use_axi_buffer)
		begin
		      fetch_state<=4'd0;    
			  inst_en<=1'b0;
			  Icache_request<=1'b0;
		end
	end

	assign IF_over =(( (use_Icache_buffer) | (real_use_axi_buffer) | addr_exc | tlb_error)) ;
     
   // assign IF_over = (Icache_over | (|tlb_fetch_exc_r)) & ~cancel ;
    //���ָ��romΪ�첽���ģ���IF_valid����IF_over�źţ�
    //��ȡָһ�����
	
	
//-----{IFִ�����}end
	wire addr_exc;
	assign addr_exc = (pc[1:0]!=2'b00) ? 1'b1 : 1'b0;
//-----{IF->ID����}begin
    assign IF_ID_bus = {pc,fetch_inst,addr_exc, tlb_fetch_exc  ,is_ds & (pc==(ID_pc + 32'd4))};  // ȡָ����Чʱ������PC��ָ��
//-----{IF->ID����}end

//-----{չʾIFģ���PCֵ��ָ��}begin
    assign IF_pc   = pc;
    assign IF_inst = fetch_inst;

	wire [6:0] index;
	wire [19:0] tag;

	wire[3:0]  hit_hit; //��·����ޙ

	wire [279:0] Ientry_wire0;
	wire [279:0] Ientry_wire1;
	wire [279:0] Ientry_wire2;
	wire [279:0] Ientry_wire3;

	
	wire [1:0] LRU0;
	wire [1:0] LRU1;
	wire [1:0] LRU2;
	wire [1:0] LRU3;
	assign LRU0 = Ientry_wire0[277:276] ;
	assign LRU1 = Ientry_wire1[277:276] ;
	assign LRU2 = Ientry_wire2[277:276] ;
	assign LRU3 =  Ientry_wire3[277:276] ;
	

	reg[279:0] Icache_wdata0;
	reg[279:0] Icache_wdata1;
	reg[279:0] Icache_wdata2;
	reg[279:0] Icache_wdata3;
	
	reg[279:0] inst_from_cache_r;
    wire[279:0] inst_from_cache;
	assign inst_from_cache = ((|hit_hit)&&Icache_request) ? hit_data : inst_from_cache_r ;
	wire[26:0] Icache_pc_base;
	assign Icache_pc_base = ((|hit_hit)&&Icache_request) ? cache_inst_addr[31:5] : Icache_pc_base_r;
	assign index = Icache_wr      ?   update_inst_addr[11:5] : 
					cache_wren  ? cache_windex :
				   Icache_request ?   cache_inst_addr[11:5] :7'd0;
	               
	assign tag = Icache_wr      ? update_inst_addr[31:12] :
				Icache_request ? cache_inst_addr[31:12] :   20'd0;

	assign hit_hit  = 
					  Ientry_wire0[279]&(tag==Ientry_wire0[275:256]) ? 4'b0001 : 
					  Ientry_wire1[279]&(tag==Ientry_wire1[275:256]) ? 4'b0010 :
					  Ientry_wire2[279]&(tag==Ientry_wire2[275:256]) ? 4'b0100 :				  
					  Ientry_wire3[279]&(tag==Ientry_wire3[275:256]) ? 4'b1000 : 4'b0000;

	//is Icahce hit ? for MEM.v
	assign Icache_hit = ((hit_hit != 4'd0)&Icache_request);
	//����Ƕ�����ֱ�Ӱ�hit_data��data_from_cache������

	wire[255:0] hit_data;
	assign hit_data = (hit_hit == 4'h1) ? Ientry_wire0[255:0] :
					  (hit_hit == 4'h2) ? Ientry_wire1[255:0] :
					  (hit_hit == 4'h4) ? Ientry_wire2[255:0] :
					  (hit_hit == 4'h8) ? Ientry_wire3[255:0] :  256'd0;
					  

	wire[1:0] ULRU0;
	wire[1:0] ULRU1;
	wire[1:0] ULRU2;
	wire[1:0] ULRU3;
	assign ULRU0 = ((~(|hit_hit)&&Icache_wr) &&Ientry_wire0[279]) ?  LRU0+1'b1 : LRU0;
	assign ULRU1 = ((~(|hit_hit)&&Icache_wr) &&Ientry_wire1[279]) ?  LRU1+1'b1 : LRU1;
	assign ULRU2 = ((~(|hit_hit)&&Icache_wr) &&Ientry_wire2[279]) ?  LRU2+1'b1 : LRU2;
	assign ULRU3 = ((~(|hit_hit)&&Icache_wr) &&Ientry_wire3[279]) ?  LRU3+1'b1 : LRU3;	

	wire[1:0] RLRU0;
	wire[1:0] RLRU1;
	wire[1:0] RLRU2;
	wire[1:0] RLRU3;
	assign RLRU0 = (((|hit_hit))&&hit_hit[0]) ? 2'b00 :
							   (hit_hit[1]&&(LRU1>LRU0)&&Ientry_wire0[279]) ?  LRU0+1'b1 : 
							   (hit_hit[2]&&(LRU2>LRU0)&&Ientry_wire0[279]) ?  LRU0+1'b1 :
							   (hit_hit[3]&&(LRU3>LRU0)&&Ientry_wire0[279]) ? LRU0+1'b1 :  LRU0;
	assign RLRU1 = (((|hit_hit))&&hit_hit[1]) ? 2'b00 :
							   (hit_hit[0]&&(LRU0>LRU1)&&Ientry_wire1[279]) ? LRU1+1'b1 : 
							   (hit_hit[2]&&(LRU2>LRU1)&&Ientry_wire1[279]) ?  LRU1+1'b1 :
							   (hit_hit[3]&&(LRU3>LRU1)&&Ientry_wire1[279]) ?  LRU1+1'b1 :  LRU1;
	assign RLRU2 = (((|hit_hit))&&hit_hit[2]) ? 2'b00 :
							   (hit_hit[1]&&(LRU1>LRU2)&&Ientry_wire2[279]) ?  LRU2+1'b1 : 
							   (hit_hit[0]&&(LRU0>LRU2)&&Ientry_wire2[279]) ?  LRU2+1'b1 :
							   (hit_hit[3]&&(LRU3>LRU2)&&Ientry_wire2[279]) ?  LRU2+1'b1 :  LRU2;
							   
	assign RLRU3 = (((|hit_hit))&&hit_hit[3]) ? 2'b00 :
							   (hit_hit[1]&&(LRU1>LRU3)&&Ientry_wire3[279]) ? LRU3+1'b1 : 
							   (hit_hit[2]&&(LRU2>LRU3)&&Ientry_wire3[279]) ? LRU3+1'b1 :
							   (hit_hit[0]&&(LRU0>LRU3)&&Ientry_wire3[279]) ? LRU3+1'b1 :  LRU3;		
	
//----------{for prefetch}----------
	reg[26:0] Icache_pc_base_r;
	reg[31:0] hit_count;
	
	//assign Icache_over = ~cancel_r;
	//reg cancel_r;
	reg cache_wren;
	reg[6:0] cache_windex;
	   always @(posedge clk) 
		  begin
			if(!resetn)
			begin 
				//cancel_r <= 1'b0;
				cache_wren <= 1'b0;
				cache_windex <= 7'd0;
				update_finished <= 1'b0;
				Istate<=4'd0;  //��ʼ״̬
				hit_count <= 32'd0;
				Icache_wdata0 <= 280'd0 ;
				Icache_wdata1 <= 280'd0 ;
				Icache_wdata2 <= 280'd0 ;
				Icache_wdata3 <= 280'd0 ;
				inst_from_cache_r<=256'd0;
				Icache_pc_base_r<=27'd0;
			end
			//�쳣�������
			if(cancel)
			begin
				//cancel_r<=1'b1;
				if(Icache_request)
				begin
				    Istate <= 0;
				end
			end
			else if((Istate==4'd0)&&Icache_request && (|hit_hit))//������
			begin
				cache_wren <= 1'b1;
				cache_windex <= index;
				Istate <= 4'd11;
				inst_from_cache_r<=hit_data;
				Icache_pc_base_r<=cache_inst_addr[31:5];
				hit_count <= hit_count + 1;	
				//����LRU
				Icache_wdata0 <= {Ientry_wire0[279],1'b0,RLRU0,Ientry_wire0[275:0]};
				Icache_wdata1 <= {Ientry_wire1[279],1'b0,RLRU1,Ientry_wire1[275:0]};
				Icache_wdata2 <= {Ientry_wire2[279],1'b0,RLRU2,Ientry_wire2[275:0]};
				Icache_wdata3 <= {Ientry_wire3[279],1'b0,RLRU3,Ientry_wire3[275:0]};
			end
			else if((Istate==4'd0)&& Icache_wr)
			begin
				Istate<=4'd7;
				update_finished<=1'b0;
			end
			else if( Istate == 4'd7)
			begin
				Istate <= 4'd14;
			end
			else if((Istate==4'd14)&&~(|hit_hit))
			begin
			   //AXI���ߵ�������ȡ��������cache״̬
				cache_wren <= 1'b1;
				cache_windex <= index;
				Istate<=4'd11;
				//inst_from_cache<=axi_inst;
				if(LRU0==2'b11)
				begin
				  Icache_wdata1 <= {Ientry_wire1[279],1'b0,ULRU1,Ientry_wire1[275:0]};
				  Icache_wdata2 <= {Ientry_wire2[279],1'b0,ULRU2,Ientry_wire2[275:0]};
				  Icache_wdata3 <= {Ientry_wire3[279],1'b0,ULRU3,Ientry_wire3[275:0]};
				  Icache_wdata0 <= {1'b1,1'b0,2'b00,tag,axi_Icache_insts};			
				end
				else if(LRU1==2'b11)
				begin
				  Icache_wdata0 <= {Ientry_wire0[279],1'b0,ULRU0,Ientry_wire0[275:0]};
				  Icache_wdata2 <= {Ientry_wire2[279],1'b0,ULRU2,Ientry_wire2[275:0]};
				  Icache_wdata3 <= {Ientry_wire3[279],1'b0,ULRU3,Ientry_wire3[275:0]};
				  Icache_wdata1 <= {1'b1,1'b0,2'b00,tag,axi_Icache_insts};			
				end
				else if(LRU2==2'b11)
				begin
				  Icache_wdata0 <= {Ientry_wire0[279],1'b0,ULRU0,Ientry_wire0[275:0]};
				  Icache_wdata1 <= {Ientry_wire1[279],1'b0,ULRU1,Ientry_wire1[275:0]};
				  Icache_wdata3 <= {Ientry_wire3[279],1'b0,ULRU3,Ientry_wire3[275:0]};
				  Icache_wdata2 <= {1'b1,1'b0,2'b00,tag,axi_Icache_insts};				
				end
				else if(LRU3==2'b11)
				begin
				  Icache_wdata0 <= {Ientry_wire0[279],1'b0,ULRU0,Ientry_wire0[275:0]};
				  Icache_wdata2 <= {Ientry_wire2[279],1'b0,ULRU2,Ientry_wire2[275:0]};
				  Icache_wdata1 <= {Ientry_wire1[279],1'b0,ULRU1,Ientry_wire1[275:0]};
				  Icache_wdata3 <= {1'b1,1'b0,2'b00,tag,axi_Icache_insts};			
				end
				update_finished <= 1'b1;
			end
			else if((Istate==4'd14)&&(|hit_hit))
			begin
				update_finished <= 1'b1;
				Istate<=4'd11;
			end
			else if(Istate == 4'd11)
			begin
				cache_wren <= 1'b0;
				Istate <= 4'd0;
				//cancel_r<=1'b0;
				update_finished <= 1'b0;		
			end
		end
		
	dist_ram Icache_ram0(
		.clk(clk),
		.we(cache_wren),
		.a(index),
		.d(Icache_wdata0),
		.spo(Ientry_wire0)
	);
	
	dist_ram Icache_ram1(
		.clk(clk),
		.we(cache_wren),
		.a(index),
		.d(Icache_wdata1),
		.spo(Ientry_wire1)
	);
	
	dist_ram Icache_ram2(
		.clk(clk),
		.we(cache_wren),
		.a(index),
		.d(Icache_wdata2),
		.spo(Ientry_wire2)
	);
	
	dist_ram Icache_ram3(
		.clk(clk),
		.we(cache_wren),
		.a(index),
		.d(Icache_wdata3),
		.spo(Ientry_wire3)
	);
endmodule