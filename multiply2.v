`timescale 1ns / 1ps

module multiply(              // 乘法器
    input         clk,        // 时钟
    input         mult_begin, // 乘法开始信号
    input  [31:0] imult_op1,   // 乘法源操作数1
    input  [31:0] imult_op2,   // 乘法源操作数2,记得改接口名，因为下面太多了，不好改
   // input [63:0] patial_product_0[15:0],    // 符号位扩展后的部分积
   input         mult_sign,  //5.30新增带符号/无符号乘法
    output [63:0] product,    // 乘积
    output        mult_end    // 乘法结束信号
);

    //乘法正在运算信号和结束信号
//    reg[4:0] count;
//    assign mult_end = mult_valid & (count == 5'd16); //乘法结束信号：乘数全0


    wire [63:0] patial_product_0;    // 符号位扩展后的部分积
	wire [63:0] patial_product_1;    // 符号位扩展后的部分积
	wire [63:0] patial_product_2;    // 符号位扩展后的部分积
	wire [63:0] patial_product_3;    // 符号位扩展后的部分积
	wire [63:0] patial_product_4;    // 符号位扩展后的部分积
	wire [63:0] patial_product_5;   // 符号位扩展后的部分积
	wire [63:0] patial_product_6;    // 符号位扩展后的部分积
	wire [63:0] patial_product_7;    // 符号位扩展后的部分积
	wire [63:0] patial_product_8;    // 符号位扩展后的部分积
	wire [63:0] patial_product_9;    // 符号位扩展后的部分积
	wire [63:0] patial_product_10;    // 符号位扩展后的部分积
	wire [63:0] patial_product_11;    // 符号位扩展后的部分积
	wire [63:0] patial_product_12;    // 符号位扩展后的部分积
	wire [63:0] patial_product_13;    // 符号位扩展后的部分积
	wire [63:0] patial_product_14;    // 符号位扩展后的部分积
	wire [63:0] patial_product_15;    // 符号位扩展后的部分积
	wire [63:0] patial_product_16;    // 符号位扩展后的部分积
wire  [32:0] mult_op1;	
wire  [34:0] mult_op2;	
wire  [63:0] temp1;  //temp1 = +2[x]
wire  [63:0] temp2; //temp2=+[x]
wire  [63:0] temp3;  //temp1 = +2[x]
wire  [63:0] temp4; //temp2=+[x] 

//assign op1= (!partial[2]&!partial[1]&!partial[0])|(partial[2]&partial[1]&partial[0]);
//assign op2= (!partial[2]&partial[1]&!partial[0])|(!partial[2]&!partial[1]&partial[0]);
//assign op3= (!partial[2]&partial[1]&partial[0]);
//assign op4= (partial[2]&!partial[1]&!partial[0]);
//assign op5= (partial[2]&!partial[1]&partial[0])|(partial[2]&partial[1]&!partial[0]);
assign mult_op2 = mult_sign ? {{2{imult_op2[31]}},imult_op2[31:0],1'd0} : {2'b0,imult_op2[31:0],1'd0};
assign mult_op1 = mult_sign ? {imult_op1[31],imult_op1[31:0]} : {1'b0,imult_op1[31:0]};

assign temp1 = {{31{mult_op1[32]}},imult_op1[31:0],1'd0};
assign temp2 = {{32{mult_op1[32]}},imult_op1[31:0]};
assign temp3=~temp2+1;
assign temp4=~temp1+1;
//assign patial_product = op2 ? {{32{mult_op1[31]}}, mult_op1} :
					   // op3 ? temp :
						//op4 ? ~mult_op1+1 :
						//op5 ? ~temp+1 : 64'd0;
assign patial_product_0 = (!mult_op2[2]&mult_op2[1]&!mult_op2[0])|(!mult_op2[2]&!mult_op2[1]&mult_op2[0]) ? temp2 :
                          (!mult_op2[2]&mult_op2[1]&mult_op2[0]) ? temp1 :
						  (mult_op2[2]&!mult_op2[1]&!mult_op2[0]) ?  temp4 :
						  (mult_op2[2]&!mult_op2[1]&mult_op2[0])|(mult_op2[2]&mult_op2[1]&!mult_op2[0]) ? temp3 : 64'd0;
assign patial_product_1 = (!mult_op2[4]&mult_op2[3]&!mult_op2[2])|(!mult_op2[4]&!mult_op2[3]&mult_op2[2]) ? {temp2[61:0],2'd0} :
                          (!mult_op2[4]&mult_op2[3]&mult_op2[2]) ? {temp1[61:0],2'd0}  :
						  (mult_op2[4]&!mult_op2[3]&!mult_op2[2]) ?  {temp4[61:0],2'd0} :
						  (mult_op2[4]&!mult_op2[3]&mult_op2[2])|(mult_op2[4]&mult_op2[3]&!mult_op2[2]) ? {temp3[61:0],2'd0} : 64'd0;
assign patial_product_2 = (!mult_op2[6]&mult_op2[5]&!mult_op2[4])|(!mult_op2[6]&!mult_op2[5]&mult_op2[4]) ? {temp2[59:0],4'd0} :
                          (!mult_op2[6]&mult_op2[5]&mult_op2[4]) ? {temp1[59:0],4'd0} :
						  (mult_op2[6]&!mult_op2[5]&!mult_op2[4]) ?  {temp4[59:0],4'd0} :
						  (mult_op2[6]&!mult_op2[5]&mult_op2[4])|(mult_op2[6]&mult_op2[5]&!mult_op2[4]) ? {temp3[59:0],4'd0} : 64'd0;
assign patial_product_3 = (!mult_op2[8]&mult_op2[7]&!mult_op2[6])|(!mult_op2[8]&!mult_op2[7]&mult_op2[6]) ? {temp2[57:0],6'd0} :
                          (!mult_op2[8]&mult_op2[7]&mult_op2[6]) ? {temp1[57:0],6'd0} :
						  (mult_op2[8]&!mult_op2[7]&!mult_op2[6]) ?  {temp4[57:0],6'd0} :
						  (mult_op2[8]&!mult_op2[7]&mult_op2[6])|(mult_op2[8]&mult_op2[7]&!mult_op2[6]) ? {temp3[57:0],6'd0} : 64'd0;
assign patial_product_4 = (!mult_op2[10]&mult_op2[9]&!mult_op2[8])|(!mult_op2[10]&!mult_op2[9]&mult_op2[8]) ? {temp2[55:0],8'd0} :
                          (!mult_op2[10]&mult_op2[9]&mult_op2[8]) ? {temp1[55:0],8'd0} :
						  (mult_op2[10]&!mult_op2[9]&!mult_op2[8]) ?  {temp4[55:0],8'd0} :
						  (mult_op2[10]&!mult_op2[9]&mult_op2[8])|(mult_op2[10]&mult_op2[9]&!mult_op2[8]) ? {temp3[55:0],8'd0} : 64'd0;
assign patial_product_5 = (!mult_op2[12]&mult_op2[11]&!mult_op2[10])|(!mult_op2[12]&!mult_op2[11]&mult_op2[10]) ? {temp2[53:0],10'd0} :
                          (!mult_op2[12]&mult_op2[11]&mult_op2[10]) ? {temp1[53:0],10'd0} :
						  (mult_op2[12]&!mult_op2[11]&!mult_op2[10]) ?  {temp4[53:0],10'd0} :
						  (mult_op2[12]&!mult_op2[11]&mult_op2[10])|(mult_op2[12]&mult_op2[11]&!mult_op2[10]) ? {temp3[53:0],10'd0} : 64'd0;
assign patial_product_6 = (!mult_op2[14]&mult_op2[13]&!mult_op2[12])|(!mult_op2[14]&!mult_op2[13]&mult_op2[12]) ? {temp2[51:0],12'd0} :
                          (!mult_op2[14]&mult_op2[13]&mult_op2[12]) ? {temp1[51:0],12'd0} :
						  (mult_op2[14]&!mult_op2[13]&!mult_op2[12]) ?  {temp4[51:0],12'd0} :
						  (mult_op2[14]&!mult_op2[13]&mult_op2[12])|(mult_op2[14]&mult_op2[13]&!mult_op2[12]) ? {temp3[51:0],12'd0} : 64'd0;
assign patial_product_7 = (!mult_op2[16]&mult_op2[15]&!mult_op2[14])|(!mult_op2[16]&!mult_op2[15]&mult_op2[14]) ? {temp2[49:0],14'd0} :
                          (!mult_op2[16]&mult_op2[15]&mult_op2[14]) ? {temp1[49:0],14'd0} :
						  (mult_op2[16]&!mult_op2[15]&!mult_op2[14]) ?  {temp4[49:0],14'd0} :
						  (mult_op2[16]&!mult_op2[15]&mult_op2[14])|(mult_op2[16]&mult_op2[15]&!mult_op2[14]) ? {temp3[49:0],14'd0} : 64'd0;
assign patial_product_8 = (!mult_op2[18]&mult_op2[17]&!mult_op2[16])|(!mult_op2[18]&!mult_op2[17]&mult_op2[16]) ? {temp2[47:0],16'd0} :
                          (!mult_op2[18]&mult_op2[17]&mult_op2[16]) ? {temp1[47:0],16'd0} :
						  (mult_op2[18]&!mult_op2[17]&!mult_op2[16]) ?  {temp4[47:0],16'd0} :
						  (mult_op2[18]&!mult_op2[17]&mult_op2[16])|(mult_op2[18]&mult_op2[17]&!mult_op2[16]) ? {temp3[47:0],16'd0} : 64'd0;
assign patial_product_9 = (!mult_op2[20]&mult_op2[19]&!mult_op2[18])|(!mult_op2[20]&!mult_op2[19]&mult_op2[18]) ? {temp2[45:0],18'd0} :
                          (!mult_op2[20]&mult_op2[19]&mult_op2[18]) ? {temp1[45:0],18'd0} :
						  (mult_op2[20]&!mult_op2[19]&!mult_op2[18]) ?  {temp4[45:0],18'd0} :
						  (mult_op2[20]&!mult_op2[19]&mult_op2[18])|(mult_op2[20]&mult_op2[19]&!mult_op2[18]) ? {temp3[45:0],18'd0} : 64'd0;
assign patial_product_10 = (!mult_op2[22]&mult_op2[21]&!mult_op2[20])|(!mult_op2[22]&!mult_op2[21]&mult_op2[20]) ? {temp2[43:0],20'd0} :
                          (!mult_op2[22]&mult_op2[21]&mult_op2[20]) ? {temp1[43:0],20'd0} :
						  (mult_op2[22]&!mult_op2[21]&!mult_op2[20]) ?  {temp4[43:0],20'd0} :
						  (mult_op2[22]&!mult_op2[21]&mult_op2[20])|(mult_op2[22]&mult_op2[21]&!mult_op2[20]) ? {temp3[43:0],20'd0} : 64'd0;
assign patial_product_11 = (!mult_op2[24]&mult_op2[23]&!mult_op2[22])|(!mult_op2[24]&!mult_op2[23]&mult_op2[22]) ? {temp2[41:0],22'd0} :
                          (!mult_op2[24]&mult_op2[23]&mult_op2[22]) ? {temp1[41:0],22'd0} :
						  (mult_op2[24]&!mult_op2[23]&!mult_op2[22]) ?  {temp4[41:0],22'd0} :
						  (mult_op2[24]&!mult_op2[23]&mult_op2[22])|(mult_op2[24]&mult_op2[23]&!mult_op2[22]) ? {temp3[41:0],22'd0} : 64'd0;
assign patial_product_12 = (!mult_op2[26]&mult_op2[25]&!mult_op2[24])|(!mult_op2[26]&!mult_op2[25]&mult_op2[24]) ? {temp2[39:0],24'd0} :
                          (!mult_op2[26]&mult_op2[25]&mult_op2[24]) ? {temp1[39:0],24'd0} :
						  (mult_op2[26]&!mult_op2[25]&!mult_op2[24]) ?  {temp4[39:0],24'd0} :
						  (mult_op2[26]&!mult_op2[25]&mult_op2[24])|(mult_op2[26]&mult_op2[25]&!mult_op2[24]) ? {temp3[39:0],24'd0} : 64'd0;
assign patial_product_13 = (!mult_op2[28]&mult_op2[27]&!mult_op2[26])|(!mult_op2[28]&!mult_op2[27]&mult_op2[26]) ? {temp2[37:0],26'd0} :
                          (!mult_op2[28]&mult_op2[27]&mult_op2[26]) ? {temp1[37:0],26'd0} :
						  (mult_op2[28]&!mult_op2[27]&!mult_op2[26]) ?  {temp4[37:0],26'd0} :
						  (mult_op2[28]&!mult_op2[27]&mult_op2[26])|(mult_op2[28]&mult_op2[27]&!mult_op2[26]) ? {temp3[37:0],26'd0} : 64'd0;
assign patial_product_14 = (!mult_op2[30]&mult_op2[29]&!mult_op2[28])|(!mult_op2[30]&!mult_op2[29]&mult_op2[28]) ? {temp2[35:0],28'd0} :
                          (!mult_op2[30]&mult_op2[29]&mult_op2[28]) ? {temp1[35:0],28'd0} :
						  (mult_op2[30]&!mult_op2[29]&!mult_op2[28]) ?  {temp4[35:0],28'd0} :
						  (mult_op2[30]&!mult_op2[29]&mult_op2[28])|(mult_op2[30]&mult_op2[29]&!mult_op2[28]) ? {temp3[35:0],28'd0} : 64'd0;
assign patial_product_15 = (!mult_op2[32]&mult_op2[31]&!mult_op2[30])|(!mult_op2[32]&!mult_op2[31]&mult_op2[30]) ? {temp2[33:0],30'd0} :
                          (!mult_op2[32]&mult_op2[31]&mult_op2[30]) ? {temp1[33:0],30'd0} :
						  (mult_op2[32]&!mult_op2[31]&!mult_op2[30]) ?  {temp4[33:0],30'd0} :
						  (mult_op2[32]&!mult_op2[31]&mult_op2[30])|(mult_op2[32]&mult_op2[31]&!mult_op2[30]) ? {temp3[33:0],30'd0} : 64'd0;
assign patial_product_16 = (!mult_op2[34]&mult_op2[33]&!mult_op2[32])|(!mult_op2[34]&!mult_op2[33]&mult_op2[32]) ? {temp2[31:0],32'd0} :
                          (!mult_op2[34]&mult_op2[33]&mult_op2[32]) ? {temp1[31:0],32'd0} :
						  (mult_op2[34]&!mult_op2[33]&!mult_op2[32]) ?  {temp4[31:0],32'd0} :
						  (mult_op2[34]&!mult_op2[33]&mult_op2[32])|(mult_op2[34]&mult_op2[33]&!mult_op2[32]) ? {temp3[31:0],32'd0} : 64'd0;

//assign patial_product_16 = (mult_op2[33]&!mult_op2[32])|(!mult_op2[33]&mult_op2[32]) ? {temp2[31:0],32'd0} :
//                           (mult_op2[33]&mult_op2[32]) ? {temp1[31:0],32'd0} : 64'd0;									  

  // switch myswitch(partial_product_0,partial_product_1,partial_product_2,partial_product_3,partial_product_4,partial_product_5,partial_product_6,
         // partial_product_7,partial_product_8,partial_product_9,partial_product_10,partial_product_11,partial_product_12,partial_product_13,
		 // partial_product_14,partial_product_15);
    //wire mwt_begin;
	wire wt_end;
	wire[16:0]  Tree[63:0];	
	
    switch switch_module(
    .patial_product_0(patial_product_0),
    .patial_product_1(patial_product_1),
    .patial_product_2(patial_product_2),
    .patial_product_3(patial_product_3),
    .patial_product_4(patial_product_4),
    .patial_product_5(patial_product_5),
    .patial_product_6(patial_product_6),
    .patial_product_7(patial_product_7),
    .patial_product_8(patial_product_8),
    .patial_product_9(patial_product_9),
    .patial_product_10(patial_product_10),
    .patial_product_11(patial_product_11),
    .patial_product_12(patial_product_12),
    .patial_product_13(patial_product_13),
    .patial_product_14(patial_product_14),
    .patial_product_15(patial_product_15),
	.patial_product_16(patial_product_16),
    .Tree1(Tree[0]),
    .Tree2(Tree[1]),
    .Tree3(Tree[2]),
    .Tree4(Tree[3]),
    .Tree5(Tree[4]),
    .Tree6(Tree[5]),
    .Tree7(Tree[6]),
    .Tree8(Tree[7]),
    .Tree9(Tree[8]),
    .Tree10(Tree[9]),
    .Tree11(Tree[10]),
    .Tree12(Tree[11]),
    .Tree13(Tree[12]),
    .Tree14(Tree[13]),
    .Tree15(Tree[14]),
    .Tree16(Tree[15]),
    .Tree17(Tree[16]),
    .Tree18(Tree[17]),
    .Tree19(Tree[18]),
    .Tree20(Tree[19]),
    .Tree21(Tree[20]),
    .Tree22(Tree[21]),
    .Tree23(Tree[22]),
    .Tree24(Tree[23]),
    .Tree25(Tree[24]),
    .Tree26(Tree[25]),
    .Tree27(Tree[26]),
    .Tree28(Tree[27]),
    .Tree29(Tree[28]),
    .Tree30(Tree[29]),
    .Tree31(Tree[30]),
    .Tree32(Tree[31]),
    .Tree33(Tree[32]),
    .Tree34(Tree[33]),
    .Tree35(Tree[34]),
    .Tree36(Tree[35]),
    .Tree37(Tree[36]),
    .Tree38(Tree[37]),
    .Tree39(Tree[38]),
    .Tree40(Tree[39]),
    .Tree41(Tree[40]),
    .Tree42(Tree[41]),
    .Tree43(Tree[42]),
    .Tree44(Tree[43]),
    .Tree45(Tree[44]),
    .Tree46(Tree[45]),
    .Tree47(Tree[46]),
    .Tree48(Tree[47]),
    .Tree49(Tree[48]),
    .Tree50(Tree[49]),
    .Tree51(Tree[50]),
    .Tree52(Tree[51]),
    .Tree53(Tree[52]),
    .Tree54(Tree[53]),
    .Tree55(Tree[54]),
    .Tree56(Tree[55]),
    .Tree57(Tree[56]),
    .Tree58(Tree[57]),
    .Tree59(Tree[58]),
    .Tree60(Tree[59]),
    .Tree61(Tree[60]),
    .Tree62(Tree[61]),
    .Tree63(Tree[62]),
    .Tree64(Tree[63])
    );
    
    MainWTree MainWTree_module(
    .clk(clk),
    .mwt_begin(mult_begin),
    .Tree1(Tree[0]),
    .Tree2(Tree[1]),
    .Tree3(Tree[2]),
    .Tree4(Tree[3]),
    .Tree5(Tree[4]),
    .Tree6(Tree[5]),
    .Tree7(Tree[6]),
    .Tree8(Tree[7]),
    .Tree9(Tree[8]),
    .Tree10(Tree[9]),
    .Tree11(Tree[10]),
    .Tree12(Tree[11]),
    .Tree13(Tree[12]),
    .Tree14(Tree[13]),
    .Tree15(Tree[14]),
    .Tree16(Tree[15]),
    .Tree17(Tree[16]),
    .Tree18(Tree[17]),
    .Tree19(Tree[18]),
    .Tree20(Tree[19]),
    .Tree21(Tree[20]),
    .Tree22(Tree[21]),
    .Tree23(Tree[22]),
    .Tree24(Tree[23]),
    .Tree25(Tree[24]),
    .Tree26(Tree[25]),
    .Tree27(Tree[26]),
    .Tree28(Tree[27]),
    .Tree29(Tree[28]),
    .Tree30(Tree[29]),
    .Tree31(Tree[30]),
    .Tree32(Tree[31]),
    .Tree33(Tree[32]),
    .Tree34(Tree[33]),
    .Tree35(Tree[34]),
    .Tree36(Tree[35]),
    .Tree37(Tree[36]),
    .Tree38(Tree[37]),
    .Tree39(Tree[38]),
    .Tree40(Tree[39]),
    .Tree41(Tree[40]),
    .Tree42(Tree[41]),
    .Tree43(Tree[42]),
    .Tree44(Tree[43]),
    .Tree45(Tree[44]),
    .Tree46(Tree[45]),
    .Tree47(Tree[46]),
    .Tree48(Tree[47]),
    .Tree49(Tree[48]),
    .Tree50(Tree[49]),
    .Tree51(Tree[50]),
    .Tree52(Tree[51]),
    .Tree53(Tree[52]),
    .Tree54(Tree[53]),
    .Tree55(Tree[54]),
    .Tree56(Tree[55]),
    .Tree57(Tree[56]),
    .Tree58(Tree[57]),
    .Tree59(Tree[58]),
    .Tree60(Tree[59]),
    .Tree61(Tree[60]),
    .Tree62(Tree[61]),
    .Tree63(Tree[62]),
    .Tree64(Tree[63]),
    .wt_end(wt_end),
    .product(product)
    );
    
	//assign mwt_begin=mult_begin;
	assign mult_end=wt_end;
	


endmodule


	
