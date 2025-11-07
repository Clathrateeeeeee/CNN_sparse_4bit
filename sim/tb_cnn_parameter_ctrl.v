`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/08 17:13:20
// Design Name: 
// Module Name: tb_cnn_parameter_ctrl
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


module tb_cnn_parameter_ctrl;

    // 参数定义
    parameter Ifm_Width = 9;
    parameter resnet20_conv_num = 21;

    // 信号定义
    reg clk;
    reg rst;
    reg start;
    
    reg [4:0]tile_num;
    reg out_last;

    wire [Ifm_Width*2-1:0] ifm_L_channel;
    wire [Ifm_Width-1:0] ifm_L;
    wire [Ifm_Width-1:0] ifm_H;
    wire [3:0] pad_edge;
    wire [2:0] kernel_size;
    wire [1:0] stride;
    wire [8:0] channels;
    
    wire [Ifm_Width-1:0]featuremap_W;
    wire [Ifm_Width-1:0]featuremap_H;

    // 实例化 DUT
    cnn_parameter_ctrl #(
        .Ifm_Width(Ifm_Width),
        .resnet20_conv_num(resnet20_conv_num)
    ) cnn_parameter_ctrl (
        //in
        .clk(clk),
        .rst(rst),
        .start(start),
        .out_last(out_last),
        .tile_num(tile_num),
        //out
        .ifm_L_channel(ifm_L_channel),
        .ifm_L(ifm_L),
        .ifm_H(ifm_H),
        .pad_edge(pad_edge),
        .kernel_size(kernel_size),
        .stride(stride),
        .channels(channels),
        .featuremap_W(featuremap_W),
        .featuremap_H(featuremap_H)
    );

    // 时钟生成
    initial clk = 0;
    always #5 clk = ~clk;  // 100MHz时钟，周期10ns

    // i_done 每200个clk周期产生一个高脉冲
    reg [7:0] i_done_counter;
    initial begin
        out_last = 0;
        i_done_counter = 0;
        forever begin
            @(posedge clk);
            if(i_done_counter == 199) begin
                out_last <= 1;
                i_done_counter <= 0;
            end else begin
                out_last <= 0;
                i_done_counter <= i_done_counter + 1;
            end
        end
    end

    // 测试序列
    initial begin
        // 初始化
        rst = 1;
        start = 0;
        #20;
        rst = 0;
        #20;

        // 启动操作
        start = 1;
        tile_num = 7;
        #20;
        start = 0;

        // 运行一段时间观察输出
        #200000;

        $finish;
    end

endmodule

