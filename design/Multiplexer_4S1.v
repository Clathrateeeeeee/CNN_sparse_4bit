`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/05 21:46:47
// Design Name: 
// Module Name: Multiplexer_8S1
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


module Multiplexer_4S1(
    input  wire [3:0] act,   // 4-bit activation input
    input  wire [1:0] idx,   // 2-bit index
    output wire       sel_bit // selected bit
);

    reg sel_pre4 ; // ��ѡ����ǰ8bit�е�1λ

    always @(*) 
        begin
            // �� idx[2:0] ѡ�� act[7:0] �е�ĳһλ
            case (idx)
                2'd0: sel_pre4 = act[0];
                2'd1: sel_pre4 = act[1];
                2'd2: sel_pre4 = act[2];
                2'd3: sel_pre4 = act[3];
                default: sel_pre4 = 1'b0;
            endcase
        end
        
    assign sel_bit = sel_pre4;

endmodule
