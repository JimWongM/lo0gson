`timescale 1ns / 1ps

module cp0(                    // 取指级
    input             clk,       // 时钟
    input             resetn,    // 复位信号，低电平有效
	input             CP0_valid,
	input             cancel,

	input [156:0] MEM_CP0_bus_r,
	input [162:0] tlb_cp0_bus,
/* 	output exc_happened,
	output int_happened,
	output [31:0] cp0r_rdata , // 读cp0 寄存器时所需要传出来的数据 */
	//output tlb_inst_over,
	output [164:0] cp0_tlb_bus,
	output CP0_over,
	output [67:0] CP0_WB_bus
	//output [31:0] real_pc
);
	
	wire[7:0] cp0r_addr;
	wire[31:0] badvaddr;
	wire[31:0] mem_result;
	//wire WB_valid;
	wire syscall;
	wire Break;
	wire trap;
	wire[1:0] addr_exc;
	wire ov_exc;
	wire ri;
	wire mtc0;
	wire eret;
	wire is_ds;
	wire [31:0] cp0r_rdata;
	wire tlb_fetch_refill;
	wire tlb_fetch_invalid;
	wire tlb_fetch_modified;
	wire tlb_mem_refill;
	wire tlb_mem_invalid;
	wire tlb_mem_modified;
	wire inst_store;
	wire inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR;
	wire [31:0] pc;
	wire [31:0] data_vaddr;
	
	assign {cp0r_addr,
				badvaddr,
				mem_result,
				//WB_valid,
				syscall,
				Break,
				trap,
				addr_exc,
				ov_exc,
				ri,
				mtc0,
				eret,
				is_ds,
				tlb_fetch_refill,tlb_fetch_invalid,tlb_fetch_modified,
				tlb_mem_refill,tlb_mem_invalid,tlb_mem_modified,inst_store,
				inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,pc,data_vaddr}=MEM_CP0_bus_r;

	wire [31:0] tlb_index;
	assign tlb_index = inst_TLBWR ? cp0r_random : 
								  (inst_TLBWI | inst_TLBR) ? cp0r_index : 32'd32;
	
	//wire [163:0] cp0_tlb_bus;
	wire tlb_cp0_valid;
	assign tlb_cp0_valid = (inst_TLBP | inst_TLBR | inst_TLBWI | inst_TLBWR) & CP0_valid;
	assign cp0_tlb_bus = {tlb_cp0_valid , tlb_index,cp0r_entryhi,cp0r_pagemask, cp0r_entrylo0,cp0r_entrylo1,
										inst_TLBR , inst_TLBP , inst_TLBWI ,inst_TLBWR};
										
	//wire[162:0] tlb_cp0_bus_r;
	
/* 	tlb tlb_module(
		.cp0_tlb_bus_r(cp0_tlb_bus),
		.tlb_cp0_bus(tlb_cp0_bus_r)
	); */
	
	wire [31:0] tlb_w_index;
	wire tlb_index_wen;
	wire tlb_inst_over;
	
	wire cp0_wen;//其它与cp0寄存器有关的信号的写入
	wire [31:0] tlb_w_entryhi;
	wire [31:0] tlb_w_entrylo0;
	wire [31:0] tlb_w_entrylo1;
	wire [31:0] tlb_w_pagemask;
	
	assign {tlb_w_index , tlb_index_wen , tlb_inst_over,
				cp0_wen, tlb_w_entryhi,tlb_w_entrylo0,tlb_w_entrylo1,tlb_w_pagemask} = tlb_cp0_bus;
				
	
	
   wire [31:0] cp0r_status;
   wire [31:0] cp0r_cause;
   wire [31:0] cp0r_epc;  
   wire [31:0] cp0r_count;
   wire [31:0] cp0r_compare;
   wire [31:0] cp0r_badvaddr;	
   wire [31:0] cp0r_index;//新加的和TLB有关的六个CP0寄存器
   wire [31:0] cp0r_entryhi;
   wire [31:0] cp0r_entrylo0;
   wire [31:0] cp0r_entrylo1;
   wire [31:0] cp0r_pagemask;
   wire [31:0] cp0r_random;//这里先不设置wired 寄存器，则random寄存器可以从31一直减到0

   //写使能
   wire status_wen;
   wire cause_wen;
   wire epc_wen;
   wire count_wen ;
   wire compare_wen;	
   
   //新增写使能
   wire index_wen;
   wire entryhi_wen;
   wire entrylo0_wen;
   wire entrylo1_wen;
   wire pagemask_wen; 
   //wire random_wen;  random 是只读信号，不能写，故这里不需要这个
   
   assign index_wen = mtc0 & (cp0r_addr == 8'd0);
   assign entryhi_wen = mtc0 & (cp0r_addr == {5'd10,3'd0});
   assign entrylo0_wen = mtc0 & (cp0r_addr == {5'd2,3'd0});
   assign entrylo1_wen = mtc0 & (cp0r_addr == {5'd3,3'd0});
   assign pagemask_wen = mtc0 & (cp0r_addr =={5'd5,3'd0});
   
   assign status_wen = mtc0 & (cp0r_addr=={5'd12,3'd0});
   assign epc_wen    = mtc0 & (cp0r_addr=={5'd14,3'd0});
   assign cause_wen = mtc0 & (cp0r_addr=={5'd13,3'd0});
   assign count_wen = mtc0 & (cp0r_addr=={5'd9,3'd0});
   assign compare_wen = mtc0 & (cp0r_addr=={5'd11,3'd0});
   //cp0寄存器读  
   //目前只实现STATUS[1]位，即EXL域
   //EXL域为软件可读写，故需要statu_wen
    assign cp0r_rdata = (cp0r_addr == 8'd0 ) ? cp0r_index :
						(cp0r_addr=={5'd1,3'd0}) ? cp0r_random :
						(cp0r_addr=={5'd2,3'd0}) ? cp0r_entrylo0 :
						(cp0r_addr=={5'd3,3'd0}) ? cp0r_entrylo1 :
						(cp0r_addr=={5'd5,3'd0}) ? cp0r_pagemask :
						(cp0r_addr=={5'd10,3'd0}) ? cp0r_entryhi :
						(cp0r_addr=={5'd8,3'd0}) ? cp0r_badvaddr :
						(cp0r_addr=={5'd9,3'd0}) ? cp0r_count :
	                    (cp0r_addr=={5'd11,3'd0}) ? cp0r_compare :
	                    (cp0r_addr=={5'd12,3'd0}) ? cp0r_status :
						(cp0r_addr=={5'd13,3'd0}) ? cp0r_cause :
						(cp0r_addr=={5'd14,3'd0}) ? cp0r_epc : 32'd0;
	
	//index 寄存器只有最高位不可写，但是由于TLB为32项，故只有低五位有效。
	reg [31:0] index_r;
	assign cp0r_index = index_r;
	always @(posedge clk)
	begin
		if(!resetn)
		begin
			index_r <= 32'd0;
			//tlb_index_over <=1'b0;
		end
		else if(index_wen && CP0_valid)
		begin
			index_r <= {27'd0 , mem_result[4:0]};
		end
		else if(tlb_index_wen && tlb_inst_over)
		begin
			index_r <= tlb_w_index;
		end
	end
	
	//random 寄存器为只读寄存器，没有写使能
	reg [31:0] random_r;
	assign cp0r_random = random_r;
	always @(posedge clk)
	begin
		if(!resetn)
		begin
			random_r <= 32'd31;
		end
		else if (CP0_over)
		begin
			random_r <=random_r - 1'b1;
			if(random_r[31])
			begin
				random_r <= 32'd31;
			end 
		end
	end
	
	reg [31:0] entryhi_r;
	assign cp0r_entryhi = entryhi_r;
	always @(posedge clk) 
	begin
		if(!resetn)
		begin
			entryhi_r <= 32'd0;
		end
		else if(entryhi_wen && CP0_valid)
		begin
			entryhi_r <= {mem_result[31:13] , 5'b00000 , mem_result[7:0]};
		end
		else if(cp0_wen && tlb_inst_over)
		begin
			entryhi_r <= tlb_w_entryhi;
		end
		else if(tlb_fetch_refill | tlb_fetch_invalid | tlb_fetch_modified)
		begin
			entryhi_r[31:13] <= pc[31:13];
		end
		else if(tlb_mem_refill | tlb_mem_invalid | tlb_mem_modified)
		begin
			entryhi_r[31:13] <= data_vaddr[31:13];
		end
	end
	
	reg [31:0] entrylo0_r;
	assign cp0r_entrylo0 = entrylo0_r;
	always @(posedge clk)
	begin
		if(!resetn)
		begin
			entrylo0_r <= 32'd0;
		end
		else if(entrylo0_wen && CP0_valid)
		begin
			entrylo0_r <= {6'd0 , mem_result[25:0]};
		end
		else if (cp0_wen && tlb_inst_over )
		begin
			entrylo0_r <= tlb_w_entrylo0;
		end
	end
	
	reg [31:0] entrylo1_r;
	assign cp0r_entrylo1 = entrylo1_r;
	always @(posedge clk)
	begin
		if(!resetn)
		begin
			entrylo1_r <= 32'd0;
		end
		else if(entrylo1_wen && CP0_valid)
		begin
			entrylo1_r <= {6'd0 , mem_result[25:0]};
		end
		else if(cp0_wen && tlb_inst_over)
		begin
			entrylo1_r <= tlb_w_entrylo1;
		end
	end
	
	reg [31:0]  pagemask_r;//参考mips手册，如果按照release 1而言，那么对于4KB 的页而言，应该置全0 ，且不可写
	assign cp0r_pagemask = pagemask_r ;
	always @(posedge clk)
	begin
		if(!resetn)
		begin
			pagemask_r <= 32'd0;
		end
		else if (pagemask_wen && CP0_valid)
		begin
			pagemask_r <= {7'd0,mem_result[24:13],13'd0};
		end
		else if(cp0_wen && tlb_inst_over)
		begin
			pagemask_r <= tlb_w_pagemask;
		end
	end
	
   reg [31:0] status_r;
   assign cp0r_status = status_r;
   always @(posedge clk)
   begin
       if (!resetn)
       begin
           status_r[31:23] <= 9'd0;
		   status_r[22] <= 1'b1;
		   status_r[21:16] <= 6'd0;
		   status_r[7:0] <= 8'd0;
       end
	   else if (eret && CP0_valid)
	   begin
		   status_r[1] <= 1'b0;
	   end
       else if ((cp0r_status[0] && ~cp0r_status[1] && 
                    ( (cp0r_cause[15] && cp0r_status[15])
                    || (cp0r_cause[14] && cp0r_status[14])
                    || (cp0r_cause[13] && cp0r_status[13])
                    || (cp0r_cause[12] && cp0r_status[12])
                    || (cp0r_cause[11] && cp0r_status[11])
                    || (cp0r_cause[10] && cp0r_status[10])
                    || (cp0r_cause[9 ] && cp0r_status[9 ])
                    || (cp0r_cause[8 ] && cp0r_status[8 ]))) || exc_happened)
       begin
            status_r[1] <= 1'b1;
       end
       else if (status_wen && CP0_valid)
       begin
           status_r <= {
							9'd0,
							1'd1,
							6'd0,
							mem_result[15:8],
							6'd0,
							mem_result[1:0]
						};
       end
   end   
 
   //CAUSE寄存器
   //目前只实现CAUSE[6:2]位，即ExcCode域,存放Exception编码
   //ExcCode域为软件只读，不可写，故不需要cause_wen
   reg [31:0] cause_r;
   assign cp0r_cause=cause_r;
   
   //assign cp0r_cause = {25'd0,cause_exc_code_r,2'd0};
   always @(posedge clk)
   begin
		if (!resetn)
		begin
			cause_r[31:7] <= 25'd0;
			cause_r[1:0] <= 2'd0;
		end
		cause_r[15] <= cause_r[30];
		if ((exc_happened | int_happened) & CP0_valid)
		begin
			cause_r[31] <= is_ds;
		end
		if (compare_wen && CP0_valid)
		begin
		    cause_r[30] <= 1'b0;
		end 
		else if (count_r == compare_r)	// TI
		begin
			cause_r[30] <= 1'b1;
			cause_r[15] <= cause_r[30];
			cause_r[6:2] <= 5'h0;
		end
       if (syscall& ~cp0r_status[1])//Sys
       begin
           cause_r[6:2] <= 5'd8;
       end
	   if(Break& ~cp0r_status[1])//###################4.24 Bp
	   begin
		   cause_r[6:2] <= 5'd9;
	   end
	   if(trap & ~cp0r_status[1])
	   begin
			cause_r[6:2] <=5'd13;
	   end
	   if((tlb_mem_invalid | tlb_mem_refill) & ~cp0r_status[1])
	   begin
			if(inst_store)
			begin
					cause_r[6:2] <= 5'd3;
			end
			else 
			begin
					cause_r[6:2] <= 5'd2;
			end
	   end
	   if((tlb_fetch_invalid | tlb_fetch_refill) & ~cp0r_status[1])
	   begin
					cause_r[6:2] <= 5'd2;
	   end
	   if((tlb_fetch_modified | tlb_mem_modified) & ~cp0r_status[1]) 
	   begin
			cause_r[6:2] <= 5'd1;
	   end
	   if ((addr_exc[1] == 1'b1) & ~cp0r_status[1]) 		// AdEL
		begin
			cause_r[6:2] <= 5'h4;
		end
		if ((addr_exc[1:0] == 2'b01) & ~cp0r_status[1]) 	// AdEsS
		begin
			cause_r[6:2] <= 5'h5;
		end
		if (ri & ~cp0r_status[1])						// RI
		begin 				
			cause_r[6:2] <= 5'ha;
		end
		if (ov_exc & ~cp0r_status[1])						// Ov
		begin 				
			cause_r[6:2] <= 5'hc;
		end
		if (cause_wen && CP0_valid & ~cp0r_status[1])
		begin
		    cause_r[9:8] <= mem_result[9:8];
		end
		if(cp0r_status[0] && ~cp0r_status[1] && 
	        ( (cp0r_cause[15] & cp0r_status[15])
            | (cp0r_cause[14] & cp0r_status[14])
            | (cp0r_cause[13] & cp0r_status[13])
            | (cp0r_cause[12] & cp0r_status[12])
            | (cp0r_cause[11] & cp0r_status[11])
            | (cp0r_cause[10] & cp0r_status[10])
            | (cp0r_cause[9] & cp0r_status[9])
            | (cp0r_cause[8] & cp0r_status[8])))
		begin
		    cause_r[6:2] <= 5'd0;
        end
		if (int_happened & ((cp0r_cause[9] & cp0r_status[9])|(cp0r_cause[8] & cp0r_status[8])) & CP0_valid)
		begin
	        cause_r[9:8] <= 2'b0;
		end
   end
   
   
   
   
   reg [31:0] badvaddr_r;
	assign cp0r_badvaddr = badvaddr_r;
	always @(posedge clk) 
	begin
		if (((addr_exc[1:0] == 2'b10) || (addr_exc[1:0] == 2'b01)) & cancel)
		begin
			badvaddr_r <= badvaddr;
		end
		else if (addr_exc[1:0] == 2'b11 & cancel)
		begin
		    badvaddr_r <= pc;
		end
		else if(tlb_fetch_refill | tlb_fetch_invalid | tlb_fetch_modified)
		begin
			badvaddr_r <= pc;		
		end
		else if(tlb_mem_refill | tlb_mem_invalid | tlb_mem_modified)
		begin
			badvaddr_r <= data_vaddr;
		end
	end
   //EPC寄存器
   //存放产生例外的地址
   //EPC整个域为软件可读写的，故需要epc_wen
   reg [31:0] epc_r;
   assign cp0r_epc = epc_r;
   always @(posedge clk)
   begin
       if (exc_valid && is_ds)
		begin
		   epc_r <= pc - 32'd4;
		end
		else if (exc_valid && ~is_ds)
		begin
			epc_r <= pc;
		end
		else if (epc_wen && CP0_valid)
		begin
		   epc_r <= mem_result;
		end
   end
   
   //COUNT寄存器
   reg [31:0] count_r;
	reg count0;
	assign cp0r_count = count_r;
	always @(posedge clk) 
	begin
	    if (!resetn)
	    begin
	       count0 <= 1'b0;
	    end
	    else if (count0)
	    begin
	       count0 <= 1'b0;
           count_r <= count_r + 1'b1;
	    end
	    else if (~count0)
	    begin
	       count0 <= 1'b1;
	    end
		if (count_wen&& CP0_valid)
		begin
			count_r <= mem_result;
		end
	end
	
	//COMPARE寄存器
	reg [31:0] compare_r;
	assign cp0r_compare = compare_r;
	always @(posedge clk) 
	begin
		if (compare_wen&& CP0_valid)
		begin
			compare_r <= mem_result;
		end
	end   


//异常和中断的处理
	wire exc_valid;
	wire 	    exc_happened;
	reg         int_happened;
	always @(posedge clk)
	begin
	    if (!resetn)
	    begin
	        int_happened <= 1'b0;
	    end
	    else if (cp0r_status[0] && ~cp0r_status[1] && 
	        ( (cp0r_cause[15] & cp0r_status[15])
            | (cp0r_cause[14] & cp0r_status[14])
            | (cp0r_cause[13] & cp0r_status[13])
            | (cp0r_cause[12] & cp0r_status[12])
            | (cp0r_cause[11] & cp0r_status[11])
            | (cp0r_cause[10] & cp0r_status[10])
            | (cp0r_cause[9] & cp0r_status[9])
            | (cp0r_cause[8] & cp0r_status[8])))
        begin
	        int_happened <= 1'b1;
	    end
	    else if (exc_valid)
	    begin
	        int_happened <= 1'b0;
	    end
	end
		
	assign exc_valid = ((exc_happened | eret | int_happened | (tlb_fetch_refill | tlb_mem_refill)) & CP0_valid);
	assign exc_happened = (tlb_fetch_invalid | tlb_mem_invalid)|( tlb_fetch_modified | tlb_mem_modified) | syscall | Break | trap | (addr_exc[1:0]!=2'b00) | ov_exc | ri;	
	assign CP0_WB_bus = {exc_happened,int_happened,exc_valid,cp0r_rdata,cp0r_epc,CP0_over};
	assign CP0_over = tlb_cp0_valid ? tlb_inst_over: CP0_valid;
endmodule