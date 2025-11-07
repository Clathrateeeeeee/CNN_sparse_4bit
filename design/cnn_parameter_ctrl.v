`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/08 14:30:03
// Design Name: 
// Module Name: cnn_parameter_ctrl
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


module cnn_parameter_ctrl#(
    parameter Ifm_width = 10,
    parameter resnet20_conv_num = 21
)(
    //normal
    input clk,
    input rst,
    input start,
    input [1:0] net_sele,
    //tile number count
    input [4:0] tile_num,
    input out_last,
    //CNN parameters output 
    output reg [Ifm_width*2-1:0]ifm_L_channel,//tile_c inbuffaddress
    output reg [Ifm_width-1:0]ifm_L,
    output reg [Ifm_width-1:0]ifm_H,
    output reg [3:0]pad_edge,
    output reg [2:0]kernel_size,
    output reg [1:0]stride,
    output reg [Ifm_width-1:0]channels,//channel numbers need to be tansfered. 
    //inbuff_address2cnn_parameter
    output reg [Ifm_width-1:0]featuremap_W,
    output reg [Ifm_width-1:0]featuremap_H
    );
    
    //Divisible signal
    wire w_full_divide = (featuremap_W % ifm_L)?1'b0:1'b1;
    wire [4:0] full_divide_num = w_full_divide?(featuremap_W / ifm_L):(featuremap_W / ifm_L)+1;
    
    //location
    integer tile_row,tile_col;
    always@(*)begin
        tile_row = tile_num % full_divide_num;
        tile_col = tile_num / full_divide_num;
    end
    
    //state
    reg [4:0] c_state,n_state;
    
    //i_done
    reg out_last_r;
    always@(posedge clk)begin
        if(rst)
            out_last_r <= 0;
        else
            out_last_r <= out_last;
    end
    wire i_done = (!out_last && out_last_r)?1'b1:1'b0;
    wire pad_top = pad_edge[3];
    wire pad_bot = pad_edge[2];
    wire pad_lef = pad_edge[1];
    wire pad_rig = pad_edge[0];
    wire [3:0] bram_h_max = (512 / (ifm_L*(channels>>4) + pad_lef + pad_rig));
    wire [15:0] ifm_H_max = (28 * bram_h_max) + (kernel_size - stride)- pad_top - pad_bot - 1;
    
    //param
    localparam idle = 5'd0;
    //the first conv
    localparam conv_start =5'd1;
    //group1
    localparam conv1_1_1 = 5'd2;
    localparam conv1_1_2 = 5'd3;
    localparam conv1_2_1 = 5'd4;
    localparam conv1_2_2 = 5'd5;
    localparam conv1_3_1 = 5'd6;
    localparam conv1_3_2 = 5'd7;
    //group2
    localparam conv2_1_1 = 5'd8;
    localparam conv2_1_2 = 5'd9;
    localparam conv2_2_1 = 5'd10;
    localparam conv2_2_2 = 5'd11;
    localparam conv2_3_1 = 5'd12;
    localparam conv2_3_2 = 5'd13;
    //group3
    localparam conv3_1_1 = 5'd14;
    localparam conv3_1_2 = 5'd15;
    localparam conv3_2_1 = 5'd16;
    localparam conv3_2_2 = 5'd17;
    localparam conv3_3_1 = 5'd18;
    localparam conv3_3_2 = 5'd19;
    
    //initial
    always@(posedge clk)begin
        if(rst)
            c_state <= idle;
        else 
            c_state <= n_state;
    end
    //fsm
    always@(*)begin
        case(c_state)
        idle:begin
            if(start) 
                n_state = conv_start;
            else 
                n_state = idle;
        end
        default:begin
            if(c_state >= conv_start && c_state <conv3_3_2)begin
                if(i_done)
                    n_state = c_state + 1;
                else 
                    n_state = c_state;
            end
            else if(net_sele==1 && c_state == conv3_3_2)begin
                if(i_done)
                    n_state = idle;
                else if(net_sele==1 && c_state == conv2_3_2)
                    if(i_done)
                        n_state = idle;
                    else
                        n_state = conv2_3_2;
                else
                    n_state = conv3_3_2;
            end
            else 
                n_state = idle;
        end
        endcase
    end
    //work
    always@(posedge clk)begin
        if(rst)begin
            kernel_size <= 3'd0;
            stride      <= 2'd0;
            channels    <= 10'd0;
            ifm_L       <= 10'd0;
            ifm_H       <= 10'd0;
            featuremap_W<= 10'd0;
            featuremap_H<= 10'd0;
            ifm_L_channel <= 20'd0;
    end else begin
    case(net_sele)
        2'd1://resnet20
            case(c_state)
                //start group1
                conv_start,conv1_1_1, conv1_1_2, conv1_2_1, conv1_2_2, conv1_3_1, conv1_3_2:begin //1-7
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd16;//16 32 64 tile_c
                    ifm_L       <= 10'd32;
                    ifm_H       <= 10'd32;
                    featuremap_W<= 10'd32;
                    featuremap_H<= 10'd32;
                    ifm_L_channel <= 20'd16;//channels * ifm_L
                end
                // group 2
                conv2_1_1:begin //8
                    kernel_size <= 3'd3;
                    stride      <= 2'd2;
                    channels    <= 10'd16;
                    ifm_L       <= 10'd16;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd16;
                    featuremap_H<= 10'd16;
                    ifm_L_channel <= 20'd16;//32
                end
                conv2_1_2, conv2_2_1, conv2_2_2, conv2_3_1, conv2_3_2: begin //9-13
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd32;
                    ifm_L       <= 10'd16;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd16;
                    featuremap_H<= 10'd16;
                    ifm_L_channel <= 20'd32;//32
                end
                // group 3
                conv3_1_1: begin //14
                    kernel_size <= 3'd3;
                    stride      <= 2'd2;
                    channels    <= 10'd32;
                    ifm_L       <= 10'd8;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd8;
                    featuremap_H<= 10'd8;
                    ifm_L_channel <= 20'd32;//64
                end
                conv3_1_2, conv3_2_1, conv3_2_2, conv3_3_1, conv3_3_2: begin //15-19
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd64;
                    ifm_L       <= 10'd8;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd8;
                    featuremap_H<= 10'd8;
                    ifm_L_channel <= 20'd64;//64
                end
                default: begin
                    kernel_size <= kernel_size;
                    stride      <= stride;
                    channels    <= channels;
                    ifm_L       <= ifm_L;
                    ifm_H       <= ifm_H;
                    featuremap_W<= featuremap_W;
                    featuremap_H<= featuremap_H;
                    ifm_L_channel <= ifm_L_channel;
                end
            endcase
        2'd2://vgg16
            case(c_state)
                //start group1
                conv_start:begin //1
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd16;//16 32 64 tile_c
                    ifm_L       <= 10'd112;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd224;
                    featuremap_H<= 10'd224;
                    ifm_L_channel <= 20'd16;//channels * ifm_L
                end
                conv1_1_1:begin//2
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd64;//16 32 64 tile_c
                    ifm_L       <= 10'd112;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd224;
                    featuremap_H<= 10'd224;
                    ifm_L_channel <= 20'd64;//channels * ifm_L
                end
                conv1_1_2:begin//3
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd64;//16 32 64 tile_c
                    ifm_L       <= 10'd112;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd112;
                    featuremap_H<= 10'd112;
                    ifm_L_channel <= 20'd64;//channels * ifm_L
                end
                conv1_2_1:begin//4
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd128;//16 32 64 tile_c
                    ifm_L       <= 10'd56;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd112;
                    featuremap_H<= 10'd112;
                    ifm_L_channel <= 20'd128;//channels * ifm_L
                end
                conv1_2_2:begin//5
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd128;//16 32 64 tile_c
                    ifm_L       <= 10'd56;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd56;
                    featuremap_H<= 10'd56;
                    ifm_L_channel <= 20'd128;//channels * ifm_L
                end
                conv1_3_1,conv1_3_2:begin//6 7
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd256;//16 32 64 tile_c
                    ifm_L       <= 10'd28;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd56;
                    featuremap_H<= 10'd56;
                    ifm_L_channel <= 20'd256;//channels * ifm_L
                end
                conv2_1_1:begin//8
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd256;//16 32 64 tile_c
                    ifm_L       <= 10'd28;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd28;
                    featuremap_H<= 10'd28;
                    ifm_L_channel <= 20'd256;//channels * ifm_L
                end
                conv2_1_2,conv2_2_1:begin//9 10
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd512;//16 32 64 tile_c
                    ifm_L       <= 10'd14;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd28;
                    featuremap_H<= 10'd28;
                    ifm_L_channel <= 20'd512;//channels * ifm_L
                end
                conv2_2_2,conv2_3_1,conv2_3_2:begin//11 12 13
                    kernel_size <= 3'd3;
                    stride      <= 2'd1;
                    channels    <= 10'd512;//16 32 64 tile_c
                    ifm_L       <= 10'd14;
                    ifm_H       <= (featuremap_H>28)?ifm_H_max:featuremap_H;
                    featuremap_W<= 10'd14;
                    featuremap_H<= 10'd14;
                    ifm_L_channel <= 20'd512;//channels * ifm_L
                end
                default: begin
                    kernel_size <= kernel_size;
                    stride      <= stride;
                    channels    <= channels;
                    ifm_L       <= ifm_L;
                    ifm_H       <= ifm_H;
                    featuremap_W<= featuremap_W;
                    featuremap_H<= featuremap_H;
                    ifm_L_channel <= ifm_L_channel;
                end
            endcase
        default:begin
                    kernel_size <= kernel_size;
                    stride      <= stride;
                    channels    <= channels;
                    ifm_L       <= ifm_L;
                    ifm_H       <= ifm_H;
                    featuremap_W<= featuremap_W;
                    featuremap_H<= featuremap_H;
                    ifm_L_channel <= ifm_L_channel;
                end
        endcase
    end
end

    //pad_edge
    always@(posedge clk)begin
        if(rst)
            pad_edge <= 4'b0000;
        else
        case(ifm_L<featuremap_W)
        1'b1:
        if (tile_row == 0 && tile_col == 0)
            pad_edge <= 4'b1010; // left_up
        else if (tile_row == 0 && tile_col == full_divide_num-1)
            pad_edge <= 4'b1001; // right_up
        else if (tile_row == full_divide_num-1 && tile_col == 0)
            pad_edge <= 4'b0110; // left_down
        else if (tile_row == full_divide_num-1 && tile_col == full_divide_num-1)
            pad_edge <= 4'b0101; // right_down             
        else if (tile_row == 0 && tile_col > 0 && tile_col < full_divide_num-1)
            pad_edge <= 4'b1000; // top edge
        else if (tile_row == full_divide_num-1 && tile_col > 0 && tile_col < full_divide_num-1)
            pad_edge <= 4'b0100; // bottom edge
        else if (tile_col == 0 && tile_row > 0 && tile_row < full_divide_num-1)
            pad_edge <= 4'b0010; // left edge
        else if (tile_col == full_divide_num-1 && tile_row > 0 && tile_row < full_divide_num-1)
            pad_edge <= 4'b0001; // right edge
        else
            pad_edge <= 4'b0000; // center
        1'b0:
        if (tile_row == 0 && tile_col == 0)
            pad_edge <= 4'b1011; // top
        else if(tile_row == 0 && tile_col > 0 && tile_col < full_divide_num - 1)
            pad_edge <= 4'b0011; // mid
        else if(tile_row == 0 && tile_col == full_divide_num - 1)
            pad_edge <= 4'b0111; // bottom
        default:pad_edge<=pad_edge;
        endcase                            
    end
    
endmodule
