`timescale 1ns / 1ps

module exe(                         // 执行级
    input              EXE_valid,   // 执行级有效信号
    input      [197:0] ID_EXE_bus_r,// ID->EXE总线##############################4.22
    output             EXE_over,    // EXE模块执行完成
    output     [178:0] EXE_MEM_bus, // EXE->MEM总线
    
     //5级流水新增
     input             clk,       // 时钟
     output     [  4:0] EXE_wdest,   // EXE级要写回寄存器堆的目标地址号
	 
	 //output     MemRead,  //load信号，冒险检测
	 output	   [ 31:0] EXE_rs_value,    //来自于EXE/MEM总线上result的值,decode模块中可能会用到(旁路)
	 output    EXE_bypass_en,
    //展示PC
    output     [ 31:0] EXE_pc
);
//-----{ID->EXE总线}begin
    //EXE需要用到的信息
    wire multiply;            //乘法
    wire mthi;             //MTHI
    wire mtlo;             //MTLO
	wire mult_sign;//##########################4.22
	wire divide;//########################4.22
	wire divide_sign;//############################4.22
    wire [12:0] alu_control;
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;
	wire hi_lo_sub;//用于对乘法最终的结果取反的指令
	wire mov_w_rd;//用于对mov 信号的选择最终的exe_result
	wire trap;//见decode级
/* 	wire [1:0] trap_judge;
	wire is_unsigned; */
	wire inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR;
	wire [2:0] tlb_fetch_exc;
    //访存需要用到的load/store信息
    wire [13:0] mem_control;  //MEM需要使用的控制信号######################4.22
    wire [31:0] store_data;  //store操作的存的数据
                          
    //写回需要用到的信息
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall和eret在写回级有特殊的操作 
    wire       eret;
	wire       Break;//####################4.22
    wire       rf_wen;    //写回的寄存器写使能
    wire [4:0] rf_wdest;  //写回的目的寄存器
    wire data_related_en;
    wire addr_exc;
	wire ri;
	wire ov_en;
	wire is_ds;
	wire inst_madd;
    //pc
    wire [31:0] pc;
    assign {multiply,
            mthi,
            mtlo,
			mult_sign,//##################4.22
			mov_w_rd,//###################7.11
			divide,//#######################4.22
			divide_sign,//###################4.22
            alu_control,
            alu_operand1,
            alu_operand2,
			hi_lo_sub,
			trap,
/* 			trap_judge,
			is_unsigned, */
            data_related_en,
            mem_control,
            store_data,
            mfhi,
            mflo,
            mtc0,
            mfc0,
            cp0r_addr,
            syscall,
            eret,
			Break,//#################4.22
			addr_exc,
			ri,
			ov_en,
			is_ds,
			inst_madd,
            rf_wen,
            rf_wdest,
			inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,
			tlb_fetch_exc,
            pc          } = ID_EXE_bus_r;
//-----{ID->EXE总线}end

//-----{ALU}begin
    wire [31:0] alu_result;
    wire ov;
    alu alu_module(
        .alu_control  (alu_control ),  // I, 12, ALU控制信号
        .alu_src1     (alu_operand1),  // I, 32, ALU操作数1
        .alu_src2     (alu_operand2),  // I, 32, ALU操作数2
        .alu_result   (alu_result  ),  // O, 32, ALU结果
		.ov(ov)
    );
//-----{ALU}end

//-----{乘法器}begin
    wire        mult_begin; 
    wire [63:0] product; 
    wire        mult_end;
    
    assign mult_begin = multiply & EXE_valid;
    multiply multiply_module (
        .clk       (clk       ),
        .mult_begin(mult_begin  ),
        .imult_op1  (alu_operand1), 
        .imult_op2  (alu_operand2),
		.mult_sign (mult_sign),//####################4.22
        .product   (product   ),
        .mult_end  (mult_end  )
		
    );
//-----{乘法器}end

//------{除法器}begin############################4.22
wire divide_begin;
wire [31:0] divide_result;
wire [31:0] divide_remainder;
wire divide_end;
assign divide_begin=divide&EXE_valid;
	divider divide_module
	(
		.clk(clk),
		.div_begin(divide_begin),
		.div_signed(divide_sign),
		.div_op1(alu_operand1),
		.div_op2(alu_operand2),		
		.div_result(divide_result),
		.div_remainder(divide_remainder),
		.div_end(divide_end)
		
	);
//  ------{实现trap有关指令} 7.15
/* wire is_trap;
wire [1:0] result_compare;
assign result_compare = ~(|alu_result) ? 2'b00:
										(|alu_result ) ? 2'b11:
										~alu_result[31] ? 2'b01:
										alu_result[31] ? 2'b10: 2'b00;
										
assign is_trap = trap & (trap_judge == result_compare ) ;// 当这两个相等的时候，即可以保证执行trap */
// #############end


//-------{除法器}end#################################

//-----{EXE执行完成}begin
    //对于ALU操作，都是1拍可完成，
    //但对于乘法操作，需要多拍完成
	//对于除法操作，也需要多拍完成#######################4.22
    assign EXE_over = EXE_valid & (~multiply | mult_end)&(~divide|divide_end);
//-----{EXE执行完成}end

//-----{EXE模块的dest值}begin
   //只有在EXE模块有效时，其写回目的寄存器号才有意义
    assign EXE_wdest = rf_wdest & {5{EXE_valid}};
//-----{EXE模块的dest值}end

//-----{EXE->MEM总线}begin
    wire [31:0] hi_result;   //在exe级能确定的最终写回结果
    wire [31:0] lo_result;
    wire        hi_write;
    wire        lo_write;
	wire        ov_exc;
	assign ov_exc=ov&ov_en;
    //要写入HI的值放在hi_result里，包括MULT和MTHI指令,
    //要写入LO的值放在lo_result里，包括MULT和MTLO指令,
    assign hi_result = mthi     ? alu_operand1 :
                        multiply ? product[63:32] : 
						hi_lo_sub ? ~product[63:32]:divide_remainder;//################4.22
    assign lo_result  = mtlo|mov_w_rd ? alu_operand1 :
									mtc0 ? alu_operand2:
									multiply? product[31:0]:
									hi_lo_sub ? ~product[31:0] :
									divide ? divide_result : alu_result;
    assign hi_write   = divide | multiply | mthi;
    assign lo_write   = divide | multiply | mtlo;
    
    assign EXE_MEM_bus = {mem_control,store_data,          //load/store信息和store数据
                          data_related_en,
                          hi_result,                      //exe运算结果
                          lo_result,                       //乘法低32位结果，新增
                          hi_write,lo_write,               //HI/LO写使能，新增
                          mfhi,mflo,                       //WB需用的信号,新增
                          mtc0,mfc0,cp0r_addr,syscall,eret,Break,trap,//WB需用的信号,新增#######################4.22
						  addr_exc,ri,ov_exc,is_ds,
                          inst_madd,rf_wen,rf_wdest,                 //WB需用的信号
						  inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,
						  tlb_fetch_exc,
                          pc};                             //PC
//-----{EXE->MEM总线}end
	//inst_load  冒险检测
	//assign  MemRead = mem_control[12];
	assign  EXE_rs_value=lo_result;
//-----{展示EXE模块的PC值}begin
    assign EXE_pc = pc;
    assign EXE_bypass_en=data_related_en;
//-----{展示EXE模块的PC值}end
endmodule
//总线
//无符号乘法
//有符号与无符号除法
