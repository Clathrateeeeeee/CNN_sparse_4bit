`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/29 14:15:47
// Design Name: 
// Module Name: tb_mask2selector
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


module tb_mask2selector();
    
    parameter deep = 512;
    parameter Ram_Row = 33;
    parameter Data_Width = 64;
    
    //mask
    reg clk;
    reg rst;
    reg [2:0]kernel_size;
    reg [1:0]stride;
    reg inbuff_ready;
    reg reset;
    reg [Data_Width*Ram_Row-1:0]din;//4bit * 16channels * 33
    
    //selector
    reg [16*Data_Width-1:0] index;
    wire [63:0]sele_outvalid;
    wire [448*64-1:0] valid_act;

mask2selector#(
    .deep(deep),
    .Ram_Row(Ram_Row),
    .Data_Width(Data_Width)
)mask2selector(
    //mask
    .clk(clk),
    .rst(rst),
    .kernel_size(kernel_size),
    .stride(stride),
    .inbuff_ready(inbuff_ready),
    .reset(reset),
    .din(din),//4bit * 16channels * 33
    //selector
    .index(index),
    .sele_outvalid(sele_outvalid),
    .valid_act(valid_act)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    initial begin
        rst = 1;
        kernel_size = 3;
        stride = 2;
        #20 rst = 0;
        
    end
    
endmodule
