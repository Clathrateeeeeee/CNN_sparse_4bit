`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/27 16:01:22
// Design Name: 
// Module Name: top
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


module top#(
    parameter Ram_Row = 33,
    parameter Axi_Width = 64,
    parameter Ifm_Width = 10,
    parameter Write_Data_Width = 64,
    parameter Read_Data_Width = 64,
    parameter Write_Addr_Width = 9,
    parameter Read_Addr_Width = 9,
    parameter PE_MACS=14,
    parameter Activation_Data_width = 4,
    parameter Use_Primitives_OReg = 0,
    parameter parallel_channels=64
)(
    input clk,
    input rst,
    input act_ctrl_start,
    input ddr_write_start,
    input [1:0]net_sele,
    //AXI-Stream Slave
    input [Axi_Width-1: 0] act_s_axis_tdata,
    input act_s_axis_tvalid,
    output act_s_axis_tready,
    //weight_buff
    input weight_buff_en,
    input weight_buff_start,
    input [Axi_Width-1: 0] weight_s_axis_tdata,
    input weight_s_axis_tvalid,
    output weight_s_axis_tready,
    //index_buff
    input index_buff_en,
    input index_buff_start,
    input [Axi_Width-1: 0] index_s_axis_tdata,
    input index_s_axis_tvalid,
    output index_s_axis_tready,
    //c_psum
    output wire [19711:0] o_cpsum,
    output wire o_finish
    );
    
wire finished;
wire [2*Ifm_Width-1:0] ifm_L_channel;
wire [Ifm_Width-1:0] ifm_L,ifm_H;
wire [2:0] kernel_size;
wire [1:0] stride;

wire [3:0] pad_edge;
wire pad_top = pad_edge[3];
wire pad_bot = pad_edge[2];
wire pad_lef = pad_edge[1];
wire pad_rig = pad_edge[0];

wire [Ifm_Width-1:0] channels;

wire [8:0] addrout;
wire enout;

wire ping_pong_read,ping_pong_write;
wire reset;
    
act_ctrl act_ctrl(
    //input
    .clk(clk),
    .rst(rst),
    .en(act_ctrl_start),
    
    .finished(finished),
    .net_sele(net_sele),
    //output
    .ifm_L_channel(ifm_L_channel),
    .ifm_L(ifm_L),
    .ifm_H(ifm_H),
    .kernel_size(kernel_size),
    .stride(stride),
    .pad_edge(pad_edge),
    .channels(channels),
    .addrout(addrout),
    .enout(enout),
    
    .ping_pong_write(ping_pong_write),
    .ping_pong_read(ping_pong_read),
    
    .reset(reset)
);

wire [19:0] ifm_L_channel_temp = ifm_L * channels;
wire [Ram_Row*Read_Data_Width-1: 0] dout;

Inbuff#(
    .Ram_Row(Ram_Row),
    .Axi_Width(Axi_Width),
    .Ifm_Width(Ifm_Width),
    .Write_Data_Width(Write_Data_Width),
    .Read_Data_Width(Read_Data_Width),//16bit-->64bit
    .Write_Addr_Width(Write_Addr_Width),
    .Read_Addr_Width(Read_Addr_Width),//11-->9 
    .Use_Primitives_OReg(Use_Primitives_OReg)
)
Inbuff(
    .clki(clk),
    .rst(rst),
    .start(ddr_write_start),//from DDR
    
    .finished(finished), //output
    
    .mode_sel(1),
    .ifm_L_channel(ifm_L_channel_temp),
    .ifm_L(ifm_L),
    .ifm_H(ifm_H),
    .kernel_size(kernel_size),
    .stride(stride),
    .pad_edge(pad_edge),
    .channels(channels),
    
    .ping_pong_write(ping_pong_write),
    .ping_pong_read(ping_pong_read),
    
    .clkout(clk),
    .enout(enout),
    .addrout(addrout),
    .dout(dout),
    
    .s_axis_tdata(act_s_axis_tdata),
    .s_axis_tvalid(act_s_axis_tvalid),
    .s_axis_tready(act_s_axis_tready)
);

//mask interface
wire [16*Axi_Width-1:0]index;
wire [63:0]sele_outvalid;
wire [448*64-1:0] valid_act;

//mask2selector
mask2selector#(
    .deep(512),
    .Ram_Row(Ram_Row),
    .Data_Width(64)
)mask2selector(
    //mask
    .clk(clk),
    .rst(rst),
    .kernel_size(kernel_size),
    .stride(stride),
    .inbuff_ready(enout),
    .reset(reset),
    .din(dout),//4bit * 16channels * 33
    //selector
    .index(index),
    .sele_outvalid(sele_outvalid),
    .valid_act(valid_act)
);

        //parameter
        wire [8959:0] cc_result;
        wire [2048:0] w_buff_data;
        wire [15:0] k_k_channels = kernel_size * kernel_size * channels;
        //parameter
        wire [3:0] OutH_14 = (((ifm_H+pad_top+pad_bot-kernel_size)/stride+1)%14==0)?((ifm_H+pad_top+pad_bot-kernel_size)/stride+1)/14:((ifm_H+pad_top+pad_bot-kernel_size)/stride+1)/14+1'b1;
        wire [4:0] Ow_times = (ifm_L+pad_lef+pad_rig-kernel_size)/stride+1;
        wire [8:0] Addrtimes_end = OutH_14 * Ow_times;
        
weight_sign_buff_read_ctrl#(
    .Ifm_Width(Ifm_Width),
    .weight_sign_Ram_Row(32),
    .weight_sign_Axi_Width(64),
    .weight_sign_Write_Data_Width(64),
    .weight_sign_Read_Data_Width(64),//16bit-->64bit
    .weight_sign_Write_Addr_Width(11),
    .weight_sign_Read_Addr_Width(11)
)
weight_sign_buff_read_ctrl(
    .clk(clk),
    .value_en(weight_buff_en),//weight wirte en is different with the inbuff read en
    .weight_sign_Sys_start(weight_buff_start),//start 1clock
    .rst(rst),
    .Addrtimes_end(Addrtimes_end),// OutH_14*Ow_times   (mac=14)  Ow_times = ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1
    .k_k_channels(k_k_channels),
    //output
    .valid(),
    //axis_fifo
    .weight_sign_s_axis_tdata(weight_s_axis_tdata),
    .weight_sign_s_axis_tvalid(weight_s_axis_tvalid),
    .weight_sign_s_axis_tready(weight_s_axis_tready),
    .en_to_fifo(enout),
    .dout(w_buff_data)
);

index_buff_read_ctrl#(
    .Ifm_Width(Ifm_Width),
    .weight_sign_Ram_Row(16),
    .weight_sign_Axi_Width(64),
    .weight_sign_Write_Data_Width(64),
    .weight_sign_Read_Data_Width(64),//16bit-->64bit
    .weight_sign_Write_Addr_Width(11),
    .weight_sign_Read_Addr_Width(11)
)
index_buff_read_ctrl(
    .clk(clk),
    .value_en(index_buff_en),//weight wirie en is different with the inbuff read en
    .weight_sign_Sys_start(index_buff_start),//start 1clock
    .rst(rst),
    .Addrtimes_end(Addrtimes_end),// OutH_14*Ow_times   (mac=14)  Ow_times = ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1
    .k_k_channels(k_k_channels),
    //output
    .valid(),
    //axis_fifo
    .weight_sign_s_axis_tdata(index_s_axis_tdata),
    .weight_sign_s_axis_tvalid(index_s_axis_tvalid),
    .weight_sign_s_axis_tready(index_s_axis_tready),
    .en_to_fifo(enout),
    .dout(index)
);

computing_core computing_core(
    .clk(clk),
    .i_Weight(w_buff_data),
    .i_Activation(valid_act),
    .o_result(cc_result)
);



c_psum#(
    .mac_number(14),
    .pe_number(64),
    .width(10),
    .c_number_max(64)
)
c_psum(
    //c_c
    .clk(clk),
    .rst(rst),
    .in_valid(sele_outvalid),
    .i_result(cc_result),
    //control
    .kernel(kernel_size),
    .c_tile_in(channels),
    //output
    .o_cpsum(o_cpsum),
    .o_finish(o_finish)
);

endmodule
