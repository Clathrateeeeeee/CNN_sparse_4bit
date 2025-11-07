`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/09 17:11:24
// Design Name: 
// Module Name: tb_inbuff_address
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


module tb_inbuff_address();

reg clk;
reg rst;
reg en;
reg [19:0]ifm_L_channel;
reg [9:0]ifm_L,ifm_H;
reg [9:0]featuremap_W,featuremap_H;
reg [8:0]c_num;
reg [2:0]kernel_size;
reg [1:0]stride;
wire [8:0]address;
wire done_tile;
wire last_tile;
wire [4:0]tile_num;
reg  [3:0]pad_edge;

wire reset;
wire [895:0]select_act;
wire out_valid;

initial begin
    clk = 0;
    forever #5 clk=~clk;
end
initial begin
    rst = 1;
    en = 0;
    #20
    rst = 0;
    en = 1;
    
    kernel_size = 3;
    stride = 1;
    pad_edge = 4'b1011;
    ifm_L_channel = 1;// ifm_L_channel>>4
    ifm_L = 112;
    ifm_H = 112;
    featuremap_W = 224;
    featuremap_H = 224;
    
    #1000000
    en = 0;
    #5000000
    $finish;
end

inbuff_address inbuff_address(
    .clk(clk),
    .rst(rst),
    .en(en),
    .ifm_L_channel(ifm_L_channel),
    .ifm_L(ifm_L),
    .ifm_H(ifm_H),
    .featuremap_W(featuremap_W),
    .featuremap_H(featuremap_H),
    .kernel_size(kernel_size),
    .pad_edge(pad_edge),
    .stride(stride),
    .address(address),
    .done_tile(done_tile),
    .last_tile(last_tile),
    .reset(reset),
    .tile_num(tile_num)
    );
    
    reg [33*64-1:0] din;
    integer i;
    initial begin
        din = 0;
        for (i = 0; i < 33; i = i + 1) begin
            din[i*64 +: 64] = {8{ i[7:0] }};
        end
    end    
    
mask mask
    (
    .clk(clk),
    .rst(rst),
    .kernel_size(kernel_size),
    .stride(stride),
    .tready(en),
    .reset(reset),
    .din(din),//4bit * 16channels * 33
    .select_act(select_act), //4bit * 14mac * 16nums
    .out_valid(out_valid)
    );


endmodule
