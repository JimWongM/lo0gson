`timescale 1ns / 1ps

`define EXC_ENTER_ADDR 32'hBFC00380     // Excption入口地址，
`define fefill_ENTER_ADDR   32'hbfc00200      //TLB refill 入口地址
                                 // 此处实现的Exception只有SYSCALL
module wb(                       // 写回级
    input          WB_valid,     // 写回级有效
    input  [168:0] MEM_WB_bus_r, // MEM->WB总线
	input  [67:0] CP0_WB_bus_r,
    output  [  3:0] rf_wen,       // 寄存器写使能###########5.7
    output [  4:0] rf_wdest,     // 寄存器写地址
    output [ 31:0] rf_wdata,     // 寄存器写数据
    output         WB_over,      // WB模块执行完成

     //5级流水新增接口
    input             clk,       // 时钟
    input             resetn,    // 复位信号，低电平有效
    output [ 32:0] exc_bus,      // Exception pc总线
	//output [118:0] WB_CP0_bus,
    output [  4:0] WB_wdest,     // WB级要写回寄存器堆的目标地址号
    output         cancel,       // syscall和eret到达写回级时会发出cancel信号，
                                  // 取消已经取出的正在其他流水级执行的指令
 
     //展示PC和HI/LO值
     output [ 31:0] WB_pc,
     output [ 31:0] HI_data,
     output [ 31:0] LO_data
);
//-----{MEM->WB总线}begin    

    //MEM传来的result
    wire [31:0] mem_result;
    //HI/LO数据
    wire [31:0] hi_result;
    wire        hi_write;
    wire        lo_write;
    
	wire inst_madd;//实现的MADD和MADDU指令所需要的结果，即相加
	
    //寄存器堆写使能和写地址
    wire wen;
    wire [4:0] wdest;
    
    //写回需要用到的信息
    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   //syscall和eret在写回级有特殊的操作 
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
//-----{MEM->WB总线}end

	wire exc_happened;
	wire int_happened;
	wire[31:0] cp0r_rdata;
	wire[31:0] cp0r_epc;
	wire        exc_valid;
	wire        CP0_over;
	//wire tlb_inst_over;//表示与tlb有关的指令对tlb 的操作结束
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

//-----{HI/LO寄存器}begin
    //HI用于存放乘法结果的高32位
    //LO用于存放乘法结果的低32位
    reg [31:0] hi;
    reg [31:0] lo;
    
    //要写入HI的数据存放在mem_result里
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
    //要写入LO的数据存放在lo_result里
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
//-----{HI/LO寄存器}end

//-----{cp0寄存器}begin
// cp0寄存器即是协处理器0寄存器
// 由于目前设计的CPU并不完备，所用到的cp0寄存器也很少
// 故暂时只实现STATUS(12.0),CAUSE(13.0),EPC(14.0)这三个
// 每个CP0寄存器都是使用5位的cp0号

//由于需要迁移到linux 系统中，因此需要添加CP0寄存器，这里按照 MIPS32 第三卷中关于CP0寄存器的说明进行添加，其中要求的规格为sel=0
/*0   index : TLB 阵列的入口索引  1  ramdom 产生TLB阵列的随机入口索引  2 EntryLo0 偶数虚拟页的入口地址的低位部分  3  EntryLo1  奇数虚拟页的入口地址的低位部分	
4 Context 指向内存虚拟页表入口地址的指针	  5  PageMask  控制TLB入口中可变页面的大小	6 Wired   控制固定的TLB入口的数目	
7 HWREna  Enables access via the RDHWR instruction to selected hardware registers  8 BadVAddr : 记录最近一次地址相关异常的地址	 9 count : 处理器记数周期	
10 EntryHi  TLB入口地址的高位部分	(0-6 以及10号寄存器都与TLB,MMU有关）  11 Compare   定时中断控制	  12 Status   处理器状态和控制寄存器	
13 Cause  保存上一次异常原因	  14 EPC	  保存上一次异常时的程序计数器	 15 PRId  处理器标志和版本	
16 Config  配置寄存器，用来设置CPU的参数	 17  LLAddr  加载链接指令要加载的数据存储器地址	 18 WatchLo  观测点watchpoint地址的低位部分	
19 WatchHi	 观测点watchpoint地址的高位部分	20-22位保留      23 Debug : 调试控制和异常状况  24 DEPC : 上一次调试异常的程序计数器	
25 PerfCnt    Performance counter interface   26 ErrCtl  控制Cache指令访问数据和SPRAM	27 CacheErr  Cache parity error control and status
28 TagLo  Low-order portion of cache tag interface   29  TagHi   High-order portion of cache tag interface   30 ErrorEPC 上一次系统错误时的程序计数器	
31 DESAVE  上一次系统错误时的程序计数器	

*/



   //syscall和eret发出的cancel信号
    assign cancel = exc_valid & WB_valid;//###################4.24
//-----{cp0寄存器}begin

//-----{WB执行完成}begin
    //WB模块所有操作都可在一拍内完成
    //故WB_valid即是WB_over信号
    //assign WB_over = (inst_TLBP | inst_TLBR | inst_TLBWI | inst_TLBWR) ? tlb_inst_over & WB_valid : WB_valid; 
	assign WB_over = CP0_over & WB_valid;
//-----{WB执行完成}end

//-----{WB->regfile信号}begin
    assign rf_wen   = {4{wen & WB_over&~exc_happened}};//###########5.7
    assign rf_wdest = wdest;
    assign rf_wdata = mfhi ?  hi:
                      mflo ? lo :
                      mfc0 ? cp0r_rdata : mem_result;
//-----{WB->regfile信号}end

//-----{Exception pc信号}begin
/* 	assign WB_CP0_bus = {cp0r_addr , badvaddr , mem_result ,WB_valid,
										    syscall , Break , trap , addr_exc , ov_exc , ri ,mtc0,eret,is_ds,
											inst_TLBR,inst_TLBWI,inst_TLBP,inst_TLBWR,pc}; */
    //assign exc_valid = (syscall| Break | eret) & WB_valid;//###############4.24
    //eret返回地址为EPC寄存器的值
    //SYSCALL的excPC应该为{EBASE[31:10],10'h180},
    //但作为实验，先设置EXC_ENTER_ADDR为0，方便测试程序的编写
    //assign exc_pc = (syscall|Break) ? `EXC_ENTER_ADDR : cp0r_epc;//????????????????????????????????4.24 BREAK指令的pc?
    wire [31:0] exc_pc;
	assign exc_pc =(tlb_fetch_refill | tlb_mem_refill) ? `fefill_ENTER_ADDR :  (exc_happened | int_happened) ? `EXC_ENTER_ADDR : cp0r_epc;
    assign exc_bus = {exc_valid & WB_valid,exc_pc};
//-----{Exception pc信号}end

//-----{WB模块的dest值}begin
   //只有在WB模块有效时，其写回目的寄存器号才有意义
    assign WB_wdest = rf_wdest & {5{WB_valid}};
//-----{WB模块的dest值}end

//-----{展示WB模块的PC值和HI/LO寄存器的值}begin
    assign WB_pc = pc;
    assign HI_data = hi;
    assign LO_data = lo;
//-----{展示WB模块的PC值和HI/LO寄存器的值}end
endmodule



