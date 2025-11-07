`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/27 15:06:00
// Design Name: 
// Module Name: mask2selector
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


`timescale 1ns / 1ps
module mask2selector#(
    parameter deep       = 512,
    parameter Ram_Row    = 33,
    parameter Data_Width = 64
)(
    input clk,
    input rst,
    input [2:0] kernel_size,
    input [1:0] stride,
    input inbuff_ready,
    input reset,
    input [Data_Width*Ram_Row-1:0] din,
    input [16*Data_Width-1:0] index,
    output [Data_Width-1:0] sele_outvalid,
    output [448*Data_Width-1:0] valid_act
);

    wire [895:0] act_middle;
    wire valid;

    // mask 实例化
    mask mask_uut(
        .clk(clk),
        .rst(rst),
        .kernel_size(kernel_size),
        .stride(stride),
        .tready(inbuff_ready),
        .reset(reset),
        .din(din),
        .select_act(act_middle),
        .out_valid(valid)
    );

    // --------------------------
    // 流水寄存器分组，降低扇出
    // --------------------------
    reg [895:0] act_reg [0:3];   // act_middle 复制 4 组
    reg [3:0] valid_reg;         // valid 复制 4 组
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            act_reg[0] <= 0;
            act_reg[1] <= 0;
            act_reg[2] <= 0;
            act_reg[3] <= 0;
            valid_reg <= 0;
        end else begin
            for (i = 0; i < 4; i = i + 1) begin
                act_reg[i] <= act_middle;
                valid_reg[i] <= valid;
            end
        end
    end

    // --------------------------
    // 生成 valid_lv2，64-bit，每16个复制一次
    // --------------------------
    wire [63:0] valid_lv2;
    genvar k;
    generate
        for (k = 0; k < 64; k = k + 1) begin : gen_valid_lv2
            assign valid_lv2[k] = valid_reg[k/16];
        end
    endgenerate

    // --------------------------
    // 生成 act_group，64组，每组对应 16 个 selector
    // --------------------------
    wire [895:0] act_group [0:63];
    genvar j;
    generate
        for (j = 0; j < 64; j = j + 1) begin : gen_act_group
            assign act_group[j] = act_reg[j/16];
        end
    endgenerate

    // --------------------------
    // selector_14groups 实例化
    // --------------------------
    genvar m;
    generate
        for (m = 0; m < Data_Width; m = m + 1) begin : gen_selector
            selector_14groups u_sel (
                .clk(clk),
                .in_valid(valid_lv2[m]),
                .weight(index[(m+1)*16-1:m*16]),
                .in_act(act_group[m]),
                .out_valid(sele_outvalid[m]),
                .valid_act(valid_act[(m+1)*448-1:m*448])
            );
        end
    endgenerate

endmodule



