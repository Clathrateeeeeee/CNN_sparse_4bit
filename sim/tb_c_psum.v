`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/03 10:03:02
// Design Name: 
// Module Name: tb_c_psum
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


module tb_c_psum();

    // ---------------------
    // 参数和信号声明
    // ---------------------
    parameter mac_number   = 14;
    parameter pe_number    = 64;
    parameter width        = 10;
    parameter c_number_max = 64;

    reg clk;
    reg rst;
    reg [mac_number*pe_number*width-1:0] i_result;
    reg [2:0] kernel;
    reg [$clog2(c_number_max):0] c_tile_in;

    wire [22*mac_number*pe_number-1:0] o_cpsum;
    wire o_finish;

    // ---------------------
    // DUT 实例化
    // ---------------------
    c_psum #(
        .mac_number(mac_number),
        .pe_number(pe_number),
        .width(width),
        .c_number_max(c_number_max)
    ) uut (
        .clk(clk),
        .rst(rst),
        .i_result(i_result),
        .kernel(kernel),
        .c_tile_in(c_tile_in),
        .o_cpsum(o_cpsum),
        .o_finish(o_finish)
    );

    // ---------------------
    // 时钟生成
    // ---------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz 时钟
    end

    // ---------------------
    // 测试激励
    // ---------------------
    integer idx;
    initial begin
        // 初始化
        rst = 1;
        i_result = 0;
        kernel = 0;
        #20;
        rst = 0;
        kernel = 3;
        c_tile_in = 1;
        for (idx = 0; idx < mac_number*pe_number*width; idx = idx + 1) begin
            i_result[idx] = $urandom % 2;  // 每一位都是随机0或1
        end


        // 结束仿真
        #50000;
        $finish;
    end

endmodule
