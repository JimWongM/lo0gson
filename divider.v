`timescale 1ns / 1ps
module divider(
	input wire 			clk,
	input wire 			div_begin,
	input wire          div_signed,
	input wire [31:0] 	div_op1,
	input wire [31:0] 	div_op2,
	output wire [31:0] 	div_result,
	output wire [31:0] 	div_remainder,
	output wire 		div_end

	);
	// Divider calculating signal and end signal
	reg div_valid;
	// Set to 33 times jump out.
	assign div_end = div_valid & ~(|times);
	always @(posedge clk) 
	begin
		if (!div_begin || div_end) 
		begin
			div_valid <= 1'b0;
		end
		else
		begin
		    div_valid <= 1'b1;
		end
	end
	// Get the absolute value of two operands.
    wire        op1_sign;      
    wire        op2_sign;      
    wire [31:0] op1_absolute;  
    wire [31:0] op2_absolute;  
    assign op1_sign = div_signed ? div_op1[31] : 1'b0;
    assign op2_sign = div_signed ? div_op2[31] : 1'b0;
    assign op1_absolute = ~div_signed ? div_op1 : op1_sign ? (~div_op1+1) : div_op1;
    assign op2_absolute = ~div_signed ? div_op2 : op2_sign ? (~div_op2+1) : div_op2;

    // Load dividend, actually we can regard it as the original remainder
    reg [63:0] remainder;
    reg [63:0] remainder_tmp;
    reg [63:0] divisor;
    reg [31:0] quotient;
    reg carry;
    reg [33:0] times;
    always @(posedge clk) 
    begin
        if (div_valid)
    	begin
    		{carry,remainder_tmp} <= (carry==1'b1)
    		                       ? {1'b0,remainder_tmp} + {1'b0,~divisor} + 1'b1
    		                       : {1'b0,remainder} + {1'b0,~divisor} + 1'b1;
    		if (carry==1'b1)	// Judge if remainder_tmp - divisor > 0
    		begin
    		    remainder <= remainder_tmp;
    			quotient <= {quotient[30:0],1'b1};
    		end
    		else
    		begin
    			quotient <= {quotient[30:0],1'b0};
    		end
    		divisor <= {1'b0,divisor[63:1]};
            times <= {1'b0,times[33:1]};
    	end
    	else if (div_begin)
        begin
            remainder <= {32'd0,op1_absolute};    
            divisor <= {op2_absolute,32'd0};
            quotient <= 32'b0;
            carry <= 1'b0;
            times <= {1'b1,33'd0};
        end
    end
	// Calculate sign and real-result of divider reuslt.
    reg quotient_sign;
    always @ (posedge clk)
    begin
        if (div_valid)
        begin
              quotient_sign <= op1_sign ^ op2_sign;
        end
    end
    
    assign div_result = quotient_sign ? (~quotient + 1) : quotient;
    assign div_remainder = op1_sign ? (~remainder[31:0] + 1) : remainder[31:0];
endmodule




















