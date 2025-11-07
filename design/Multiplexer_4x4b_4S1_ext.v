`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/06 10:16:23
// Design Name: 
// Module Name: Multiplexer_8x4b_8S1_ext
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


module Multiplexer_4x4b_4S1_ext(
    input  wire [4*5*4-1:0] act,   ////5个4b激活，4组
    input  wire [11:0]  idx,   // 3-bit index
    output wire [15:0]  sel_4x4b // selected bit
);


    wire [15:0]  sel_4x4b_temp;

    generate 
        genvar i;
        for(i = 0; i < 4; i = i+1)
            begin:selecter_4b
                Multiplexer_4b_4S1 M_4bb_init(
                .act(act[20*(i+1)-5:20*i]),   // 9-bit activation input
                .idx(idx[3*(i+1)-2:3*i]),   // 4-bit index
                .sel_4b(sel_4x4b_temp[4*(i+1)-1:4*i]) // selected bit
                );
            end
    endgenerate


    generate 
        genvar j;
        for(j = 0; j < 4; j = j+1)
            begin:LUT_UU
                LUT_5I_2O_Sel UU0(.In_Data({idx[(j+1)*3-1],act[20*(j+1)-3:20*(j+1)-4],sel_4x4b_temp[j*4+1:j*4]}),.Out_Data(sel_4x4b[j*4+1:j*4]));
                LUT_5I_2O_Sel UU1(.In_Data({idx[(j+1)*3-1],act[20*(j+1)-1:20*(j+1)-2],sel_4x4b_temp[j*4+3:j*4+2]}),.Out_Data(sel_4x4b[j*4+3:j*4+2]));
            end
    endgenerate
    
    // LUT_5I_2O_Sel UU0(.In_Data({idx[3 ],act[36*1-3:36*1-4],sel_8x4b_temp[1 :0]}),.Out_Data(sel_8x4b[1:0]));
    // LUT_5I_2O_Sel UU1(.In_Data({idx[3 ],act[36*1-1:36*1-2],sel_8x4b_temp[3 :2]}),.Out_Data(sel_8x4b[3:2]));

    // assign sel_8x4b[3 :0]  = idx[3 ] ? act[36*1-1:36*1-4] : sel_8x4b_temp[3 :0] ;
    // assign sel_8x4b[7 :4]  = idx[7 ] ? act[36*2-1:36*2-4] : sel_8x4b_temp[7 :4] ;
    // assign sel_8x4b[11:8]  = idx[11] ? act[36*3-1:36*3-4] : sel_8x4b_temp[11:8] ;
    // assign sel_8x4b[15:12] = idx[15] ? act[36*4-1:36*4-4] : sel_8x4b_temp[15:12];
    // assign sel_8x4b[19:16] = idx[19] ? act[36*5-1:36*5-4] : sel_8x4b_temp[19:16];
    // assign sel_8x4b[23:20] = idx[23] ? act[36*6-1:36*6-4] : sel_8x4b_temp[23:20];
    // assign sel_8x4b[27:24] = idx[27] ? act[36*7-1:36*7-4] : sel_8x4b_temp[27:24];
    // assign sel_8x4b[31:28] = idx[31] ? act[36*8-1:36*8-4] : sel_8x4b_temp[31:28];



endmodule

