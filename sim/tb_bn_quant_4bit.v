`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 15:49:29
// Design Name: 
// Module Name: tb_bn_quant_4bit
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


module tb_bn_quant_4bit();
    parameter XW = 22;        
    parameter Q  = 18;        
    parameter S  = 8;        
    parameter SIGNED_MODE = 1 ;
    reg signed [XW-1:0]X_in;
    reg signed [15:0]gamma_q;  // γ Q1.14 -2|+1.9999 0.1|3.0  
    reg signed [31:0]beta_q;   // β Q8.23 -128|+128 -2.0|2.0
    wire signed [3:0]Y_out;

initial begin
    // case1: γ = 1.0, β = 0
    // gamma_q = 1.0 * 2^14 = 16384 = 16'h4000
    // beta_q  = 0.0 * 2^23 = 0
    X_in     = 22'sd1024;    // 输入约 0.5 (假设输入范围≈[-2048,2047])
    gamma_q  = 16'sd16384;
    beta_q   = 32'sd0;
    #10;
    
    // case2: γ = 0.5, β = +1.0
    // gamma_q = 0.5 * 2^14 = 8192
    // beta_q  = 1.0 * 2^23 = 8388608
    X_in     = 22'sd2048;
    gamma_q  = 16'sd8192;
    beta_q   = 32'sd8388608;
    #10;
    
    // case3: γ = 1.5, β = -0.5
    // gamma_q = 1.5 * 2^14 = 24576
    // beta_q  = -0.5 * 2^23 = -4194304
    X_in     = 22'sd4096;
    gamma_q  = 16'sd24576;
    beta_q   = -32'sd4194304;
    #10;

    // case4: γ = 2.0, β = 0  → 观察是否clip
    gamma_q  = 16'sd32768;
    beta_q   = 32'sd0;
    X_in     = 22'sd6000;
    #10;

    // case5: γ = 0.25, β = 0 → 缩小输出
    gamma_q  = 16'sd4096;
    beta_q   = 32'sd0;
    X_in     = 22'sd6000;
    #10;

end

bn_quant_4bit #(
    .XW(22),       
    .Q (18),        
    .S (8) ,        
    .SIGNED_MODE(1) 
)bn_quant_4bit(
    .X_in(X_in),
    .gamma_q(gamma_q), 
    .beta_q(beta_q),  
    .Y_out(Y_out)
);

endmodule
