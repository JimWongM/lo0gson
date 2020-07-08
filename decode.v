`timescale 1ns / 1ps

module decode(                      // 译码级
    input              ID_valid,    // 译码级有效信号
    input      [ 68:0] IF_ID_bus_r, // IF->ID总线
    input      [ 31:0] rs_value,    // 第一源操作数值
    input      [ 31:0] rt_value,    // 第二源操作数值
    output     [  4:0] rs,          // 第一源操作数地址 
    output     [  4:0] rt,          // 第二源操作数地址
    output     [ 32:0] jbr_bus,     // 跳转总线
    output             inst_jbr,    // 指令为跳转分支指令,五级流水不需要
    output             ID_over,     // ID模块执行完成
    output     [197:0] ID_EXE_bus,  // ID->EXE总线###################################4.22
    
    //5级流水新增
     input              IF_over,     //对于分支指令，需要该信号
	 
    input      [  4:0] EXE_wdest,   // EXE级要写回寄存器堆的目标地址号
    input      [  4:0] MEM_wdest,   // MEM级要写回寄存器堆的目标地址号
    input      [  4:0] WB_wdest,    // WB级要写回寄存器堆的目标地址号
    
	//旁路用到的信号
	input         EXE_over,
	input         MEM_over,
	input	   [ 31:0] EXE_rs_value,    //来自于EXE/MEM总线上result的值
    input      [ 31:0] MEM_rs_value,     //来自于MEM总线上result的值
    //input 		MemRead ,   //ID/EX.MEMRead是否有效	
    input           EXE_bypass_en,
    input           MEM_bypass_en,
    //展示PC
    output     [ 31:0] ID_pc
);
//-----{IF->ID总线}begin
    wire [31:0] pc;
    wire [31:0] inst;
	wire addr_exc;
	wire [2:0] tlb_fetch_exc;
	 wire is_ds;
    assign {pc, inst,addr_exc, tlb_fetch_exc ,is_ds} = IF_ID_bus_r;  // IF->ID总线传PC和指令
//-----{IF->ID总线}end


    wire [31:0] new_rs_value;
    wire [31:0] new_rt_value;
//-----{指令译码}begin
    wire [5:0] op;       
    wire [4:0] rd;       
    wire [4:0] sa;      
    wire [5:0] funct;    
    wire [15:0] imm;     
    wire [15:0] offset;  
    wire [25:0] target;  
    wire [2:0] cp0r_sel;

    assign op     = inst[31:26];  // 操作码
    assign rs     = inst[25:21];  // 源操作数1
    assign rt     = inst[20:16];  // 源操作数2
    assign rd     = inst[15:11];  // 目标操作数
    assign sa     = inst[10:6];   // 特殊域，可能存放偏移量
    assign funct  = inst[5:0];    // 功能码
    assign imm    = inst[15:0];   // 立即数
    assign offset = inst[15:0];   // 地址偏移量
    assign target = inst[25:0];   // 目标地址
    assign cp0r_sel= inst[2:0];   // cp0寄存器的select域

    // 实现指令列表
    wire inst_ADDU, inst_SUBU , inst_SLT , inst_AND;
    wire inst_NOR , inst_OR   , inst_XOR , inst_SLL;
    wire inst_SRL , inst_ADDIU, inst_BEQ , inst_BNE;
    wire inst_LW  , inst_SW   , inst_LUI , inst_J;
    wire inst_SLTU, inst_JALR , inst_JR  , inst_SLLV;
    wire inst_SRA , inst_SRAV , inst_SRLV, inst_SLTIU;
    wire inst_SLTI, inst_BGEZ , inst_BGTZ, inst_BLEZ;
    wire inst_BLTZ, inst_LB   , inst_LBU , inst_SB;
    wire inst_ANDI, inst_ORI  , inst_XORI, inst_JAL;
    wire inst_MULT, inst_MFLO , inst_MFHI, inst_MTLO;
    wire inst_MTHI, inst_MFC0 , inst_MTC0;
    wire inst_ERET, inst_SYSCALL;
	
	//新增的指令列表##################################4.19
	wire inst_ADD,inst_SUB,inst_DIV,inst_DIVU;
	wire inst_MULTU,inst_ADDI,inst_BLTZAL,inst_BGEZAL;
	wire inst_BREAK,inst_LH,inst_LHU,inst_LWL;
	wire inst_LWR,inst_SH,inst_SWL,inst_SWR;
	//################################end
	
	
	//新增的指令列表##################################7.11
	wire inst_CLO,inst_CLZ;//CLO为首1计数器，CLZ为首0计数器
	wire inst_MADD,inst_MADDU;//(HI,LO) ← (HI,LO) + (GPR[rs] × GPR[rt]) 即先相乘，最后相加
	wire inst_MSUB,inst_MSUBU;//(HI,LO) ← (HI,LO) - (GPR[rs] × GPR[rt])
	wire inst_MUL;//乘法指令，将乘法的地位的结果保存在rd寄存器中，不改变hi和lo的值
	wire inst_MOVN,inst_MOVZ;//两条相关的MOV指令，判断rt_value后，选择是否传递rs_value至rd
	//###############################end
	
	//新增的指令列表##################################7.15
	wire inst_TEQ,inst_TEQI;//当两个数相等的时候，trap
	wire inst_TGE,inst_TGEI,inst_TGEIU,inst_TGEU;//当rs大于等于rt(或立即数），trap
	wire inst_TLT,inst_TLTI,inst_TLTIU,inst_TLTU;//同理，小于trap
	wire inst_TNE,inst_TNEI;//不等于trap
	//###############################end
	
	//与TLB有关的指令，需要一直传到最后一级
	wire inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR;
	
    wire op_zero;  // 操作码全0
    wire sa_zero;  // sa域全0
    assign op_zero = ~(|op);
    assign sa_zero = ~(|sa);
	
	//####################################7.11
	assign inst_TLBP = (op == 6'b010000) & (rs == 5'b10000) & ~(|rt) & ~(|rd) & sa_zero & (funct == 6'b001000);
	assign inst_TLBR = (op == 6'b010000) & (rs == 5'b10000) & ~(|rt) & ~(|rd) & sa_zero & (funct == 6'b000001);
	assign inst_TLBWI = (op == 6'b010000) & (rs == 5'b10000) & ~(|rt) & ~(|rd) & sa_zero & (funct == 6'b000010);
	assign inst_TLBWR = (op == 6'b010000) & (rs == 5'b10000) & ~(|rt) & ~(|rd) & sa_zero & (funct == 6'b000110);
	assign inst_TEQ = op_zero & (funct == 6'b110100);
	assign inst_TEQI = (op == 6'b000001) & (rt == 5'b01100);
	assign inst_TGE = op_zero & (funct == 6'b110000);
	assign inst_TGEI = (op == 6'b000001) & (rt == 5'b01000);
	assign inst_TGEIU = (op == 6'b000001) & (rt == 5'b01001);
	assign inst_TGEU = op_zero & (funct == 6'b110001);
	assign inst_TLT = op_zero & (funct == 6'b110010);
	assign inst_TLTI = (op == 6'b000001) & (rt == 5'b01010);
	assign inst_TLTIU = (op == 6'b000001) & (rt == 5'b01011);
	assign inst_TLTU = op_zero & (funct == 6'b110011);
	assign inst_TNE = op_zero & (funct == 6'b110110);
	assign inst_TNEI = (op == 6'b000001) & (rt == 5'b01110);
	//####################################end
	
	//####################################7.11
	assign inst_CLO = (op == 6'b011100) & sa_zero & (funct == 6'b100001);
	assign inst_CLZ  =  (op == 6'b011100) &  sa_zero & (funct == 6'b100000);
	assign inst_MADD = (op == 6'b011100) & (rd == 5'b00000) & sa_zero & (funct == 6'b000000);//有符号
	assign inst_MADDU = (op == 6'b011100) & (rd == 5'b00000) & sa_zero & (funct == 6'b000001);
	assign inst_MSUB =  (op == 6'b011100) & (rd == 5'b00000) & sa_zero & (funct == 6'b000100);
	assign inst_MSUBU = (op == 6'b011100) & (rd == 5'b00000) & sa_zero & (funct == 6'b000101);//无符号
	assign inst_MUL = (op == 6'b011100) & sa_zero & (funct == 6'b000010);
	assign inst_MOVN = op_zero & (funct == 6'b001011);
	assign inst_MOVZ = op_zero & (funct == 6'b001010);
	//####################################end
	
	//####################################4.19
	assign inst_ADD  = op_zero & sa_zero    & (funct == 6'b100000);//加法
	assign inst_SUB  = op_zero & sa_zero    & (funct == 6'b100010);//减法
	assign inst_DIV  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011010);             //除法
	assign inst_DIVU  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011011);             //无符号除法
	assign inst_MULTU = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011001);             //无符号乘法
	assign inst_ADDI   = (op == 6'b001000);                         //立即数加	
	assign inst_BLTZAL = (op == 6'b000001) & (rt==5'b10000);//小于0调用子程序并保存返回地址
	assign inst_BGEZAL = (op == 6'b000001) & (rt==5'b10001);//大于等于0调用子程序并保存返回地址
	assign inst_BREAK= (op == 6'b000000) & (funct == 6'b001101);//触发断点例外
	assign inst_LH   = (op == 6'b100001); //取半字有符号扩展 
	assign inst_LHU  = (op == 6'b100101); //取半字无符号扩li展 
	assign inst_LWL  = (op == 6'b100010); //非对齐地址取字至寄存器左部 
	assign inst_LWR  = (op == 6'b100110); //非对齐地址取字至寄存器右部 
	assign inst_SH   = (op == 6'b101001);//存半字 
	assign inst_SWL   = (op == 6'b101010);//寄存器左部存入非对齐地址
	assign inst_SWR   = (op == 6'b101110);//寄存器右部存入非对齐地址 
	//#####################################end
	
    assign inst_ADDU  = op_zero & sa_zero    & (funct == 6'b100001);//无符号加法
    assign inst_SUBU  = op_zero & sa_zero    & (funct == 6'b100011);//无符号减法
    assign inst_SLT   = op_zero & sa_zero    & (funct == 6'b101010);//小于则置位
    assign inst_SLTU  = op_zero & sa_zero    & (funct == 6'b101011);//无符号小则置
    assign inst_JALR  = op_zero & (rt==5'd0) & (rd==5'd31)
                      & sa_zero & (funct == 6'b001001);         //跳转寄存器并链接
    assign inst_JR    = op_zero & (rt==5'd0) & (rd==5'd0 )
                      & sa_zero & (funct == 6'b001000);             //跳转寄存器
    assign inst_AND   = op_zero & sa_zero    & (funct == 6'b100100);//与运算
    assign inst_NOR   = op_zero & sa_zero    & (funct == 6'b100111);//或非运算
    assign inst_OR    = op_zero & sa_zero    & (funct == 6'b100101);//或运算
    assign inst_XOR   = op_zero & sa_zero    & (funct == 6'b100110);//异或运算
    assign inst_SLL   = op_zero & (rs==5'd0) & (funct == 6'b000000);//逻辑左移
    assign inst_SLLV  = op_zero & sa_zero    & (funct == 6'b000100);//变量逻辑左移
    assign inst_SRA   = op_zero & (rs==5'd0) & (funct == 6'b000011);//算术右移
    assign inst_SRAV  = op_zero & sa_zero    & (funct == 6'b000111);//变量算术右移
    assign inst_SRL   = op_zero & (rs==5'd0) & (funct == 6'b000010);//逻辑右移
    assign inst_SRLV  = op_zero & sa_zero    & (funct == 6'b000110);//变量逻辑右移
    assign inst_MULT  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011000);             //乘法
    assign inst_MFLO  = op_zero & (rs==5'd0) & (rt==5'd0)
                      & sa_zero & (funct == 6'b010010);             //从LO读取
    assign inst_MFHI  = op_zero & (rs==5'd0) & (rt==5'd0)
                      & sa_zero & (funct == 6'b010000);             //从HI读取
    assign inst_MTLO  = op_zero & (rt==5'd0) & (rd==5'd0)
                      & sa_zero & (funct == 6'b010011);             //向LO写数据
    assign inst_MTHI  = op_zero & (rt==5'd0) & (rd==5'd0)
                      & sa_zero & (funct == 6'b010001);             //向HI写数据
    assign inst_ADDIU = (op == 6'b001001);             //立即数无符号加法
    assign inst_SLTI  = (op == 6'b001010);             //小于立即数则置位
    assign inst_SLTIU = (op == 6'b001011);             //小于立即数则置位（无符号）
    assign inst_BEQ   = (op == 6'b000100);             //判断相等跳转
    assign inst_BGEZ  = (op == 6'b000001) & (rt==5'd1);//大于等于0跳转
    assign inst_BGTZ  = (op == 6'b000111) & (rt==5'd0);//大于0跳转
    assign inst_BLEZ  = (op == 6'b000110) & (rt==5'd0);//小于等于0跳转
    assign inst_BLTZ  = (op == 6'b000001) & (rt==5'd0);//小于0跳转
    assign inst_BNE   = (op == 6'b000101);             //判断不等跳转
    assign inst_LW    = (op == 6'b100011);             //从内存装载字
    assign inst_SW    = (op == 6'b101011);             //向内存存储字
    assign inst_LB    = (op == 6'b100000);             //load字节（符号扩展）
    assign inst_LBU   = (op == 6'b100100);             //load字节（无符号扩展）
    assign inst_SB    = (op == 6'b101000);             //向内存存储字节
    assign inst_ANDI  = (op == 6'b001100);             //立即数与
    assign inst_LUI   = (op == 6'b001111) & (rs==5'd0);//立即数装载高半字节
    assign inst_ORI   = (op == 6'b001101);             //立即数或
    assign inst_XORI  = (op == 6'b001110);             //立即数异或
    assign inst_J     = (op == 6'b000010);             //跳转
    assign inst_JAL   = (op == 6'b000011);             //跳转和链接
    assign inst_MFC0    = (op == 6'b010000) & (rs==5'd0) 
                        & sa_zero & (funct[5:3] == 3'b000); // 从cp0寄存器装载
    assign inst_MTC0    = (op == 6'b010000) & (rs==5'd4)
                        & sa_zero & (funct[5:3] == 3'b000); // 向cp0寄存器存储
    assign inst_SYSCALL = (op == 6'b000000) & (funct == 6'b001100); // 系统调用
    assign inst_ERET    = (op == 6'b010000) & (rs==5'd16) & (rt==5'd0)
                        & (rd==5'd0) & sa_zero & (funct == 6'b011000);//异常返回
    
	
    //跳转分支指令##############################4.19
    //wire inst_jr;    //寄存器跳转指令
    //wire inst_j_link;//链接跳转指令
    //wire inst_jbr;   //所有分支跳转指令
    //assign inst_jr     = inst_JALR | inst_JR;
    //assign inst_j_link = inst_JAL | inst_JALR;
    //assign inst_jbr = inst_J    | inst_JAL  | inst_jr
    //                | inst_BEQ  | inst_BNE  | inst_BGEZ
    //                | inst_BGTZ | inst_BLEZ | inst_BLTZ;
    
	wire inst_jr;    //寄存器跳转指令
    wire inst_j_link;//链接跳转指令
    wire inst_jbr;   //所有分支跳转指令
    assign inst_jr     = inst_JALR | inst_JR;
    assign inst_j_link = inst_JAL | inst_JALR|inst_BGEZAL|inst_BLTZAL;//增加两条指令
    assign inst_jbr = inst_J    | inst_JAL  | inst_jr
                    | inst_BEQ  | inst_BNE  | inst_BGEZ
                    | inst_BGTZ | inst_BLEZ | inst_BLTZ|inst_BGEZAL|inst_BLTZAL;
	//#########################################end
    
	
    //load store##############################4.19
    //wire inst_load;
    //wire inst_store;
    //assign inst_load  = inst_LW | inst_LB | inst_LBU;  // load指令
    //assign inst_store = inst_SW | inst_SB;             // store指令
	
	wire inst_load;
    wire inst_store;
    assign inst_load  = inst_LW | inst_LB | inst_LBU|inst_LH|inst_LHU|inst_LWL|inst_LWR;  // 增加四条指令
    assign inst_store = inst_SW | inst_SB|inst_SH|inst_SWL|inst_SWR;             // 增加三条指令

	
	wire trap_inst;//trap 信号代表可能会产生trap，将传到exe信号
	wire trap;//trap 信号，直接使用
	//wire [1:0]  trap_judge;//用2位标记，其中00代表相等，01代表大于等于,10代表小于,11代表不等于
	//wire is_unsigned;//传到exe级，按照此来判断最终的结果
	
	wire inst_count;//新加的CLO和CLZ指令的一个信号
	wire inst_madd;//新加的MADD和MADDU指令所需要的一个信号指令
	wire hi_lo_sub;//在exe级的时候，看最后的结果是加还是减（即是否需要取反）
	
	
	wire inst_add, inst_sub, inst_slt,inst_sltu;
    wire inst_and, inst_nor, inst_or, inst_xor;
    wire inst_sll, inst_srl, inst_sra,inst_lui;
	
	assign trap_inst = inst_TEQ | inst_TEQI | inst_TGE | inst_TGEI | inst_TGEIU |inst_TGEU
						| inst_TLT | inst_TLTI | inst_TLTIU | inst_TLTU | inst_TNE | inst_TNEI;

	
	assign hi_lo_sub = inst_MSUB | inst_MSUBU;//最后是相减，故在exe中取出的结果要取反
	assign inst_madd = inst_MADD | inst_MADDU | inst_MSUB | inst_MSUBU;//当这两条指令中有一条触发时，需要将最终得到的hi_result和lo_result在wb级和原来的进行相加（有符号和无符号同时实现）
	assign inst_count = inst_CLO | inst_CLZ;//当CLZ的时候，要记得改变其operand1的值，需要取反
	
    assign inst_add = inst_ADDU | inst_ADDIU | inst_load
                    | inst_store | inst_j_link|inst_ADD|inst_ADDI | inst_MADD | inst_MADDU;            // 增加一条指令
    assign inst_sub = inst_SUBU|inst_SUB | inst_MSUB | inst_MSUBU;                           // 增加一条指令
    assign inst_slt = inst_SLT | inst_SLTI;                // 有符号小于置位
    assign inst_sltu= inst_SLTIU | inst_SLTU;              // 无符号小于置位
    assign inst_and = inst_AND | inst_ANDI;                // 逻辑与
	
    assign inst_nor = inst_NOR;                            // 逻辑或非
    assign inst_or  = inst_OR  | inst_ORI;                 // 逻辑或
    assign inst_xor = inst_XOR | inst_XORI;                // 逻辑异或
    assign inst_sll = inst_SLL | inst_SLLV;                // 逻辑左移
    assign inst_srl = inst_SRL | inst_SRLV;                // 逻辑右移
    assign inst_sra = inst_SRA | inst_SRAV;                // 算术右移
    assign inst_lui = inst_LUI;                            // 立即数装载高位
    //#########################################end
	
    //使用sa域作为偏移量的移位指令
    wire inst_shf_sa;
    assign inst_shf_sa =  inst_SLL | inst_SRL | inst_SRA;
			 
	wire inst_imm_zero; //立即数0扩展
    wire inst_imm_sign; //立即数符号扩展
	wire inst_imm;//立即数指令，旁路会用来判断
    assign inst_imm_zero = inst_ANDI  | inst_LUI  | inst_ORI | inst_XORI ;
    assign inst_imm_sign = inst_ADDIU | inst_SLTI | inst_SLTIU
                         | inst_load | inst_store|inst_ADDI | inst_TEQI | inst_TNEI 
						 | inst_TGEI | inst_TGEIU | inst_TLTI | inst_TLTIU;	//增加一条指令		
    assign inst_imm = inst_imm_zero| inst_imm_sign;						 
    //#########################################end
    
				 
    wire inst_wdest_rt;  // 寄存器堆写入地址为rt的指令
    wire inst_wdest_31;  // 寄存器堆写入地址为31的指令
    wire inst_wdest_rd;  // 寄存器堆写入地址为rd的指令
    assign inst_wdest_rt = inst_imm_zero | inst_ADDIU | inst_SLTI | inst_LUI
                         | inst_SLTIU | inst_load | inst_MFC0|inst_ADDI;//增加一条指令
						 
    assign inst_wdest_31 = inst_JAL|inst_BGEZAL|inst_BLTZAL;//增加两条指令
    assign inst_wdest_rd = inst_ADDU | inst_SUBU | inst_SLT  | inst_SLTU
                         | inst_JALR | inst_AND  | inst_NOR  | inst_OR 
                            | inst_XOR  | inst_SLL  | inst_SLLV | inst_SRA 
                         | inst_SRAV | inst_SRL  | inst_SRLV
                         | inst_MFHI | inst_MFLO|inst_ADD|inst_SUB
						 | inst_CLO | inst_CLZ | inst_MUL | mov_w_rd  ;//增加两条指令
	//#########################################end

	wire inst_no_rs;  //指令rs域非0，且不是从寄存器堆读rs的数据
    wire inst_no_rt;  //指令rt域非0，且不是从寄存器堆读rt的数据
    assign inst_no_rs = inst_MTC0 | inst_SYSCALL | inst_ERET|inst_BREAK
									| inst_TLBP |  inst_TLBR | inst_TLBWI | inst_TLBWR;//增加一条指令
    assign inst_no_rt = inst_ADDIU | inst_SLTI | inst_SLTIU
                      | inst_BGEZ  | inst_load | inst_imm_zero
                      | inst_J     | inst_JAL  | inst_MFC0
                      | inst_SYSCALL|inst_ADDI|inst_BREAK|inst_BGEZAL|inst_BLTZAL
					  | inst_TLTI | inst_TLTIU | inst_TNEI | inst_TGEIU | inst_TGEI | inst_TEQI;	//增加四条指令			  
	//#########################################end				  
//-----{指令译码}end

//rs ,rt 可读信号
    wire inst_rt_is_rdest;
    wire inst_rs_is_rdest;
    //wire inst_rt_is_wdest;
    assign inst_rt_is_rdest = inst_ADD | inst_ADDU | inst_SUB | inst_SUBU
                            | inst_SLT |inst_SLTU | inst_DIV | inst_DIVU 
                            | inst_MULT | inst_MULTU | inst_AND | inst_NOR
                            | inst_OR | inst_XOR | inst_SLLV | inst_SLL
                            | inst_SRAV | inst_SRA | inst_SRLV | inst_SRL
                            | inst_BEQ | inst_BNE | inst_store | inst_LWL
                            | inst_LWR | inst_MTC0 | inst_MUL | inst_MADD | inst_MADDU
							| inst_MSUB | inst_MSUBU | inst_MOVN | inst_MOVZ
							| inst_TEQ | inst_TGE | inst_TGEU | inst_TLT | inst_TLTU | inst_TNE;
    assign inst_rs_is_rdest = inst_ADD | inst_ADDI | inst_ADDU | inst_ADDIU | inst_SUB
                            | inst_SUBU | inst_SLT | inst_SLTI | inst_SLTU
                            | inst_SLTIU | inst_DIV | inst_DIVU | inst_MULT
                            | inst_MULTU | inst_AND | inst_ANDI | inst_NOR
                            | inst_OR | inst_ORI | inst_XOR | inst_XORI
                            | inst_SLLV | inst_SRAV | inst_BEQ | inst_BNE | inst_SRLV
                            | inst_BGEZ | inst_BGTZ | inst_BLEZ | inst_BLTZ
                            | inst_BGEZAL | inst_BLTZAL | inst_JR |inst_JALR
                            | inst_MTHI | inst_MTLO | inst_load | inst_store
							| inst_MUL | inst_MOVN | inst_MOVZ | inst_MADD | inst_MADDU
							| inst_CLO | inst_CLZ | inst_MSUB | inst_MSUBU | trap_inst;
//-----{分支指令执行}begin
   //bd_pc,分支跳转指令参与计算的为延迟槽指令的PC值，即当前分支指令的PC+4
    wire [31:0] bd_pc;   //延迟槽指令PC值
    assign bd_pc = pc + 3'b100;
    
    //无条件跳转
    wire        j_taken;
    wire [31:0] j_target;
    assign j_taken = inst_J | inst_JAL | inst_jr;
    //寄存器跳转地址为rs_value,其他跳转为{bd_pc[31:28],target,2'b00}
    assign j_target = inst_jr ? new_rs_value : {bd_pc[31:28],target,2'b00};


	
	assign trap = (inst_TEQ | inst_TEQI) & alu1_equal_alu2
						| (inst_TGE | inst_TGEI) & ~alu1_less_alu2
						| (inst_TGEIU | inst_TGEU) & ~less_unsigned
						| (inst_TLT | inst_TLTI) & alu1_less_alu2
						| (inst_TLTIU | inst_TLTU) & less_unsigned
						| (inst_TNE | inst_TNEI) & ~alu1_equal_alu2;
	
	wire less_unsigned;
	assign less_unsigned = alu_operand1 < alu_operand2;
	wire alu1_less_alu2;
	wire [31:0] sub_result;
	wire sub_cout;
	assign {sub_cout , sub_result} = alu_operand1 + ~alu_operand2 +1;
	assign alu1_less_alu2 = (alu_operand1[31] & ~alu_operand2[31]) | (~(alu_operand1[31]^alu_operand2) & sub_result[31]);
	wire alu1_equal_alu2;
	assign alu1_equal_alu2 = (alu_operand1 == alu_operand2);
	
	
	wire rs_equql_rt;
    wire rs_ez;
    wire rs_ltz;
    assign rs_equql_rt = (new_rs_value == new_rt_value);  // GPR[rs]==GPR[rt]
    assign rs_ez       = ~(|new_rs_value);            // rs寄存器值为0
    assign rs_ltz      = new_rs_value[31];            // rs寄存器值小于0
    wire br_taken;//是否进行跳转，在这里实际上实现的是提前的指令跳转
    wire [31:0] br_target;
    assign br_taken = inst_BEQ  & rs_equql_rt       // 相等跳转
                    | inst_BNE  & ~rs_equql_rt      // 不等跳转
                    | inst_BGEZ & ~rs_ltz           // 大于等于0跳转
                    | inst_BGTZ & ~rs_ltz & ~rs_ez  // 大于0跳转
                    | inst_BLEZ & (rs_ltz | rs_ez)  // 小于等于0跳转
                    | inst_BLTZ & rs_ltz          // 小于0跳转
					| inst_BLTZAL&rs_ltz			//小于0调用子程序并保存返回地址
					| inst_BGEZAL&~rs_ltz;			//大于等于0调用子程序并保存返回地址
	//#########################################end	
	
	wire mov_w_rd;
	
	assign mov_w_rd = ((inst_MOVN)&~(new_rt_value==32'd0))|((inst_MOVZ)&(new_rt_value==32'd0));
	
    // 分支跳转目标地址：PC=PC+offset<<2
    assign br_target[31:2] = bd_pc[31:2] + {{14{offset[15]}}, offset};  
    assign br_target[1:0]  = bd_pc[1:0];
    
    //jump and branch指令
    wire jbr_taken;
    wire [31:0] jbr_target;
    assign jbr_taken = (j_taken | br_taken) & ID_over; 
    assign jbr_target = j_taken ? j_target : br_target;
    
    //ID到IF的跳转总线
    assign jbr_bus = {jbr_taken, jbr_target};
//-----{分支指令执行}end

    

    wire rs_wait;
    wire rt_wait;
    
    assign rs_wait = ~inst_no_rs & inst_rs_is_rdest & (rs!=5'd0) & ((rs==EXE_wdest) | (rs==MEM_wdest) | (rs==WB_wdest));
	assign rt_wait = ~inst_no_rt & inst_rt_is_rdest & (rt!=5'd0) & ((rt==EXE_wdest) | (rt==MEM_wdest) | (rt==WB_wdest));				 
	
	
					 
	assign new_rs_value = (rs_wait & ((rs==EXE_wdest)&EXE_bypass_en & EXE_over)) ?  EXE_rs_value
	                       :(rs_wait & ((rs==MEM_wdest)&MEM_bypass_en & MEM_over)) ? MEM_rs_value : rs_value;  
					 
	assign new_rt_value = (rt_wait & ((rt==EXE_wdest) &EXE_bypass_en& EXE_over)) ?  EXE_rs_value
	                       :(rt_wait &((rt==MEM_wdest)&MEM_bypass_en & MEM_over)) ? MEM_rs_value : rt_value;  
    //对于分支跳转指令，只有在IF执行完成后，才可以算ID完成；
    //否则，ID级先完成了，而IF还在取指令，则next_pc不能锁存到PC里去，
    //那么等IF完成，next_pc能锁存到PC里去时，jbr_bus上的数据已变成无效，
    //导致分支跳转失败
	assign ID_over = ID_valid 
	               & (~rs_wait | ((rs==EXE_wdest)& EXE_bypass_en & EXE_over) | ((rs==MEM_wdest)&MEM_bypass_en & MEM_over)) 
	               & (~rt_wait | ((rt==EXE_wdest)& EXE_bypass_en & EXE_over) | ((rt==MEM_wdest)&MEM_bypass_en & MEM_over))
	               & (~inst_jbr | IF_over);
//-----{ID执行完成}end

//-----{ID->EXE总线}begin
    //EXE需要用到的信息
	
    wire multiply;         //乘法
    wire mthi;             //MTHI
    wire mtlo;             //MTLO
	wire mult_sign;        //判断是有符号还是无符号乘法，0代表无符号，1代表有符号#########4.22
    assign multiply = inst_MULT| inst_MULTU | inst_madd | inst_MUL;//新增一条
    assign mthi     = inst_MTHI;
    assign mtlo     = inst_MTLO;
	assign mult_sign=inst_MULT| inst_MADD | inst_MSUB | inst_MUL ?1'b1:1'b0;//###########################4.22有符号为1，无符号为0
	
	wire divide;			//除法################4.22
	wire divide_sign;
	assign divide=inst_DIV|inst_DIVU;
	assign divide_sign=inst_DIV?1'b1:1'b0;//有符号为1，无符号为0
	
	
    //ALU两个源操作数和控制信号
    wire [12:0] alu_control;
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;

    
    //所谓链接跳转是将跳转返回的PC值存放到31号寄存器里
    //在流水CPU里，考虑延迟槽，故链接跳转需要计算PC+8，存放到31号寄存器里


    assign alu_operand1 = inst_j_link ? pc : 
                          inst_shf_sa ? {27'd0,sa} : 
						  inst_CLZ ? ~new_rs_value : new_rs_value;
    assign alu_operand2 = inst_j_link ? 32'd8 :  
                          inst_imm_zero ? {16'd0, imm} :
                          inst_imm_sign ?  {{16{imm[15]}}, imm} : new_rt_value;

    assign alu_control = {inst_count,
						  inst_add,        // ALU操作码，独热编码
                          inst_sub,
                          inst_slt,
                          inst_sltu,
                          inst_and,
                          inst_nor,
                          inst_or, 
                          inst_xor,
                          inst_sll,
                          inst_srl,
                          inst_sra,
                          inst_lui};
               
						  
	wire lb_sign;  //load一字节为有符号load
    //wire ls_word;  //load/store为字节还是字,0:byte;1:word
	wire lh_sign;
	wire sw,sh,sb,swl,swr;
	wire lb,lh,lwl,lwr,lw;
    wire [13:0] mem_control;  //MEM需要使用的控制信号
    wire [31:0] store_data;  //store操作的存的数据
    assign lb_sign = inst_LB;
	assign lh_sign=inst_LH;
	assign sw=inst_SW;
	assign sh=inst_SH;
	assign sb=inst_SB;
	assign swr=inst_SWR;
	assign swl=inst_SWL;
	assign lb=inst_LB|inst_LBU;
	assign lh=inst_LH|inst_LHU;
	assign lwl=inst_LWL;
	assign lwr=inst_LWR;
	assign lw=inst_LW;
    //assign ls_word = inst_LW | inst_SW|inst_LWL|inst_LWR|inst_SWL|inst_SWR;
    assign mem_control = {inst_load,
                          inst_store,
                          //ls_word,
						  sw,
						  sh,
						  sb,
						  swl,
						  swr,
						  lb,
						  lh,
						  lw,
						  lwl,
						  lwr,
                          lb_sign, 
						  lh_sign};
	//##############################end
    
	//是否可以发生溢出
	wire ov_en;
	assign ov_en=inst_ADD | inst_ADDI | inst_SUB;
	wire ri;//
	
    //写回需要用到的信息
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall和eret在写回级有特殊的操作 
    wire       eret;
	wire	   Break;//##################4.22
    wire       rf_wen;    //写回的寄存器写使能
    wire [4:0] rf_wdest;  //写回的目的寄存器
    wire data_related_en;
    
    assign syscall  = inst_SYSCALL;//当为SYSCALL时，进行触发
    assign eret     = inst_ERET;
	assign Break=inst_BREAK;//############################4.22
    assign mfhi     = inst_MFHI;
    assign mflo     = inst_MFLO;
    assign mtc0     = inst_MTC0;
    assign mfc0     = inst_MFC0;
    assign cp0r_addr= {rd,cp0r_sel};
    assign rf_wen   = inst_wdest_rt | inst_wdest_31 | inst_wdest_rd;
    assign rf_wdest = inst_wdest_rt ? rt :     //在不写寄存器堆时设置为0
                      inst_wdest_31 ? 5'd31 :  //以便能准确判断数据相关
                      inst_wdest_rd ? rd : 5'd0;
    assign store_data = new_rt_value;
	
	//非指令
	assign ri = ~(inst_add | inst_sub | inst_slt | inst_sltu
                  | inst_and | inst_nor | inst_or  | inst_xor 
                  | inst_sll | inst_srl | inst_sra | inst_lui
                  | multiply | divide
                  | inst_load | inst_store | inst_jbr 
                  | mthi | mtlo | mfhi | mflo | mtc0 | mfc0 
                  | syscall | eret | Break | trap_inst | inst_madd | inst_count | inst_MUL | inst_MOVN | inst_MOVZ
				  | inst_TLBP | inst_TLBR | inst_TLBWI | inst_TLBWR);
	
    assign data_related_en = (((alu_control!=13'd0) | (inst_MULT | inst_MULTU | inst_DIV | inst_DIVU)) & (!inst_load)) ? 1'b1 : 1'b0;
    assign ID_EXE_bus = {multiply,mthi,mtlo,mult_sign, mov_w_rd,                  //EXE需用的信息,新增###############4.22 mult_sign
						 divide,divide_sign,//##########################4.22除法
                         alu_control,alu_operand1,alu_operand2,hi_lo_sub,trap,//EXE需用的信息
                         data_related_en,
                         mem_control,store_data,               //MEM需用的信号
                         mfhi,mflo,                            //WB需用的信号,新增
                         mtc0,mfc0,cp0r_addr,syscall,eret,Break,    //WB需用的信号,新增###################4.22
						 addr_exc,ri,ov_en,is_ds,
                         inst_madd,rf_wen, rf_wdest,                     //WB需用的信号
						 inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,//传到cp0寄存器控制TLB
						 tlb_fetch_exc,//传到cp0 和WB进行异常处理
                         pc};                                  //PC值
//-----{ID->EXE总线}end

//-----{展示ID模块的PC值}begin
    assign ID_pc = pc;
//-----{展示ID模块的PC值}end
endmodule
