`timescale 1ns / 1ps
module MainWTree
(
    input         clk,        // 时钟
    input     mwt_begin, //华莱士树步骤�?始信�?
	input [16:0]	Tree1,
    input [16:0]	Tree2,
    input [16:0]	Tree3,
    input [16:0]	Tree4,
    input [16:0]	Tree5,
    input [16:0]	Tree6,
    input [16:0]	Tree7,
    input [16:0]	Tree8,
    input [16:0]	Tree9,
    input [16:0]	Tree10,
    input [16:0]	Tree11,
    input [16:0]	Tree12,
    input [16:0]	Tree13,
    input [16:0]	Tree14,
    input [16:0]	Tree15,
    input [16:0]	Tree16,
    input [16:0]	Tree17,
    input [16:0]	Tree18,
    input [16:0]	Tree19,
    input [16:0]	Tree20,
    input [16:0]	Tree21,
    input [16:0]	Tree22,
    input [16:0]	Tree23,
    input [16:0]	Tree24,
    input [16:0]	Tree25,
    input [16:0]	Tree26,
    input [16:0]	Tree27,
    input [16:0]	Tree28,
    input [16:0]	Tree29,
    input [16:0]	Tree30,
    input [16:0]	Tree31,
    input [16:0]	Tree32,
    input [16:0]	Tree33,
    input [16:0]	Tree34,
    input [16:0]	Tree35,
    input [16:0]	Tree36,
    input [16:0]	Tree37,
    input [16:0]	Tree38,
    input [16:0]	Tree39,
    input [16:0]	Tree40,
    input [16:0]	Tree41,
    input [16:0]	Tree42,
    input [16:0]	Tree43,
    input [16:0]	Tree44,
    input [16:0]	Tree45,
    input [16:0]	Tree46,
    input [16:0]	Tree47,
    input [16:0]	Tree48,
    input [16:0]	Tree49,
    input [16:0]	Tree50,
    input [16:0]	Tree51,
    input [16:0]	Tree52,
    input [16:0]	Tree53,
    input [16:0]	Tree54,
    input [16:0]	Tree55,
    input [16:0]	Tree56,
    input [16:0]	Tree57,
    input [16:0]	Tree58,
    input [16:0]	Tree59,
    input [16:0]	Tree60,
    input [16:0]	Tree61,
    input [16:0]	Tree62,
    input [16:0]	Tree63,
    input [16:0]	Tree64,

	output wire wt_end, //乘法结束信号
	output [0:63] product
	
);
 
	//wire[63:0] wt_begin;
	//assign wt_begin={32{mwt_begin}};
	wire wt_begin;
	assign wt_begin=mwt_begin;
	wire[63:0] subTree_end;
	wire[63:0] Sadder;
	wire[63:0] Cadder;
	wire[13:0]	cin0;
wire[13:0]	cin1;
wire[13:0]	cin2;
wire[13:0]	cin3;
wire[13:0]	cin4;
wire[13:0]	cin5;
wire[13:0]	cin6;
wire[13:0]	cin7;
wire[13:0]	cin8;
wire[13:0]	cin9;
wire[13:0]	cin10;
wire[13:0]	cin11;
wire[13:0]	cin12;
wire[13:0]	cin13;
wire[13:0]	cin14;
wire[13:0]	cin15;
wire[13:0]	cin16;
wire[13:0]	cin17;
wire[13:0]	cin18;
wire[13:0]	cin19;
wire[13:0]	cin20;
wire[13:0]	cin21;
wire[13:0]	cin22;
wire[13:0]	cin23;
wire[13:0]	cin24;
wire[13:0]	cin25;
wire[13:0]	cin26;
wire[13:0]	cin27;
wire[13:0]	cin28;
wire[13:0]	cin29;
wire[13:0]	cin30;
wire[13:0]	cin31;
wire[13:0]	cin32;
wire[13:0]	cin33;
wire[13:0]	cin34;
wire[13:0]	cin35;
wire[13:0]	cin36;
wire[13:0]	cin37;
wire[13:0]	cin38;
wire[13:0]	cin39;
wire[13:0]	cin40;
wire[13:0]	cin41;
wire[13:0]	cin42;
wire[13:0]	cin43;
wire[13:0]	cin44;
wire[13:0]	cin45;
wire[13:0]	cin46;
wire[13:0]	cin47;
wire[13:0]	cin48;
wire[13:0]	cin49;
wire[13:0]	cin50;
wire[13:0]	cin51;
wire[13:0]	cin52;
wire[13:0]	cin53;
wire[13:0]	cin54;
wire[13:0]	cin55;
wire[13:0]	cin56;
wire[13:0]	cin57;
wire[13:0]	cin58;
wire[13:0]	cin59;
wire[13:0]	cin60;
wire[13:0]	cin61;
wire[13:0]	cin62;
wire[13:0]	cin63;

wire[13:0]	cout0;
wire[13:0]	cout1;
wire[13:0]	cout2;
wire[13:0]	cout3;
wire[13:0]	cout4;
wire[13:0]	cout5;
wire[13:0]	cout6;
wire[13:0]	cout7;
wire[13:0]	cout8;
wire[13:0]	cout9;
wire[13:0]	cout10;
wire[13:0]	cout11;
wire[13:0]	cout12;
wire[13:0]	cout13;
wire[13:0]	cout14;
wire[13:0]	cout15;
wire[13:0]	cout16;
wire[13:0]	cout17;
wire[13:0]	cout18;
wire[13:0]	cout19;
wire[13:0]	cout20;
wire[13:0]	cout21;
wire[13:0]	cout22;
wire[13:0]	cout23;
wire[13:0]	cout24;
wire[13:0]	cout25;
wire[13:0]	cout26;
wire[13:0]	cout27;
wire[13:0]	cout28;
wire[13:0]	cout29;
wire[13:0]	cout30;
wire[13:0]	cout31;
wire[13:0]	cout32;
wire[13:0]	cout33;
wire[13:0]	cout34;
wire[13:0]	cout35;
wire[13:0]	cout36;
wire[13:0]	cout37;
wire[13:0]	cout38;
wire[13:0]	cout39;
wire[13:0]	cout40;
wire[13:0]	cout41;
wire[13:0]	cout42;
wire[13:0]	cout43;
wire[13:0]	cout44;
wire[13:0]	cout45;
wire[13:0]	cout46;
wire[13:0]	cout47;
wire[13:0]	cout48;
wire[13:0]	cout49;
wire[13:0]	cout50;
wire[13:0]	cout51;
wire[13:0]	cout52;
wire[13:0]	cout53;
wire[13:0]	cout54;
wire[13:0]	cout55;
wire[13:0]	cout56;
wire[13:0]	cout57;
wire[13:0]	cout58;
wire[13:0]	cout59;
wire[13:0]	cout60;
wire[13:0]	cout61;
wire[13:0]	cout62;
wire[13:0]	cout63;


assign cin0=14'd0;
assign cin1=	cout0;
assign cin2=	cout1;
assign cin3=	cout2;
assign cin4=	cout3;
assign cin5=	cout4;
assign cin6=	cout5;
assign cin7=	cout6;
assign cin8=	cout7;
assign cin9=	cout8;
assign cin10=	cout9;
assign cin11=	cout10;
assign cin12=	cout11;
assign cin13=	cout12;
assign cin14=	cout13;
assign cin15=	cout14;
assign cin16=	cout15;
assign cin17=	cout16;
assign cin18=	cout17;
assign cin19=	cout18;
assign cin20=	cout19;
assign cin21=	cout20;
assign cin22=	cout21;
assign cin23=	cout22;
assign cin24=	cout23;
assign cin25=	cout24;
assign cin26=	cout25;
assign cin27=	cout26;
assign cin28=	cout27;
assign cin29=	cout28;
assign cin30=	cout29;
assign cin31=	cout30;
assign cin32=	cout31;
assign cin33=	cout32;
assign cin34=	cout33;
assign cin35=	cout34;
assign cin36=	cout35;
assign cin37=	cout36;
assign cin38=	cout37;
assign cin39=	cout38;
assign cin40=	cout39;
assign cin41=	cout40;
assign cin42=	cout41;
assign cin43=	cout42;
assign cin44=	cout43;
assign cin45=	cout44;
assign cin46=	cout45;
assign cin47=	cout46;
assign cin48=	cout47;
assign cin49=	cout48;
assign cin50=	cout49;
assign cin51=	cout50;
assign cin52=	cout51;
assign cin53=	cout52;
assign cin54=	cout53;
assign cin55=	cout54;
assign cin56=	cout55;
assign cin57=	cout56;
assign cin58=	cout57;
assign cin59=	cout58;
assign cin60=	cout59;
assign cin61=	cout60;
assign cin62=	cout61;
assign cin63=	cout62;
SubWTree  subtree1(clk,wt_begin,	Tree1,	subTree_end[0],	Sadder[0],	Cadder[0],	cin0,	cout0);
SubWTree  subtree2(clk,wt_begin,	Tree2,	subTree_end[1],	Sadder[1],	Cadder[1],	cin1,	cout1);
SubWTree  subtree3(clk,wt_begin,	Tree3,	subTree_end[2],	Sadder[2],	Cadder[2],	cin2,	cout2);
SubWTree  subtree4(clk,wt_begin,	Tree4,	subTree_end[3],	Sadder[3],	Cadder[3],	cin3,	cout3);
SubWTree  subtree5(clk,wt_begin,	Tree5,	subTree_end[4],	Sadder[4],	Cadder[4],	cin4,	cout4);
SubWTree  subtree6(clk,wt_begin,	Tree6,	subTree_end[5],	Sadder[5],	Cadder[5],	cin5,	cout5);
SubWTree  subtree7(clk,wt_begin,	Tree7,	subTree_end[6],	Sadder[6],	Cadder[6],	cin6,	cout6);
SubWTree  subtree8(clk,wt_begin,	Tree8,	subTree_end[7],	Sadder[7],	Cadder[7],	cin7,	cout7);
SubWTree  subtree9(clk,wt_begin,	Tree9,	subTree_end[8],	Sadder[8],	Cadder[8],	cin8,	cout8);
SubWTree  subtree10(clk,wt_begin,	Tree10,	subTree_end[9],	Sadder[9],	Cadder[9],	cin9,	cout9);
SubWTree  subtree11(clk,wt_begin,	Tree11,	subTree_end[10],	Sadder[10],	Cadder[10],	cin10,	cout10);
SubWTree  subtree12(clk,wt_begin,	Tree12,	subTree_end[11],	Sadder[11],	Cadder[11],	cin11,	cout11);
SubWTree  subtree13(clk,wt_begin,	Tree13,	subTree_end[12],	Sadder[12],	Cadder[12],	cin12,	cout12);
SubWTree  subtree14(clk,wt_begin,	Tree14,	subTree_end[13],	Sadder[13],	Cadder[13],	cin13,	cout13);
SubWTree  subtree15(clk,wt_begin,	Tree15,	subTree_end[14],	Sadder[14],	Cadder[14],	cin14,	cout14);
SubWTree  subtree16(clk,wt_begin,	Tree16,	subTree_end[15],	Sadder[15],	Cadder[15],	cin15,	cout15);
SubWTree  subtree17(clk,wt_begin,	Tree17,	subTree_end[16],	Sadder[16],	Cadder[16],	cin16,	cout16);
SubWTree  subtree18(clk,wt_begin,	Tree18,	subTree_end[17],	Sadder[17],	Cadder[17],	cin17,	cout17);
SubWTree  subtree19(clk,wt_begin,	Tree19,	subTree_end[18],	Sadder[18],	Cadder[18],	cin18,	cout18);
SubWTree  subtree20(clk,wt_begin,	Tree20,	subTree_end[19],	Sadder[19],	Cadder[19],	cin19,	cout19);
SubWTree  subtree21(clk,wt_begin,	Tree21,	subTree_end[20],	Sadder[20],	Cadder[20],	cin20,	cout20);
SubWTree  subtree22(clk,wt_begin,	Tree22,	subTree_end[21],	Sadder[21],	Cadder[21],	cin21,	cout21);
SubWTree  subtree23(clk,wt_begin,	Tree23,	subTree_end[22],	Sadder[22],	Cadder[22],	cin22,	cout22);
SubWTree  subtree24(clk,wt_begin,	Tree24,	subTree_end[23],	Sadder[23],	Cadder[23],	cin23,	cout23);
SubWTree  subtree25(clk,wt_begin,	Tree25,	subTree_end[24],	Sadder[24],	Cadder[24],	cin24,	cout24);
SubWTree  subtree26(clk,wt_begin,	Tree26,	subTree_end[25],	Sadder[25],	Cadder[25],	cin25,	cout25);
SubWTree  subtree27(clk,wt_begin,	Tree27,	subTree_end[26],	Sadder[26],	Cadder[26],	cin26,	cout26);
SubWTree  subtree28(clk,wt_begin,	Tree28,	subTree_end[27],	Sadder[27],	Cadder[27],	cin27,	cout27);
SubWTree  subtree29(clk,wt_begin,	Tree29,	subTree_end[28],	Sadder[28],	Cadder[28],	cin28,	cout28);
SubWTree  subtree30(clk,wt_begin,	Tree30,	subTree_end[29],	Sadder[29],	Cadder[29],	cin29,	cout29);
SubWTree  subtree31(clk,wt_begin,	Tree31,	subTree_end[30],	Sadder[30],	Cadder[30],	cin30,	cout30);
SubWTree  subtree32(clk,wt_begin,	Tree32,	subTree_end[31],	Sadder[31],	Cadder[31],	cin31,	cout31);
SubWTree  subtree33(clk,wt_begin,	Tree33,	subTree_end[32],	Sadder[32],	Cadder[32],	cin32,	cout32);
SubWTree  subtree34(clk,wt_begin,	Tree34,	subTree_end[33],	Sadder[33],	Cadder[33],	cin33,	cout33);
SubWTree  subtree35(clk,wt_begin,	Tree35,	subTree_end[34],	Sadder[34],	Cadder[34],	cin34,	cout34);
SubWTree  subtree36(clk,wt_begin,	Tree36,	subTree_end[35],	Sadder[35],	Cadder[35],	cin35,	cout35);
SubWTree  subtree37(clk,wt_begin,	Tree37,	subTree_end[36],	Sadder[36],	Cadder[36],	cin36,	cout36);
SubWTree  subtree38(clk,wt_begin,	Tree38,	subTree_end[37],	Sadder[37],	Cadder[37],	cin37,	cout37);
SubWTree  subtree39(clk,wt_begin,	Tree39,	subTree_end[38],	Sadder[38],	Cadder[38],	cin38,	cout38);
SubWTree  subtree40(clk,wt_begin,	Tree40,	subTree_end[39],	Sadder[39],	Cadder[39],	cin39,	cout39);
SubWTree  subtree41(clk,wt_begin,	Tree41,	subTree_end[40],	Sadder[40],	Cadder[40],	cin40,	cout40);
SubWTree  subtree42(clk,wt_begin,	Tree42,	subTree_end[41],	Sadder[41],	Cadder[41],	cin41,	cout41);
SubWTree  subtree43(clk,wt_begin,	Tree43,	subTree_end[42],	Sadder[42],	Cadder[42],	cin42,	cout42);
SubWTree  subtree44(clk,wt_begin,	Tree44,	subTree_end[43],	Sadder[43],	Cadder[43],	cin43,	cout43);
SubWTree  subtree45(clk,wt_begin,	Tree45,	subTree_end[44],	Sadder[44],	Cadder[44],	cin44,	cout44);
SubWTree  subtree46(clk,wt_begin,	Tree46,	subTree_end[45],	Sadder[45],	Cadder[45],	cin45,	cout45);
SubWTree  subtree47(clk,wt_begin,	Tree47,	subTree_end[46],	Sadder[46],	Cadder[46],	cin46,	cout46);
SubWTree  subtree48(clk,wt_begin,	Tree48,	subTree_end[47],	Sadder[47],	Cadder[47],	cin47,	cout47);
SubWTree  subtree49(clk,wt_begin,	Tree49,	subTree_end[48],	Sadder[48],	Cadder[48],	cin48,	cout48);
SubWTree  subtree50(clk,wt_begin,	Tree50,	subTree_end[49],	Sadder[49],	Cadder[49],	cin49,	cout49);
SubWTree  subtree51(clk,wt_begin,	Tree51,	subTree_end[50],	Sadder[50],	Cadder[50],	cin50,	cout50);
SubWTree  subtree52(clk,wt_begin,	Tree52,	subTree_end[51],	Sadder[51],	Cadder[51],	cin51,	cout51);
SubWTree  subtree53(clk,wt_begin,	Tree53,	subTree_end[52],	Sadder[52],	Cadder[52],	cin52,	cout52);
SubWTree  subtree54(clk,wt_begin,	Tree54,	subTree_end[53],	Sadder[53],	Cadder[53],	cin53,	cout53);
SubWTree  subtree55(clk,wt_begin,	Tree55,	subTree_end[54],	Sadder[54],	Cadder[54],	cin54,	cout54);
SubWTree  subtree56(clk,wt_begin,	Tree56,	subTree_end[55],	Sadder[55],	Cadder[55],	cin55,	cout55);
SubWTree  subtree57(clk,wt_begin,	Tree57,	subTree_end[56],	Sadder[56],	Cadder[56],	cin56,	cout56);
SubWTree  subtree58(clk,wt_begin,	Tree58,	subTree_end[57],	Sadder[57],	Cadder[57],	cin57,	cout57);
SubWTree  subtree59(clk,wt_begin,	Tree59,	subTree_end[58],	Sadder[58],	Cadder[58],	cin58,	cout58);
SubWTree  subtree60(clk,wt_begin,	Tree60,	subTree_end[59],	Sadder[59],	Cadder[59],	cin59,	cout59);
SubWTree  subtree61(clk,wt_begin,	Tree61,	subTree_end[60],	Sadder[60],	Cadder[60],	cin60,	cout60);
SubWTree  subtree62(clk,wt_begin,	Tree62,	subTree_end[61],	Sadder[61],	Cadder[61],	cin61,	cout61);
SubWTree  subtree63(clk,wt_begin,	Tree63,	subTree_end[62],	Sadder[62],	Cadder[62],	cin62,	cout62);
SubWTree  subtree64(clk,wt_begin,	Tree64,	subTree_end[63],	Sadder[63],	Cadder[63],	cin63,	cout63);
//	reg mwt_valid;
//	always @(posedge clk)
//    begin
//        if (!mwt_begin || (&subTree_end))  //只有当subtree执行结束才可�?
//        begin
//            mwt_valid <= 1'b0;
//        end
//        else
//        begin
//            mwt_valid <= 1'b1;
//        end
//    end
	reg[63:0] product_temp;
	reg end_temp;
	always @ (posedge clk)
    begin
	   if(&subTree_end)
	   begin
	    product_temp <= {Cadder[62:0],1'b0}+Sadder;
		end_temp <= 1'b1;
		end
	   else
	     end_temp<=1'b0;
	end
	assign wt_end=end_temp;
	assign product = product_temp;

endmodule
	

