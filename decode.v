`timescale 1ns / 1ps

module decode(                      // ���뼶
    input              ID_valid,    // ���뼶��Ч�ź�
    input      [ 68:0] IF_ID_bus_r, // IF->ID����
    input      [ 31:0] rs_value,    // ��һԴ������ֵ
    input      [ 31:0] rt_value,    // �ڶ�Դ������ֵ
    output     [  4:0] rs,          // ��һԴ��������ַ 
    output     [  4:0] rt,          // �ڶ�Դ��������ַ
    output     [ 32:0] jbr_bus,     // ��ת����
    output             inst_jbr,    // ָ��Ϊ��ת��ָ֧��,�弶��ˮ����Ҫ
    output             ID_over,     // IDģ��ִ�����
    output     [197:0] ID_EXE_bus,  // ID->EXE����###################################4.22
    
    //5����ˮ����
     input              IF_over,     //���ڷ�ָ֧���Ҫ���ź�
	 
    input      [  4:0] EXE_wdest,   // EXE��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
    input      [  4:0] MEM_wdest,   // MEM��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
    input      [  4:0] WB_wdest,    // WB��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
    
	//��·�õ����ź�
	input         EXE_over,
	input         MEM_over,
	input	   [ 31:0] EXE_rs_value,    //������EXE/MEM������result��ֵ
    input      [ 31:0] MEM_rs_value,     //������MEM������result��ֵ
    //input 		MemRead ,   //ID/EX.MEMRead�Ƿ���Ч	
    input           EXE_bypass_en,
    input           MEM_bypass_en,
    //չʾPC
    output     [ 31:0] ID_pc
);
//-----{IF->ID����}begin
    wire [31:0] pc;
    wire [31:0] inst;
	wire addr_exc;
	wire [2:0] tlb_fetch_exc;
	 wire is_ds;
    assign {pc, inst,addr_exc, tlb_fetch_exc ,is_ds} = IF_ID_bus_r;  // IF->ID���ߴ�PC��ָ��
//-----{IF->ID����}end


    wire [31:0] new_rs_value;
    wire [31:0] new_rt_value;
//-----{ָ������}begin
    wire [5:0] op;       
    wire [4:0] rd;       
    wire [4:0] sa;      
    wire [5:0] funct;    
    wire [15:0] imm;     
    wire [15:0] offset;  
    wire [25:0] target;  
    wire [2:0] cp0r_sel;

    assign op     = inst[31:26];  // ������
    assign rs     = inst[25:21];  // Դ������1
    assign rt     = inst[20:16];  // Դ������2
    assign rd     = inst[15:11];  // Ŀ�������
    assign sa     = inst[10:6];   // �����򣬿��ܴ��ƫ����
    assign funct  = inst[5:0];    // ������
    assign imm    = inst[15:0];   // ������
    assign offset = inst[15:0];   // ��ַƫ����
    assign target = inst[25:0];   // Ŀ���ַ
    assign cp0r_sel= inst[2:0];   // cp0�Ĵ�����select��

    // ʵ��ָ���б�
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
	
	//������ָ���б�##################################4.19
	wire inst_ADD,inst_SUB,inst_DIV,inst_DIVU;
	wire inst_MULTU,inst_ADDI,inst_BLTZAL,inst_BGEZAL;
	wire inst_BREAK,inst_LH,inst_LHU,inst_LWL;
	wire inst_LWR,inst_SH,inst_SWL,inst_SWR;
	//################################end
	
	
	//������ָ���б�##################################7.11
	wire inst_CLO,inst_CLZ;//CLOΪ��1��������CLZΪ��0������
	wire inst_MADD,inst_MADDU;//(HI,LO) �� (HI,LO) + (GPR[rs] �� GPR[rt]) ������ˣ�������
	wire inst_MSUB,inst_MSUBU;//(HI,LO) �� (HI,LO) - (GPR[rs] �� GPR[rt])
	wire inst_MUL;//�˷�ָ����˷��ĵ�λ�Ľ��������rd�Ĵ����У����ı�hi��lo��ֵ
	wire inst_MOVN,inst_MOVZ;//������ص�MOVָ��ж�rt_value��ѡ���Ƿ񴫵�rs_value��rd
	//###############################end
	
	//������ָ���б�##################################7.15
	wire inst_TEQ,inst_TEQI;//����������ȵ�ʱ��trap
	wire inst_TGE,inst_TGEI,inst_TGEIU,inst_TGEU;//��rs���ڵ���rt(������������trap
	wire inst_TLT,inst_TLTI,inst_TLTIU,inst_TLTU;//ͬ��С��trap
	wire inst_TNE,inst_TNEI;//������trap
	//###############################end
	
	//��TLB�йص�ָ���Ҫһֱ�������һ��
	wire inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR;
	
    wire op_zero;  // ������ȫ0
    wire sa_zero;  // sa��ȫ0
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
	assign inst_MADD = (op == 6'b011100) & (rd == 5'b00000) & sa_zero & (funct == 6'b000000);//�з���
	assign inst_MADDU = (op == 6'b011100) & (rd == 5'b00000) & sa_zero & (funct == 6'b000001);
	assign inst_MSUB =  (op == 6'b011100) & (rd == 5'b00000) & sa_zero & (funct == 6'b000100);
	assign inst_MSUBU = (op == 6'b011100) & (rd == 5'b00000) & sa_zero & (funct == 6'b000101);//�޷���
	assign inst_MUL = (op == 6'b011100) & sa_zero & (funct == 6'b000010);
	assign inst_MOVN = op_zero & (funct == 6'b001011);
	assign inst_MOVZ = op_zero & (funct == 6'b001010);
	//####################################end
	
	//####################################4.19
	assign inst_ADD  = op_zero & sa_zero    & (funct == 6'b100000);//�ӷ�
	assign inst_SUB  = op_zero & sa_zero    & (funct == 6'b100010);//����
	assign inst_DIV  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011010);             //����
	assign inst_DIVU  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011011);             //�޷��ų���
	assign inst_MULTU = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011001);             //�޷��ų˷�
	assign inst_ADDI   = (op == 6'b001000);                         //��������	
	assign inst_BLTZAL = (op == 6'b000001) & (rt==5'b10000);//С��0�����ӳ��򲢱��淵�ص�ַ
	assign inst_BGEZAL = (op == 6'b000001) & (rt==5'b10001);//���ڵ���0�����ӳ��򲢱��淵�ص�ַ
	assign inst_BREAK= (op == 6'b000000) & (funct == 6'b001101);//�����ϵ�����
	assign inst_LH   = (op == 6'b100001); //ȡ�����з�����չ 
	assign inst_LHU  = (op == 6'b100101); //ȡ�����޷�����liչ 
	assign inst_LWL  = (op == 6'b100010); //�Ƕ����ַȡ�����Ĵ����� 
	assign inst_LWR  = (op == 6'b100110); //�Ƕ����ַȡ�����Ĵ����Ҳ� 
	assign inst_SH   = (op == 6'b101001);//����� 
	assign inst_SWL   = (op == 6'b101010);//�Ĵ����󲿴���Ƕ����ַ
	assign inst_SWR   = (op == 6'b101110);//�Ĵ����Ҳ�����Ƕ����ַ 
	//#####################################end
	
    assign inst_ADDU  = op_zero & sa_zero    & (funct == 6'b100001);//�޷��żӷ�
    assign inst_SUBU  = op_zero & sa_zero    & (funct == 6'b100011);//�޷��ż���
    assign inst_SLT   = op_zero & sa_zero    & (funct == 6'b101010);//С������λ
    assign inst_SLTU  = op_zero & sa_zero    & (funct == 6'b101011);//�޷���С����
    assign inst_JALR  = op_zero & (rt==5'd0) & (rd==5'd31)
                      & sa_zero & (funct == 6'b001001);         //��ת�Ĵ���������
    assign inst_JR    = op_zero & (rt==5'd0) & (rd==5'd0 )
                      & sa_zero & (funct == 6'b001000);             //��ת�Ĵ���
    assign inst_AND   = op_zero & sa_zero    & (funct == 6'b100100);//������
    assign inst_NOR   = op_zero & sa_zero    & (funct == 6'b100111);//�������
    assign inst_OR    = op_zero & sa_zero    & (funct == 6'b100101);//������
    assign inst_XOR   = op_zero & sa_zero    & (funct == 6'b100110);//�������
    assign inst_SLL   = op_zero & (rs==5'd0) & (funct == 6'b000000);//�߼�����
    assign inst_SLLV  = op_zero & sa_zero    & (funct == 6'b000100);//�����߼�����
    assign inst_SRA   = op_zero & (rs==5'd0) & (funct == 6'b000011);//��������
    assign inst_SRAV  = op_zero & sa_zero    & (funct == 6'b000111);//������������
    assign inst_SRL   = op_zero & (rs==5'd0) & (funct == 6'b000010);//�߼�����
    assign inst_SRLV  = op_zero & sa_zero    & (funct == 6'b000110);//�����߼�����
    assign inst_MULT  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011000);             //�˷�
    assign inst_MFLO  = op_zero & (rs==5'd0) & (rt==5'd0)
                      & sa_zero & (funct == 6'b010010);             //��LO��ȡ
    assign inst_MFHI  = op_zero & (rs==5'd0) & (rt==5'd0)
                      & sa_zero & (funct == 6'b010000);             //��HI��ȡ
    assign inst_MTLO  = op_zero & (rt==5'd0) & (rd==5'd0)
                      & sa_zero & (funct == 6'b010011);             //��LOд����
    assign inst_MTHI  = op_zero & (rt==5'd0) & (rd==5'd0)
                      & sa_zero & (funct == 6'b010001);             //��HIд����
    assign inst_ADDIU = (op == 6'b001001);             //�������޷��żӷ�
    assign inst_SLTI  = (op == 6'b001010);             //С������������λ
    assign inst_SLTIU = (op == 6'b001011);             //С������������λ���޷��ţ�
    assign inst_BEQ   = (op == 6'b000100);             //�ж������ת
    assign inst_BGEZ  = (op == 6'b000001) & (rt==5'd1);//���ڵ���0��ת
    assign inst_BGTZ  = (op == 6'b000111) & (rt==5'd0);//����0��ת
    assign inst_BLEZ  = (op == 6'b000110) & (rt==5'd0);//С�ڵ���0��ת
    assign inst_BLTZ  = (op == 6'b000001) & (rt==5'd0);//С��0��ת
    assign inst_BNE   = (op == 6'b000101);             //�жϲ�����ת
    assign inst_LW    = (op == 6'b100011);             //���ڴ�װ����
    assign inst_SW    = (op == 6'b101011);             //���ڴ�洢��
    assign inst_LB    = (op == 6'b100000);             //load�ֽڣ�������չ��
    assign inst_LBU   = (op == 6'b100100);             //load�ֽڣ��޷�����չ��
    assign inst_SB    = (op == 6'b101000);             //���ڴ�洢�ֽ�
    assign inst_ANDI  = (op == 6'b001100);             //��������
    assign inst_LUI   = (op == 6'b001111) & (rs==5'd0);//������װ�ظ߰��ֽ�
    assign inst_ORI   = (op == 6'b001101);             //��������
    assign inst_XORI  = (op == 6'b001110);             //���������
    assign inst_J     = (op == 6'b000010);             //��ת
    assign inst_JAL   = (op == 6'b000011);             //��ת������
    assign inst_MFC0    = (op == 6'b010000) & (rs==5'd0) 
                        & sa_zero & (funct[5:3] == 3'b000); // ��cp0�Ĵ���װ��
    assign inst_MTC0    = (op == 6'b010000) & (rs==5'd4)
                        & sa_zero & (funct[5:3] == 3'b000); // ��cp0�Ĵ����洢
    assign inst_SYSCALL = (op == 6'b000000) & (funct == 6'b001100); // ϵͳ����
    assign inst_ERET    = (op == 6'b010000) & (rs==5'd16) & (rt==5'd0)
                        & (rd==5'd0) & sa_zero & (funct == 6'b011000);//�쳣����
    
	
    //��ת��ָ֧��##############################4.19
    //wire inst_jr;    //�Ĵ�����תָ��
    //wire inst_j_link;//������תָ��
    //wire inst_jbr;   //���з�֧��תָ��
    //assign inst_jr     = inst_JALR | inst_JR;
    //assign inst_j_link = inst_JAL | inst_JALR;
    //assign inst_jbr = inst_J    | inst_JAL  | inst_jr
    //                | inst_BEQ  | inst_BNE  | inst_BGEZ
    //                | inst_BGTZ | inst_BLEZ | inst_BLTZ;
    
	wire inst_jr;    //�Ĵ�����תָ��
    wire inst_j_link;//������תָ��
    wire inst_jbr;   //���з�֧��תָ��
    assign inst_jr     = inst_JALR | inst_JR;
    assign inst_j_link = inst_JAL | inst_JALR|inst_BGEZAL|inst_BLTZAL;//��������ָ��
    assign inst_jbr = inst_J    | inst_JAL  | inst_jr
                    | inst_BEQ  | inst_BNE  | inst_BGEZ
                    | inst_BGTZ | inst_BLEZ | inst_BLTZ|inst_BGEZAL|inst_BLTZAL;
	//#########################################end
    
	
    //load store##############################4.19
    //wire inst_load;
    //wire inst_store;
    //assign inst_load  = inst_LW | inst_LB | inst_LBU;  // loadָ��
    //assign inst_store = inst_SW | inst_SB;             // storeָ��
	
	wire inst_load;
    wire inst_store;
    assign inst_load  = inst_LW | inst_LB | inst_LBU|inst_LH|inst_LHU|inst_LWL|inst_LWR;  // ��������ָ��
    assign inst_store = inst_SW | inst_SB|inst_SH|inst_SWL|inst_SWR;             // ��������ָ��

	
	wire trap_inst;//trap �źŴ�����ܻ����trap��������exe�ź�
	wire trap;//trap �źţ�ֱ��ʹ��
	//wire [1:0]  trap_judge;//��2λ��ǣ�����00������ȣ�01������ڵ���,10����С��,11��������
	//wire is_unsigned;//����exe�������մ����ж����յĽ��
	
	wire inst_count;//�¼ӵ�CLO��CLZָ���һ���ź�
	wire inst_madd;//�¼ӵ�MADD��MADDUָ������Ҫ��һ���ź�ָ��
	wire hi_lo_sub;//��exe����ʱ�򣬿����Ľ���Ǽӻ��Ǽ������Ƿ���Ҫȡ����
	
	
	wire inst_add, inst_sub, inst_slt,inst_sltu;
    wire inst_and, inst_nor, inst_or, inst_xor;
    wire inst_sll, inst_srl, inst_sra,inst_lui;
	
	assign trap_inst = inst_TEQ | inst_TEQI | inst_TGE | inst_TGEI | inst_TGEIU |inst_TGEU
						| inst_TLT | inst_TLTI | inst_TLTIU | inst_TLTU | inst_TNE | inst_TNEI;

	
	assign hi_lo_sub = inst_MSUB | inst_MSUBU;//��������������exe��ȡ���Ľ��Ҫȡ��
	assign inst_madd = inst_MADD | inst_MADDU | inst_MSUB | inst_MSUBU;//��������ָ������һ������ʱ����Ҫ�����յõ���hi_result��lo_result��wb����ԭ���Ľ�����ӣ��з��ź��޷���ͬʱʵ�֣�
	assign inst_count = inst_CLO | inst_CLZ;//��CLZ��ʱ��Ҫ�ǵøı���operand1��ֵ����Ҫȡ��
	
    assign inst_add = inst_ADDU | inst_ADDIU | inst_load
                    | inst_store | inst_j_link|inst_ADD|inst_ADDI | inst_MADD | inst_MADDU;            // ����һ��ָ��
    assign inst_sub = inst_SUBU|inst_SUB | inst_MSUB | inst_MSUBU;                           // ����һ��ָ��
    assign inst_slt = inst_SLT | inst_SLTI;                // �з���С����λ
    assign inst_sltu= inst_SLTIU | inst_SLTU;              // �޷���С����λ
    assign inst_and = inst_AND | inst_ANDI;                // �߼���
	
    assign inst_nor = inst_NOR;                            // �߼����
    assign inst_or  = inst_OR  | inst_ORI;                 // �߼���
    assign inst_xor = inst_XOR | inst_XORI;                // �߼����
    assign inst_sll = inst_SLL | inst_SLLV;                // �߼�����
    assign inst_srl = inst_SRL | inst_SRLV;                // �߼�����
    assign inst_sra = inst_SRA | inst_SRAV;                // ��������
    assign inst_lui = inst_LUI;                            // ������װ�ظ�λ
    //#########################################end
	
    //ʹ��sa����Ϊƫ��������λָ��
    wire inst_shf_sa;
    assign inst_shf_sa =  inst_SLL | inst_SRL | inst_SRA;
			 
	wire inst_imm_zero; //������0��չ
    wire inst_imm_sign; //������������չ
	wire inst_imm;//������ָ���·�������ж�
    assign inst_imm_zero = inst_ANDI  | inst_LUI  | inst_ORI | inst_XORI ;
    assign inst_imm_sign = inst_ADDIU | inst_SLTI | inst_SLTIU
                         | inst_load | inst_store|inst_ADDI | inst_TEQI | inst_TNEI 
						 | inst_TGEI | inst_TGEIU | inst_TLTI | inst_TLTIU;	//����һ��ָ��		
    assign inst_imm = inst_imm_zero| inst_imm_sign;						 
    //#########################################end
    
				 
    wire inst_wdest_rt;  // �Ĵ�����д���ַΪrt��ָ��
    wire inst_wdest_31;  // �Ĵ�����д���ַΪ31��ָ��
    wire inst_wdest_rd;  // �Ĵ�����д���ַΪrd��ָ��
    assign inst_wdest_rt = inst_imm_zero | inst_ADDIU | inst_SLTI | inst_LUI
                         | inst_SLTIU | inst_load | inst_MFC0|inst_ADDI;//����һ��ָ��
						 
    assign inst_wdest_31 = inst_JAL|inst_BGEZAL|inst_BLTZAL;//��������ָ��
    assign inst_wdest_rd = inst_ADDU | inst_SUBU | inst_SLT  | inst_SLTU
                         | inst_JALR | inst_AND  | inst_NOR  | inst_OR 
                            | inst_XOR  | inst_SLL  | inst_SLLV | inst_SRA 
                         | inst_SRAV | inst_SRL  | inst_SRLV
                         | inst_MFHI | inst_MFLO|inst_ADD|inst_SUB
						 | inst_CLO | inst_CLZ | inst_MUL | mov_w_rd  ;//��������ָ��
	//#########################################end

	wire inst_no_rs;  //ָ��rs���0���Ҳ��ǴӼĴ����Ѷ�rs������
    wire inst_no_rt;  //ָ��rt���0���Ҳ��ǴӼĴ����Ѷ�rt������
    assign inst_no_rs = inst_MTC0 | inst_SYSCALL | inst_ERET|inst_BREAK
									| inst_TLBP |  inst_TLBR | inst_TLBWI | inst_TLBWR;//����һ��ָ��
    assign inst_no_rt = inst_ADDIU | inst_SLTI | inst_SLTIU
                      | inst_BGEZ  | inst_load | inst_imm_zero
                      | inst_J     | inst_JAL  | inst_MFC0
                      | inst_SYSCALL|inst_ADDI|inst_BREAK|inst_BGEZAL|inst_BLTZAL
					  | inst_TLTI | inst_TLTIU | inst_TNEI | inst_TGEIU | inst_TGEI | inst_TEQI;	//��������ָ��			  
	//#########################################end				  
//-----{ָ������}end

//rs ,rt �ɶ��ź�
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
//-----{��ָ֧��ִ��}begin
   //bd_pc,��֧��תָ���������Ϊ�ӳٲ�ָ���PCֵ������ǰ��ָ֧���PC+4
    wire [31:0] bd_pc;   //�ӳٲ�ָ��PCֵ
    assign bd_pc = pc + 3'b100;
    
    //��������ת
    wire        j_taken;
    wire [31:0] j_target;
    assign j_taken = inst_J | inst_JAL | inst_jr;
    //�Ĵ�����ת��ַΪrs_value,������תΪ{bd_pc[31:28],target,2'b00}
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
    assign rs_ez       = ~(|new_rs_value);            // rs�Ĵ���ֵΪ0
    assign rs_ltz      = new_rs_value[31];            // rs�Ĵ���ֵС��0
    wire br_taken;//�Ƿ������ת��������ʵ����ʵ�ֵ�����ǰ��ָ����ת
    wire [31:0] br_target;
    assign br_taken = inst_BEQ  & rs_equql_rt       // �����ת
                    | inst_BNE  & ~rs_equql_rt      // ������ת
                    | inst_BGEZ & ~rs_ltz           // ���ڵ���0��ת
                    | inst_BGTZ & ~rs_ltz & ~rs_ez  // ����0��ת
                    | inst_BLEZ & (rs_ltz | rs_ez)  // С�ڵ���0��ת
                    | inst_BLTZ & rs_ltz          // С��0��ת
					| inst_BLTZAL&rs_ltz			//С��0�����ӳ��򲢱��淵�ص�ַ
					| inst_BGEZAL&~rs_ltz;			//���ڵ���0�����ӳ��򲢱��淵�ص�ַ
	//#########################################end	
	
	wire mov_w_rd;
	
	assign mov_w_rd = ((inst_MOVN)&~(new_rt_value==32'd0))|((inst_MOVZ)&(new_rt_value==32'd0));
	
    // ��֧��תĿ���ַ��PC=PC+offset<<2
    assign br_target[31:2] = bd_pc[31:2] + {{14{offset[15]}}, offset};  
    assign br_target[1:0]  = bd_pc[1:0];
    
    //jump and branchָ��
    wire jbr_taken;
    wire [31:0] jbr_target;
    assign jbr_taken = (j_taken | br_taken) & ID_over; 
    assign jbr_target = j_taken ? j_target : br_target;
    
    //ID��IF����ת����
    assign jbr_bus = {jbr_taken, jbr_target};
//-----{��ָ֧��ִ��}end

    

    wire rs_wait;
    wire rt_wait;
    
    assign rs_wait = ~inst_no_rs & inst_rs_is_rdest & (rs!=5'd0) & ((rs==EXE_wdest) | (rs==MEM_wdest) | (rs==WB_wdest));
	assign rt_wait = ~inst_no_rt & inst_rt_is_rdest & (rt!=5'd0) & ((rt==EXE_wdest) | (rt==MEM_wdest) | (rt==WB_wdest));				 
	
	
					 
	assign new_rs_value = (rs_wait & ((rs==EXE_wdest)&EXE_bypass_en & EXE_over)) ?  EXE_rs_value
	                       :(rs_wait & ((rs==MEM_wdest)&MEM_bypass_en & MEM_over)) ? MEM_rs_value : rs_value;  
					 
	assign new_rt_value = (rt_wait & ((rt==EXE_wdest) &EXE_bypass_en& EXE_over)) ?  EXE_rs_value
	                       :(rt_wait &((rt==MEM_wdest)&MEM_bypass_en & MEM_over)) ? MEM_rs_value : rt_value;  
    //���ڷ�֧��תָ�ֻ����IFִ����ɺ󣬲ſ�����ID��ɣ�
    //����ID��������ˣ���IF����ȡָ���next_pc�������浽PC��ȥ��
    //��ô��IF��ɣ�next_pc�����浽PC��ȥʱ��jbr_bus�ϵ������ѱ����Ч��
    //���·�֧��תʧ��
	assign ID_over = ID_valid 
	               & (~rs_wait | ((rs==EXE_wdest)& EXE_bypass_en & EXE_over) | ((rs==MEM_wdest)&MEM_bypass_en & MEM_over)) 
	               & (~rt_wait | ((rt==EXE_wdest)& EXE_bypass_en & EXE_over) | ((rt==MEM_wdest)&MEM_bypass_en & MEM_over))
	               & (~inst_jbr | IF_over);
//-----{IDִ�����}end

//-----{ID->EXE����}begin
    //EXE��Ҫ�õ�����Ϣ
	
    wire multiply;         //�˷�
    wire mthi;             //MTHI
    wire mtlo;             //MTLO
	wire mult_sign;        //�ж����з��Ż����޷��ų˷���0�����޷��ţ�1�����з���#########4.22
    assign multiply = inst_MULT| inst_MULTU | inst_madd | inst_MUL;//����һ��
    assign mthi     = inst_MTHI;
    assign mtlo     = inst_MTLO;
	assign mult_sign=inst_MULT| inst_MADD | inst_MSUB | inst_MUL ?1'b1:1'b0;//###########################4.22�з���Ϊ1���޷���Ϊ0
	
	wire divide;			//����################4.22
	wire divide_sign;
	assign divide=inst_DIV|inst_DIVU;
	assign divide_sign=inst_DIV?1'b1:1'b0;//�з���Ϊ1���޷���Ϊ0
	
	
    //ALU����Դ�������Ϳ����ź�
    wire [12:0] alu_control;
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;

    
    //��ν������ת�ǽ���ת���ص�PCֵ��ŵ�31�żĴ�����
    //����ˮCPU������ӳٲۣ���������ת��Ҫ����PC+8����ŵ�31�żĴ�����


    assign alu_operand1 = inst_j_link ? pc : 
                          inst_shf_sa ? {27'd0,sa} : 
						  inst_CLZ ? ~new_rs_value : new_rs_value;
    assign alu_operand2 = inst_j_link ? 32'd8 :  
                          inst_imm_zero ? {16'd0, imm} :
                          inst_imm_sign ?  {{16{imm[15]}}, imm} : new_rt_value;

    assign alu_control = {inst_count,
						  inst_add,        // ALU�����룬���ȱ���
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
               
						  
	wire lb_sign;  //loadһ�ֽ�Ϊ�з���load
    //wire ls_word;  //load/storeΪ�ֽڻ�����,0:byte;1:word
	wire lh_sign;
	wire sw,sh,sb,swl,swr;
	wire lb,lh,lwl,lwr,lw;
    wire [13:0] mem_control;  //MEM��Ҫʹ�õĿ����ź�
    wire [31:0] store_data;  //store�����Ĵ������
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
    
	//�Ƿ���Է������
	wire ov_en;
	assign ov_en=inst_ADD | inst_ADDI | inst_SUB;
	wire ri;//
	
    //д����Ҫ�õ�����Ϣ
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall��eret��д�ؼ�������Ĳ��� 
    wire       eret;
	wire	   Break;//##################4.22
    wire       rf_wen;    //д�صļĴ���дʹ��
    wire [4:0] rf_wdest;  //д�ص�Ŀ�ļĴ���
    wire data_related_en;
    
    assign syscall  = inst_SYSCALL;//��ΪSYSCALLʱ�����д���
    assign eret     = inst_ERET;
	assign Break=inst_BREAK;//############################4.22
    assign mfhi     = inst_MFHI;
    assign mflo     = inst_MFLO;
    assign mtc0     = inst_MTC0;
    assign mfc0     = inst_MFC0;
    assign cp0r_addr= {rd,cp0r_sel};
    assign rf_wen   = inst_wdest_rt | inst_wdest_31 | inst_wdest_rd;
    assign rf_wdest = inst_wdest_rt ? rt :     //�ڲ�д�Ĵ�����ʱ����Ϊ0
                      inst_wdest_31 ? 5'd31 :  //�Ա���׼ȷ�ж��������
                      inst_wdest_rd ? rd : 5'd0;
    assign store_data = new_rt_value;
	
	//��ָ��
	assign ri = ~(inst_add | inst_sub | inst_slt | inst_sltu
                  | inst_and | inst_nor | inst_or  | inst_xor 
                  | inst_sll | inst_srl | inst_sra | inst_lui
                  | multiply | divide
                  | inst_load | inst_store | inst_jbr 
                  | mthi | mtlo | mfhi | mflo | mtc0 | mfc0 
                  | syscall | eret | Break | trap_inst | inst_madd | inst_count | inst_MUL | inst_MOVN | inst_MOVZ
				  | inst_TLBP | inst_TLBR | inst_TLBWI | inst_TLBWR);
	
    assign data_related_en = (((alu_control!=13'd0) | (inst_MULT | inst_MULTU | inst_DIV | inst_DIVU)) & (!inst_load)) ? 1'b1 : 1'b0;
    assign ID_EXE_bus = {multiply,mthi,mtlo,mult_sign, mov_w_rd,                  //EXE���õ���Ϣ,����###############4.22 mult_sign
						 divide,divide_sign,//##########################4.22����
                         alu_control,alu_operand1,alu_operand2,hi_lo_sub,trap,//EXE���õ���Ϣ
                         data_related_en,
                         mem_control,store_data,               //MEM���õ��ź�
                         mfhi,mflo,                            //WB���õ��ź�,����
                         mtc0,mfc0,cp0r_addr,syscall,eret,Break,    //WB���õ��ź�,����###################4.22
						 addr_exc,ri,ov_en,is_ds,
                         inst_madd,rf_wen, rf_wdest,                     //WB���õ��ź�
						 inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,//����cp0�Ĵ�������TLB
						 tlb_fetch_exc,//����cp0 ��WB�����쳣����
                         pc};                                  //PCֵ
//-----{ID->EXE����}end

//-----{չʾIDģ���PCֵ}begin
    assign ID_pc = pc;
//-----{չʾIDģ���PCֵ}end
endmodule
