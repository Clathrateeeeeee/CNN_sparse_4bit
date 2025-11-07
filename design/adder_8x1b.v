`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/21 10:20:48
// Design Name: 
// Module Name: adder_8x1b
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

// This code function is to implement the accumulation of eight 1b based on the characteristics of LUT

module adder_8x1b(
        input [7:0] In_data,
        output [3:0] Out_data    
    );

        // first-stage
    wire [1:0] psum0_0,psum0_1,psum0_2;
    
    assign psum0_0 =  In_data[2] + In_data[1] + In_data[0];     
    assign psum0_1 =  In_data[5] + In_data[4] + In_data[3]; 
    assign psum0_2 =  In_data[7] + In_data[6];    

        // second-stage
    wire [1:0] psum1_0,psum1_1; 

    assign psum1_0 = psum0_0[0] + psum0_1[0] + psum0_2[0];
    assign psum1_1 = psum0_0[1] + psum0_1[1] + psum0_2[1];
    assign Out_data[0] = psum1_0[0];

        // third-stage
    wire [1:0] psum2_0;

    assign psum2_0 = psum1_0[1] + psum1_1[0];
    assign Out_data[1] = psum2_0[0];

        // four-stage
    assign Out_data[3:2] = psum2_0[1] + psum1_1[1];
        
endmodule

