`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/03 19:51:55
// Design Name: 
// Module Name: tb_computing_core
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


module tb_computing_core();

    //=============================
    // 参数定义
    //=============================
    parameter WEIGHT_WIDTH = 2048;     // 64*32
    parameter ACT_WIDTH    = 64*448;   // 28672
    parameter RESULT_WIDTH = 8960;     // 64*140 (from design)

    //=============================
    // 信号声明
    //=============================
    reg clk;
    reg [WEIGHT_WIDTH-1:0] i_Weight;
    reg [ACT_WIDTH-1:0]    i_Activation;
    wire [RESULT_WIDTH-1:0] o_result;

    //=============================
    // DUT 实例化
    //=============================
    computing_core uut (
        .clk(clk),
        .i_Weight(i_Weight),
        .i_Activation(i_Activation),
        .o_result(o_result)
    );

    //=============================
    // 时钟产生
    //=============================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz
    end

    //=============================
    // 激励产生
    //=============================
    integer i;
    reg [31:0] rand_w[0:63];
    reg [447:0] rand_a[0:63];

    // 新增的数组用于存储和显示权重、激活和输出
    reg [31:0] weight_array[0:63];    // 32 bits 位宽的权重数组
    reg [447:0] activation_array[0:63]; // 448 bits 位宽的激活数组
    reg [9:0] result_array[0:895];    // 10 bits 位宽的输出数组

    initial begin
        // 初始化
        i_Weight     = 0;
        i_Activation = 0;

        // 随机数生成（可以多次）
        for (i = 0; i < 64; i = i + 1) begin
            rand_w[i] = $random;  // 32-bit 随机数
            rand_a[i] = {$random, $random, $random, $random, $random, $random, $random, $random,
                         $random, $random, $random, $random, $random, $random}; // 拼成448bit
        end

        // 拼接为输入向量
        for (i = 0; i < 64; i = i + 1) begin
            i_Weight[i*32 +: 32]      = rand_w[i];
            i_Activation[i*448 +: 448] = rand_a[i];
            weight_array[i]           = rand_w[i];               // 保存到权重数组
            activation_array[i]       = rand_a[i];               // 保存到激活数组
        end

        // 稍等几个时钟
        #20;

        // 再生成第二组随机输入（验证动态变化）
        for (i = 0; i < 64; i = i + 1) begin
            rand_w[i] = $random;
            rand_a[i] = {$random, $random, $random, $random, $random, $random, $random, $random,
                         $random, $random, $random, $random, $random, $random};
        end

        // 拼接为输入向量
        for (i = 0; i < 64; i = i + 1) begin
            i_Weight[i*32 +: 32]      = rand_w[i];
            i_Activation[i*448 +: 448] = rand_a[i];
            weight_array[i]           = rand_w[i];               // 保存到权重数组
            activation_array[i]       = rand_a[i];               // 保存到激活数组
        end


        #100;
        $finish;
    end

endmodule
