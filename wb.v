`timescale 1ns / 1ps

`define EXC_ENTER_ADDR 32'hBFC00380     // Excption��ڵ�ַ��
`define fefill_ENTER_ADDR   32'hbfc00200      //TLB refill ��ڵ�ַ
                                 // �˴�ʵ�ֵ�Exceptionֻ��SYSCALL
module wb(                       // д�ؼ�
    input          WB_valid,     // д�ؼ���Ч
    input  [168:0] MEM_WB_bus_r, // MEM->WB����
	input  [67:0] CP0_WB_bus_r,
    output  [  3:0] rf_wen,       // �Ĵ���дʹ��###########5.7
    output [  4:0] rf_wdest,     // �Ĵ���д��ַ
    output [ 31:0] rf_wdata,     // �Ĵ���д����
    output         WB_over,      // WBģ��ִ�����

     //5����ˮ�����ӿ�
    input             clk,       // ʱ��
    input             resetn,    // ��λ�źţ��͵�ƽ��Ч
    output [ 32:0] exc_bus,      // Exception pc����
	//output [118:0] WB_CP0_bus,
    output [  4:0] WB_wdest,     // WB��Ҫд�ؼĴ����ѵ�Ŀ���ַ��
    output         cancel,       // syscall��eret����д�ؼ�ʱ�ᷢ��cancel�źţ�
                                  // ȡ���Ѿ�ȡ��������������ˮ��ִ�е�ָ��
 
     //չʾPC��HI/LOֵ
     output [ 31:0] WB_pc,
     output [ 31:0] HI_data,
     output [ 31:0] LO_data
);
//-----{MEM->WB����}begin    

    //MEM������result
    wire [31:0] mem_result;
    //HI/LO����
    wire [31:0] hi_result;
    wire        hi_write;
    wire        lo_write;
    
	wire inst_madd;//ʵ�ֵ�MADD��MADDUָ������Ҫ�Ľ���������
	
    //�Ĵ�����дʹ�ܺ�д��ַ
    wire wen;
    wire [4:0] wdest;
    
    //д����Ҫ�õ�����Ϣ
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall��eret��д�ؼ�������Ĳ��� 
    wire       eret;
    wire       Break;//###################4.24
	wire trap;
	wire [1:0] addr_exc;
	wire ri;
	wire ov_exc;
	wire is_ds;
	wire [31:0] badvaddr;
	wire inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR;
	wire tlb_fetch_refill,tlb_fetch_invalid,tlb_fetch_modified;
	wire tlb_mem_refill,tlb_mem_invalid,tlb_mem_modified;
	wire inst_store;
    //pc
    wire [31:0] pc;    
    assign {inst_madd,
			wen,
            wdest,
            hi_result,
            mem_result,
            hi_write,
            lo_write,
            mfhi,
            mflo,
            mtc0,
            mfc0,
            cp0r_addr,
            syscall,
            eret,
			Break,//##########################4.24
			trap,
			addr_exc,ri,ov_exc,is_ds,badvaddr,
			tlb_fetch_refill,tlb_fetch_invalid,tlb_fetch_modified,
			tlb_mem_refill,tlb_mem_invalid,tlb_mem_modified,inst_store,
			inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,
            pc} = MEM_WB_bus_r;
//-----{MEM->WB����}end

	wire exc_happened;
	wire int_happened;
	wire[31:0] cp0r_rdata;
	wire[31:0] cp0r_epc;
	wire        exc_valid;
	wire        CP0_over;
	//wire tlb_inst_over;//��ʾ��tlb�йص�ָ���tlb �Ĳ�������
	assign {exc_happened,
				int_happened,
				exc_valid,
				cp0r_rdata,
				cp0r_epc,
				CP0_over} = CP0_WB_bus_r;

//madd
wire [63:0] hi_lo;
wire [64:0] madd_result;
wire adder64_cout;
assign hi_lo = {hi,lo};
adder64 adder64_module(
	.operand1({hi_lo[63],hi_lo}),
	.operand2({hi_result[31],hi_result,mem_result}),
	.cin(1'b0),
	.result(madd_result),
	.cout(adder64_cout)
);

//

//-----{HI/LO�Ĵ���}begin
    //HI���ڴ�ų˷�����ĸ�32λ
    //LO���ڴ�ų˷�����ĵ�32λ
    reg [31:0] hi;
    reg [31:0] lo;
    
    //Ҫд��HI�����ݴ����mem_result��
    always @(posedge clk)
    begin
        if (hi_write)
        begin
            hi <= hi_result;
        end
		else if(inst_madd)
		begin
			hi <= madd_result[63:32];
		end
    end
    //Ҫд��LO�����ݴ����lo_result��
    always @(posedge clk)
    begin
        if (lo_write)
        begin
            lo <= mem_result;
        end
		else if(inst_madd)
		begin
			lo <= madd_result[31:0];
		end
    end
//-----{HI/LO�Ĵ���}end

//-----{cp0�Ĵ���}begin
// cp0�Ĵ�������Э������0�Ĵ���
// ����Ŀǰ��Ƶ�CPU�����걸�����õ���cp0�Ĵ���Ҳ����
// ����ʱֻʵ��STATUS(12.0),CAUSE(13.0),EPC(14.0)������
// ÿ��CP0�Ĵ�������ʹ��5λ��cp0��

//������ҪǨ�Ƶ�linux ϵͳ�У������Ҫ���CP0�Ĵ��������ﰴ�� MIPS32 �������й���CP0�Ĵ�����˵��������ӣ�����Ҫ��Ĺ��Ϊsel=0
/*0   index : TLB ���е��������  1  ramdom ����TLB���е�����������  2 EntryLo0 ż������ҳ����ڵ�ַ�ĵ�λ����  3  EntryLo1  ��������ҳ����ڵ�ַ�ĵ�λ����	
4 Context ָ���ڴ�����ҳ����ڵ�ַ��ָ��	  5  PageMask  ����TLB����пɱ�ҳ��Ĵ�С	6 Wired   ���ƹ̶���TLB��ڵ���Ŀ	
7 HWREna  Enables access via the RDHWR instruction to selected hardware registers  8 BadVAddr : ��¼���һ�ε�ַ����쳣�ĵ�ַ	 9 count : ��������������	
10 EntryHi  TLB��ڵ�ַ�ĸ�λ����	(0-6 �Լ�10�żĴ�������TLB,MMU�йأ�  11 Compare   ��ʱ�жϿ���	  12 Status   ������״̬�Ϳ��ƼĴ���	
13 Cause  ������һ���쳣ԭ��	  14 EPC	  ������һ���쳣ʱ�ĳ��������	 15 PRId  ��������־�Ͱ汾	
16 Config  ���üĴ�������������CPU�Ĳ���	 17  LLAddr  ��������ָ��Ҫ���ص����ݴ洢����ַ	 18 WatchLo  �۲��watchpoint��ַ�ĵ�λ����	
19 WatchHi	 �۲��watchpoint��ַ�ĸ�λ����	20-22λ����      23 Debug : ���Կ��ƺ��쳣״��  24 DEPC : ��һ�ε����쳣�ĳ��������	
25 PerfCnt    Performance counter interface   26 ErrCtl  ����Cacheָ��������ݺ�SPRAM	27 CacheErr  Cache parity error control and status
28 TagLo  Low-order portion of cache tag interface   29  TagHi   High-order portion of cache tag interface   30 ErrorEPC ��һ��ϵͳ����ʱ�ĳ��������	
31 DESAVE  ��һ��ϵͳ����ʱ�ĳ��������	

*/



   //syscall��eret������cancel�ź�
    assign cancel = exc_valid & WB_valid;//###################4.24
//-----{cp0�Ĵ���}begin

//-----{WBִ�����}begin
    //WBģ�����в���������һ�������
    //��WB_valid����WB_over�ź�
    //assign WB_over = (inst_TLBP | inst_TLBR | inst_TLBWI | inst_TLBWR) ? tlb_inst_over & WB_valid : WB_valid; 
	assign WB_over = CP0_over & WB_valid;
//-----{WBִ�����}end

//-----{WB->regfile�ź�}begin
    assign rf_wen   = {4{wen & WB_over&~exc_happened}};//###########5.7
    assign rf_wdest = wdest;
    assign rf_wdata = mfhi ?  hi:
                      mflo ? lo :
                      mfc0 ? cp0r_rdata : mem_result;
//-----{WB->regfile�ź�}end

//-----{Exception pc�ź�}begin
/* 	assign WB_CP0_bus = {cp0r_addr , badvaddr , mem_result ,WB_valid,
										    syscall , Break , trap , addr_exc , ov_exc , ri ,mtc0,eret,is_ds,
											inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,pc}; */
    //assign exc_valid = (syscall| Break | eret) & WB_valid;//###############4.24
    //eret���ص�ַΪEPC�Ĵ�����ֵ
    //SYSCALL��excPCӦ��Ϊ{EBASE[31:10],10'h180},
    //����Ϊʵ�飬������EXC_ENTER_ADDRΪ0��������Գ���ı�д
    //assign exc_pc = (syscall|Break) ? `EXC_ENTER_ADDR : cp0r_epc;//????????????????????????????????4.24 BREAKָ���pc?
    wire [31:0] exc_pc;
	assign exc_pc =(tlb_fetch_refill | tlb_mem_refill) ? `fefill_ENTER_ADDR :  (exc_happened | int_happened) ? `EXC_ENTER_ADDR : cp0r_epc;
    assign exc_bus = {exc_valid & WB_valid,exc_pc};
//-----{Exception pc�ź�}end

//-----{WBģ���destֵ}begin
   //ֻ����WBģ����Чʱ����д��Ŀ�ļĴ����Ų�������
    assign WB_wdest = rf_wdest & {5{WB_valid}};
//-----{WBģ���destֵ}end

//-----{չʾWBģ���PCֵ��HI/LO�Ĵ�����ֵ}begin
    assign WB_pc = pc;
    assign HI_data = hi;
    assign LO_data = lo;
//-----{չʾWBģ���PCֵ��HI/LO�Ĵ�����ֵ}end
endmodule



