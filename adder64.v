`timescale 1ns / 1ps

module adder64(
    input  [64:0] operand1,
    input  [64:0] operand2,
    input         cin,
    output [64:0] result,
    output        cout
    );
    assign {cout,result} = operand1 + operand2 + cin;

endmodule
