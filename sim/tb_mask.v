`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/22 20:09:53
// Design Name: 
// Module Name: tb_mask
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

module tb_mask;

    // 参数和模块保持一致
    localparam Ram_Row    = 33;
    localparam Data_Width = 64;
    localparam Pe_Mac     = 14;
    localparam deep       = 512;

    reg clk;
    reg rst;
    reg [2:0] kernel_size;
    reg [1:0] stride;
    reg       tready;
    reg [$clog2(deep):0] ram_deep;
    reg [Data_Width*Ram_Row-1:0] din;

    wire [Pe_Mac*Data_Width-1:0] select_act;

    // DUT 实例化
    mask #(
        .Ram_Row(Ram_Row),
        .Data_Width(Data_Width),
        .Pe_Mac(Pe_Mac),
        .deep(deep)
    ) u_mask (
        .clk(clk),
        .rst(rst),
        .kernel_size(kernel_size),
        .stride(stride),
        .tready(tready),
        .din(din),
        .select_act(select_act)
    );

    // 生成时钟
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    // 初始化 din：每64bit一个不同的值
    integer i;
    initial begin
        din = 0;
        for (i = 0; i < Ram_Row; i = i + 1) begin
            din[i*Data_Width +: Data_Width] = {8{ i[7:0] }};
        end
    end

    // 激励信号 dont use k7s1
    initial begin
        rst = 1;
        tready = 0;
        kernel_size = 3;
        stride = 1;

        #20 rst = 0;

        #10 tready = 1; 
        

        #50000 $finish;
    end

endmodule

