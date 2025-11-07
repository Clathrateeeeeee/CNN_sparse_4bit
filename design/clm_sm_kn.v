`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/21 10:25:36
// Design Name: 
// Module Name: clm_sm_kn
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module clm_sm_kn(
    input  [3:0] A,         // signed 4-bit input (two's complement)
    input  [3:0] B,         // signed 4-bit input (two's complement)
    output       sign,
    output [6:0] result     // signed 6-bit output
);

    wire [5:0] abs_result;
    assign sign = A[3] ^ B[3]; 


    // Look-up Table 3x3
    mult3x3_lut lut_unit1 (
        .a(A[2:0]),
        .b(B[2:0]),
        .Y(abs_result)
    );

    // complementation
    wire [6:0] result_neg = ~{1'b0,abs_result};
    assign result = sign ? result_neg : {1'b0,abs_result}; //This result is not a complete one and still lacks the accumulation of sign bits

endmodule
