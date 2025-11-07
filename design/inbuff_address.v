`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/08 19:57:19
// Design Name: 
// Module Name: inbuff_address
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


module inbuff_address(
    //sign
    input clk,
    input rst,
    input en,
    //tile parameter
    input [19:0]ifm_L_channel,
    input [9:0]ifm_L, //smaller than 512
    input [9:0]ifm_H,
    //cnn parameter
    input [9:0]featuremap_W,
    input [9:0]featuremap_H,
    input [2:0]kernel_size,
    input [1:0]stride,
    input [3:0]pad_edge,
    //output
    output reg [8:0]address,
    output reg done_tile,
    output wire last_tile,
    output reg out_last,
    output wire reset,
    //cnn paramter
    output reg [4:0]tile_num
    );
    
    reg [8:0] offset;
    reg [8:0] kernel_group;
    reg [7:0] hold_cnt;
    wire pad_top = pad_edge[3];
    wire pad_bot = pad_edge[2];
    wire pad_lef = pad_edge[1];
    wire pad_rig = pad_edge[0];
    wire [4:0] tile_w_count = (featuremap_W + (kernel_size - stride))%(ifm_L+pad_lef+pad_rig)?(featuremap_W + (kernel_size - stride))/(ifm_L+pad_lef+pad_rig)+1:(featuremap_W + (kernel_size - stride))/(ifm_L+pad_lef+pad_rig);
    wire [4:0] tile_h_count = (featuremap_H + (kernel_size - stride))%(ifm_H+pad_top+pad_bot)?(featuremap_H + (kernel_size - stride))/(ifm_H+pad_top+pad_bot)+1:(featuremap_H + (kernel_size - stride))/(ifm_H+pad_top+pad_bot);
    wire [4:0] bram_h_count = ((ifm_H + pad_top + pad_bot - (kernel_size - stride))%28)?((ifm_H + pad_top + pad_bot - (kernel_size - stride))/28)+1:((ifm_H + pad_top + pad_bot - (kernel_size - stride))/28);
    wire [4:0] bram_h_last_count = (ifm_H + pad_top + pad_bot - (kernel_size - stride))%28;//最后一块H上的剩余bram条数
    wire [8:0] group = ((ifm_L+pad_lef+pad_rig) - kernel_size)/stride + 1;
    wire [3:0] hold_times = (stride==1)?2*kernel_size:kernel_size;
    assign reset = (kernel_group == group - 1 && address == offset + kernel_size * ifm_L_channel - 1 && hold_cnt == hold_times - 1);
    reg reset_r;    
    reg [4:0] bram_h_num;
    wire reset_s1 = (reset_r == 1 && reset)?1'b1:1'b0;
    wire reset_s = (stride==1 && ifm_H>(14+(kernel_size-stride)))?(bram_h_num == bram_h_count - 1 && bram_h_last_count<16)?reset:reset_s1:reset;

    always@(posedge clk)begin
        if(rst)
            bram_h_num <= 0;
        else if(bram_h_num == bram_h_count - 1 && reset_s)
            bram_h_num <= 0;
        else if(reset_s)
            bram_h_num <= bram_h_num + 1;
        else
            bram_h_num <= bram_h_num;
    end
    always@(posedge clk)begin
        if(rst)
            reset_r <= 0;
        else if(bram_h_num == bram_h_count - 1 && reset_s)
            reset_r <= 0;
        else if(reset_r == 1 && reset)
            reset_r <= 0;
        else if(reset)
            reset_r <= 1;
        else
            reset_r <= reset_r;
    end
   
    always @(posedge clk) begin
        if (rst) begin
            address <= 0;
            offset  <= 0;  
            hold_cnt <= 0;
        end
        else if(done_tile)begin
            address <= 0;
            offset <= 0;
            hold_cnt <= 0;
        end
        else if(reset && reset_s)begin
            address <= (bram_h_num+1)*(ifm_L+pad_lef+pad_rig);
            offset <= (bram_h_num+1)*(ifm_L+pad_lef+pad_rig);
            hold_cnt <= 0;
        end
        else if(reset)begin
            address <= (bram_h_num)*(ifm_L+pad_lef+pad_rig);
            offset <= (bram_h_num)*(ifm_L+pad_lef+pad_rig);
            hold_cnt <= 0;
        end
        else if (en) begin
            if (hold_cnt == hold_times - 1) begin
                hold_cnt <= 0;
                if (address == offset + kernel_size * ifm_L_channel - 1) begin
                    offset  <= offset + stride * ifm_L_channel;
                    address <= offset + stride * ifm_L_channel; 
                end
                else begin
                    address <= address + 1;
                end
            end
            else begin
                hold_cnt <= hold_cnt + 1; 
                address <= address;        
                offset  <= offset;
            end
        end
        else begin
            hold_cnt <= 0;
            address  <= address;
            offset   <= offset;
        end
    end
    
    always@(posedge clk)begin
        if(rst)begin
            kernel_group <= 0;
        end
        else if(reset)
            kernel_group <= 0;
        else if(hold_cnt == hold_times - 1 && address == offset + kernel_size * ifm_L_channel - 1) begin
            kernel_group <= kernel_group + 1;
        end
        else
            kernel_group <= kernel_group;
    end
        
    always@(posedge clk)begin
        if(rst)
            done_tile = 0;
        else if(bram_h_num == bram_h_count - 1 && reset_s)
            done_tile = 1;
        else 
            done_tile = 0;
    end
 
    always@(posedge clk)begin
        if(rst)begin
            tile_num <= 0;
        end
        else if(en &&( tile_num == (tile_w_count * tile_h_count - 1)) && reset_s && bram_h_num == bram_h_count - 1)begin
            tile_num <= 0;
        end
        else if(en && done_tile)begin
            tile_num <= tile_num + 1;
        end
        else begin
            tile_num <= tile_num;
        end
    end
    
    always@(posedge clk)begin
        if(rst)
            out_last <= 0;
        else if(last_tile && reset_s && bram_h_num == bram_h_count - 1)
            out_last <= 1;
        else
            out_last <= 0;
    end
    
    assign last_tile = (en && tile_num == tile_w_count * tile_h_count - 1)?1'b1:1'b0;
    
endmodule
