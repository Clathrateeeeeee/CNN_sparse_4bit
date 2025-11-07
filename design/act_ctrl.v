`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/16 15:26:26
// Design Name: 
// Module Name: act_ctrl
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


module act_ctrl(
    input clk,
    input rst,
    input en,
    
    input finished,
    input [1:0]net_sele,
    
    output wire [19:0]ifm_L_channel,
    output wire [9:0] ifm_L,
    output wire [9:0] ifm_H,
    output wire [2:0] kernel_size,
    output wire [1:0] stride,
    output wire [3:0] pad_edge,
    output wire [9:0] channels,
    output wire [8:0] addrout,
    output wire enout,
    
    output wire ping_pong_write,
    output wire ping_pong_read,
    
    output wire reset
    );
    
wire done_tile,last_tile,out_last;
wire [4:0] tile_num;
wire [9:0] featuremap_W,featuremap_H;
    
ping_pong_ctrl ping_pong_ctrl
(
    //normal
    .clki(clk),
    .rst(rst),
    .Ctrl_start(en),
    //inbuff_adress
    .done_tile(done_tile),
    .last_tile(last_tile),
    .write_finish(finished),
    //output
    .ping_pong_write(ping_pong_write),
    .ping_pong_read(ping_pong_read),
    .inbuffer_enout(enout)
);
wire [19:0] ifm_L_channel_d16 = ifm_L_channel >> 4;// / 16,one 64bits data has 16 mult 4bits data

inbuff_address inbuff_address(
    //normal
    .clk(clk),
    .rst(rst),
    .en(enout),
    //tile parameter
    .ifm_L_channel(ifm_L_channel_d16),
    .ifm_L(ifm_L),
    .ifm_H(ifm_H),
    //cnn parameter
    .featuremap_W(featuremap_W),
    .featuremap_H(featuremap_H),
    .kernel_size(kernel_size),
    .stride(stride),
    .pad_edge(pad_edge),
    //output
    .address(addrout),
    .done_tile(done_tile),
    .last_tile(last_tile),
    .out_last(out_last),
    .reset(reset),
    //cnn parameter
    .tile_num(tile_num)
);

cnn_parameter_ctrl #(
    .Ifm_width(10),
    .resnet20_conv_num(21)
)cnn_parameter_ctrl(
    //normal
    .clk(clk),
    .rst(rst),
    .start(en),
    .net_sele(net_sele),
    //tile number count
    .tile_num(tile_num),
    .out_last(out_last),//last_tile finish signal
    //cnn parameters output
    .ifm_L_channel(ifm_L_channel),
    .ifm_L(ifm_L),
    .ifm_H(ifm_H),
    .pad_edge(pad_edge),
    .kernel_size(kernel_size),
    .stride(stride),
    .channels(channels),
    //inbuff_address2cnn_parameter
    .featuremap_W(featuremap_W),
    .featuremap_H(featuremap_H)
);

endmodule
