`timescale 1ns / 1ps
module SubWTree (
   input clk,
   input swt_begin,
   input wire [16:0] in,
  
   output swt_end,
   output S,
   output C,
   input wire [13:0] cin,
   output wire [13:0] cout
 );
    reg[2:0] reg1,reg2,reg3,reg4,reg5,reg6,reg7,reg8,reg9,reg10,reg11,reg12,reg13,reg14,reg15;
    reg[3:0] count;
    assign swt_end = ((count == 4'd6)&swt_valid) ? 1'd1:1'd0; //乘法结束信号：乘数全0
	wire[14:0] Cn; //各层的进�?
	wire[14:0] Sn; //各层的和

	myadder myadder1(reg1[0],reg1[1],reg1[2],Sn[0],Cn[0]);
	myadder myadder2(reg2[0],reg2[1],reg2[2],Sn[1],Cn[1]);
	myadder myadder3(reg3[0],reg3[1],reg3[2],Sn[2],Cn[2]);
	myadder myadder4(reg4[0],reg4[1],reg4[2],Sn[3],Cn[3]);
	myadder myadder5(reg5[0],reg5[1],reg5[2],Sn[4],Cn[4]);
	
	myadder myadder6(reg6[0],reg6[1],reg6[2],Sn[5],Cn[5]);
	myadder myadder7(reg7[0],reg7[1],reg7[2],Sn[6],Cn[6]);
	myadder myadder8(reg8[0],reg8[1],reg8[2],Sn[7],Cn[7]);
	myadder myadder9(reg9[0],reg9[1],reg9[2],Sn[8],Cn[8]);
	
	myadder myadder10(reg10[0],reg10[1],reg10[2],Sn[9],Cn[9]);
	myadder myadder11(reg11[0],reg11[1],reg11[2],Sn[10],Cn[10]);
	
	myadder myadder12(reg12[0],reg12[1],reg12[2],Sn[11],Cn[11]);
	myadder myadder13(reg13[0],reg13[1],reg13[2],Sn[12],Cn[12]);
	
	myadder myadder14(reg14[0],reg14[1],reg14[2],Sn[13],Cn[13]);
	
	myadder myadder15(reg15[0],reg15[1],reg15[2],Sn[14],Cn[14]);

	
	
	reg swt_valid;
    always @(posedge clk)
    begin
        if (!swt_begin || swt_end)
        begin
            swt_valid <= 1'b0;
        end
        else
        begin
            swt_valid <= 1'b1;
        end
   end 
  
always @ (posedge clk)
begin
	if(swt_valid)
		begin
	    if (count == 4'd0)
			begin  
            //{reg1,reg2,reg3,reg4,reg <= patial_product_0; 
			reg1 <= in[4:2];
			reg2 <= in[7:5];
			reg3 <= in[10:8];
			reg4 <= in[13:11];
			reg5 <= in[16:14];
        end
        else if (count == 4'd1)
        begin
            reg6<={cin[2:0]};//5.30
			reg7<={in[0],cin[4:3]};
			reg8<={Sn[1:0],in[1]};
			reg9<=Sn[4:2];
        end
		else if (count == 4'd2)
        begin
            reg10<={cin[6:5],Sn[5]};
			reg11<={Sn[8:6]};
        end
		else if (count == 4'd3)
        begin
            reg12<=cin[9:7];
			reg13<={Sn[10:9],cin[10]};
        end
		else if (count == 4'd4)
        begin
            reg14<={Sn[12:11],cin[11]};
        end
		else if (count == 4'd5)
        begin
            reg15<={Sn[13],cin[13:12]};
        end
    end 
 end
    //计数�?
always @ (posedge clk)  
    begin
	     if (swt_begin & ~swt_end)
			count <= 4'd0;
        if (swt_valid)
        begin
            count <= count + 4'd1;
        end
    end 
	
	assign S=Sn[14];
	assign C=Cn[14];
	assign cout=Cn[13:0];
endmodule

module myadder(
     //input clk,
	 input a,
	 input b,
	 input c,
	 output sum,
	 output cin
);
   assign {cin,sum} = ( a==0 & b==0 & c==0 ) ? 2'b00 :
                      ( (a==1 & b==0 & c==0) | (a==0 & b==1 & c==0) | (a==0 & b==0 & c==1)) ? 2'b01 :
					  ( (a==1 & b==1 & c==0) | (a==0 & b==1 & c==1) | (a==1 & b==0 & c==1)) ? 2'b10 : 2'b11;
					  
					  
endmodule					  