`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/03 20:02:06
// Design Name: 
// Module Name: top_fifo_wrap
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


module top_fifo_wrap (
    input  wire clk,
    input  wire rst,
    input  wire act_ctrl_start,
    input  wire ddr_write_start,
    input  wire weight_buff_start,
    input  wire index_buff_start,

    // AXIS 激活输入
    input  wire [63:0] s_axis_act_tdata,
    input  wire s_axis_act_tvalid,
    output wire s_axis_act_tready,

    // AXIS 权重输入
    input  wire weight_buff_en,
    input  wire [63:0] s_axis_weight_tdata,
    input  wire s_axis_weight_tvalid,
    output wire s_axis_weight_tready,

    // AXIS 索引输入
    input  wire index_buff_en,
    input  wire [63:0] s_axis_index_tdata,
    input  wire s_axis_index_tvalid,
    output wire s_axis_index_tready,

    // AXIS 累加输出
    output wire [63:0] m_axis_cpsum_tdata,
    output wire m_axis_cpsum_tvalid,
    input  wire m_axis_cpsum_tready
);


    //=============================
    // FIFO 实例化 (可用 Xilinx AXIS FIFO IP)
    //=============================
    wire [63:0] act_fifo_dout, weight_fifo_dout, index_fifo_dout;
    wire act_fifo_empty, weight_fifo_empty, index_fifo_empty;
    wire act_fifo_rd_en, weight_fifo_rd_en, index_fifo_rd_en;

    axis_fifo_64 u_act_fifo (
        .s_axis_aclk(clk), 
        .s_axis_aresetn(rst),
        .s_axis_tdata(s_axis_act_tdata),
        .s_axis_tvalid(s_axis_act_tvalid),
        .s_axis_tready(s_axis_act_tready),
        .m_axis_tdata(act_fifo_dout),
        .m_axis_tvalid(act_fifo_empty),
        .m_axis_tready(act_fifo_rd_en)
    );

    axis_fifo_64  u_weight_fifo (
        .s_axis_aclk(clk), 
        .s_axis_aresetn(rst),
        .s_axis_tdata(s_axis_weight_tdata),
        .s_axis_tvalid(s_axis_weight_tvalid),
        .s_axis_tready(s_axis_weight_tready),
        .m_axis_tdata(weight_fifo_dout),
        .m_axis_tvalid(weight_fifo_empty),
        .m_axis_tready(weight_fifo_rd_en)
    );

    axis_fifo_64  u_index_fifo (
        .s_axis_aclk(clk), 
        .s_axis_aresetn(rst),
        .s_axis_tdata(s_axis_index_tdata),
        .s_axis_tvalid(s_axis_index_tvalid),
        .s_axis_tready(s_axis_index_tready),
        .m_axis_tdata(index_fifo_dout),
        .m_axis_tvalid(index_fifo_empty),
        .m_axis_tready(index_fifo_rd_en)
    );

    //=============================
    // 实例化原 top 模块
    //=============================
    wire [19711:0] o_cpsum;
    wire o_finish;

    (* DONT_TOUCH = "TRUE" *) top u_top (
        .clk(clk),
        .rst(rst),
        .act_ctrl_start(act_ctrl_start),
        .ddr_write_start(ddr_write_start),

        // 激活流通过FIFO输出驱动
        .act_s_axis_tdata(act_fifo_dout),
        .act_s_axis_tvalid(act_fifo_empty),
        .act_s_axis_tready(act_fifo_rd_en),

        // 权重输入
        .weight_buff_en(weight_buff_en),
        .weight_buff_start(weight_buff_start),
        .weight_s_axis_tdata(weight_fifo_dout),
        .weight_s_axis_tvalid(weight_fifo_empty),
        .weight_s_axis_tready(weight_fifo_rd_en),

        // 索引输入
        .index_buff_en(index_buff_en),
        .index_buff_start(index_buff_start),
        .index_s_axis_tdata(index_fifo_dout),
        .index_s_axis_tvalid(index_fifo_empty),
        .index_s_axis_tready(index_fifo_rd_en),

        
        .net_sele(2'b01),

        .o_cpsum(o_cpsum),
        .o_finish(o_finish)
    );

    //=============================
    // 输出FIFO封装
    //=============================
    axis_fifo_64  u_cpsum_fifo (
        .s_axis_aclk(clk), 
        .s_axis_aresetn(rst),
        .s_axis_tdata(o_cpsum[63:0]),  
        .s_axis_tvalid(o_finish),
        .s_axis_tready(1'b1),

        .m_axis_tdata(m_axis_cpsum_tdata),
        .m_axis_tvalid(m_axis_cpsum_tvalid),
        .m_axis_tready(m_axis_cpsum_tready)
    );

endmodule
