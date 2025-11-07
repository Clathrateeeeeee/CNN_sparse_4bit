`timescale 1ns/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/17 17:14:38
// Design Name: 
// Module Name: Inbuff
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


module tb_ping_pong_ctrl;

    // =================== 参数定义 ===================
    localparam CLK_PERIOD = 10;   // 100 MHz

    // =================== 信号定义 ===================
    reg  clki;
    reg  rst;
    reg  Ctrl_start;
    reg  done_tile;
    reg  last_tile;
    reg  write_finish;

    wire ping_pong_write;
    wire ping_pong_read;
    wire inbuffer_enout;

    // =================== DUT 例化 ===================
    ping_pong_ctrl dut(
        .clki(clki),
        .rst(rst),
        .Ctrl_start(Ctrl_start),
        .done_tile(done_tile),
        .last_tile(last_tile),
        .write_finish(write_finish),
        .ping_pong_write(ping_pong_write),
        .ping_pong_read(ping_pong_read),
        .inbuffer_enout(inbuffer_enout)
    );

    // =================== 时钟产生 ===================
    initial begin
        clki = 0;
        forever #(CLK_PERIOD/2) clki = ~clki;
    end

    // =================== 复位 ===================
    initial begin
        rst = 1;
        Ctrl_start = 0;
        done_tile = 0;
        last_tile = 0;
        write_finish = 0;
        #(CLK_PERIOD*5);
        rst = 0;
    end

    // =================== 任务：产生单周期脉冲 ===================
    task pulse_write_finish;
    begin
        @(posedge clki);
        write_finish <= 1'b1;
        @(posedge clki);
        write_finish <= 1'b0;
    end
    endtask

    task pulse_done_tile;
    begin
        @(posedge clki);
        done_tile <= 1'b1;
        @(posedge clki);
        done_tile <= 1'b0;
    end
    endtask

    // =================== 激励 ===================
    initial begin
        // 启动 FSM
        #(CLK_PERIOD*10);
        Ctrl_start = 1;
        @(posedge clki);
        Ctrl_start = 0;

        // ---------------- Tile1 ----------------
        // 仅写完成脉冲
        #(CLK_PERIOD*10);
        pulse_write_finish();

        // ---------------- Tile2 ----------------
        // 模拟 write 快 read 慢
        #(CLK_PERIOD*20);
        pulse_done_tile();
        #(CLK_PERIOD*10);
        pulse_write_finish();

        // ---------------- Tile3 ----------------
        // 模拟 read 快 write 慢
        #(CLK_PERIOD*20);
        pulse_write_finish();
        #(CLK_PERIOD*15);
        pulse_done_tile();
        
        #(CLK_PERIOD*20);
        pulse_write_finish();
        #(CLK_PERIOD*15);
        pulse_done_tile();
        
                // ---------------- Tile2 ----------------
        // 模拟 write 快 read 慢
        #(CLK_PERIOD*20);
        pulse_done_tile();
        #(CLK_PERIOD*10);
        pulse_write_finish();

        // ---------------- Tile3 ----------------
        // 模拟 read 快 write 慢
        #(CLK_PERIOD*20);
        pulse_write_finish();
        #(CLK_PERIOD*15);
        pulse_done_tile();
        
        #(CLK_PERIOD*20);
        pulse_write_finish();
        #(CLK_PERIOD*15);
        pulse_done_tile();
        
                // ---------------- Tile2 ----------------
        // 模拟 write 快 read 慢
        #(CLK_PERIOD*20);
        pulse_done_tile();
        #(CLK_PERIOD*10);
        pulse_write_finish();

        // ---------------- Tile3 ----------------
        // 模拟 read 快 write 慢
        #(CLK_PERIOD*20);
        pulse_write_finish();
        #(CLK_PERIOD*15);
        pulse_done_tile();
        
        #(CLK_PERIOD*20);
        pulse_write_finish();
        #(CLK_PERIOD*15);
        pulse_done_tile();

        // ---------------- 最后一块 tile ----------------
        #(CLK_PERIOD*20);
        last_tile = 1'b1;
        pulse_write_finish();
        #(CLK_PERIOD*20);
        pulse_done_tile();

        #(CLK_PERIOD*50);
        $stop;
    end


endmodule