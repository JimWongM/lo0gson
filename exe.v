`timescale 1ns / 1ps

module exe(                         // ִ�м�
    input              EXE_valid,   // ִ�м���Ч�ź�
    input      [197:0] ID_EXE_bus_r,// ID->EXE����##############################4.22
    output             EXE_over,    // EXEģ��ִ�����
    output     [178:0] EXE_MEM_bus, // EXE->MEM����
    
     //5����ˮ����
     input             clk,       // ʱ��
     output     [  4:0] EXE_wdest,   // EXE��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
	 
	 //output     MemRead,  //load�źţ�ð�ռ��
	 output	   [ 31:0] EXE_rs_value,    //������EXE/MEM������result��ֵ,decodeģ���п��ܻ��õ�(��·)
	 output    EXE_bypass_en,
    //չʾPC
    output     [ 31:0] EXE_pc
);
//-----{ID->EXE����}begin
    //EXE��Ҫ�õ�����Ϣ
    wire multiply;            //�˷�
    wire mthi;             //MTHI
    wire mtlo;             //MTLO
	wire mult_sign;//##########################4.22
	wire divide;//########################4.22
	wire divide_sign;//############################4.22
    wire [12:0] alu_control;
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;
	wire hi_lo_sub;//���ڶԳ˷����յĽ��ȡ����ָ��
	wire mov_w_rd;//���ڶ�mov �źŵ�ѡ�����յ�exe_result
	wire trap;//��decode��
/* 	wire [1:0] trap_judge;
	wire is_unsigned; */
	wire inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR;
	wire [2:0] tlb_fetch_exc;
    //�ô���Ҫ�õ���load/store��Ϣ
    wire [13:0] mem_control;  //MEM��Ҫʹ�õĿ����ź�######################4.22
    wire [31:0] store_data;  //store�����Ĵ������
                          
    //д����Ҫ�õ�����Ϣ
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall��eret��д�ؼ�������Ĳ��� 
    wire       eret;
	wire       Break;//####################4.22
    wire       rf_wen;    //д�صļĴ���дʹ��
    wire [4:0] rf_wdest;  //д�ص�Ŀ�ļĴ���
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
//-----{ID->EXE����}end

//-----{ALU}begin
    wire [31:0] alu_result;
    wire ov;
    alu alu_module(
        .alu_control  (alu_control ),  // I, 12, ALU�����ź�
        .alu_src1     (alu_operand1),  // I, 32, ALU������1
        .alu_src2     (alu_operand2),  // I, 32, ALU������2
        .alu_result   (alu_result  ),  // O, 32, ALU���
		.ov(ov)
    );
//-----{ALU}end

//-----{�˷���}begin
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
//-----{�˷���}end

//------{������}begin############################4.22
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
//  ------{ʵ��trap�й�ָ��} 7.15
/* wire is_trap;
wire [1:0] result_compare;
assign result_compare = ~(|alu_result) ? 2'b00:
										(|alu_result ) ? 2'b11:
										~alu_result[31] ? 2'b01:
										alu_result[31] ? 2'b10: 2'b00;
										
assign is_trap = trap & (trap_judge == result_compare ) ;// ����������ȵ�ʱ�򣬼����Ա�ִ֤��trap */
// #############end


//-------{������}end#################################

//-----{EXEִ�����}begin
    //����ALU����������1�Ŀ���ɣ�
    //�����ڳ˷���������Ҫ�������
	//���ڳ���������Ҳ��Ҫ�������#######################4.22
    assign EXE_over = EXE_valid & (~multiply | mult_end)&(~divide|divide_end);
//-----{EXEִ�����}end

//-----{EXEģ���destֵ}begin
   //ֻ����EXEģ����Чʱ����д��Ŀ�ļĴ����Ų�������
    assign EXE_wdest = rf_wdest & {5{EXE_valid}};
//-----{EXEģ���destֵ}end

//-----{EXE->MEM����}begin
    wire [31:0] hi_result;   //��exe����ȷ��������д�ؽ��
    wire [31:0] lo_result;
    wire        hi_write;
    wire        lo_write;
	wire        ov_exc;
	assign ov_exc=ov&ov_en;
    //Ҫд��HI��ֵ����hi_result�����MULT��MTHIָ��,
    //Ҫд��LO��ֵ����lo_result�����MULT��MTLOָ��,
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
    
    assign EXE_MEM_bus = {mem_control,store_data,          //load/store��Ϣ��store����
                          data_related_en,
                          hi_result,                      //exe������
                          lo_result,                       //�˷���32λ���������
                          hi_write,lo_write,               //HI/LOдʹ�ܣ�����
                          mfhi,mflo,                       //WB���õ��ź�,����
                          mtc0,mfc0,cp0r_addr,syscall,eret,Break,trap,//WB���õ��ź�,����#######################4.22
						  addr_exc,ri,ov_exc,is_ds,
                          inst_madd,rf_wen,rf_wdest,                 //WB���õ��ź�
						  inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,
						  tlb_fetch_exc,
                          pc};                             //PC
//-----{EXE->MEM����}end
	//inst_load  ð�ռ��
	//assign  MemRead = mem_control[12];
	assign  EXE_rs_value=lo_result;
//-----{չʾEXEģ���PCֵ}begin
    assign EXE_pc = pc;
    assign EXE_bypass_en=data_related_en;
//-----{չʾEXEģ���PCֵ}end
endmodule
//����
//�޷��ų˷�
//�з������޷��ų���
