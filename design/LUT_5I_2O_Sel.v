`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/06 10:48:15
// Design Name: 
// Module Name: LUT_5I_2O_Sel
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


module LUT_5I_2O_Sel(
     input wire [4:0] In_Data,
     output wire [1:0] Out_Data
    );
    
    assign Out_Data = In_Data[4]?In_Data[3:2]:In_Data[1:0];
    
endmodule
