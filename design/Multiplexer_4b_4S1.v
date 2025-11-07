`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/06 09:43:30
// Design Name: 
// Module Name: Multiplexer_4b_8S1
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



module Multiplexer_4b_4S1(
    input  wire [15:0] act,   // 4-bit activation input
    input  wire [1:0]  idx,   // 4-bit index
    output wire [3:0]  sel_4b // selected bit
);

    generate
        genvar i;
        for(i = 0; i < 4; i = i+1)
            begin:selecter
                Multiplexer_4S1 M_init(
                .act({act[i+12],act[i+8],act[i+4],act[i]}),   // 9-bit activation input
                .idx(idx),   // 4-bit index
                .sel_bit(sel_4b[i]) // selected bit
                );
            end
    endgenerate



endmodule
