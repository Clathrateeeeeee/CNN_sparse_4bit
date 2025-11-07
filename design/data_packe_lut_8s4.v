`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/07 11:36:50
// Design Name: 
// Module Name: data_packe_lut_9s1
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


module data_packe_lut_8s4(
	input         clk,
	input [11:0] index,		//four indexs of nozero position  4*4
	input  [31:0] data_in,		//16 activations
	output reg [15:0] data_out	//8 valid activations
    );


	wire [19:0] data_in0[3:0] ;
	generate
		genvar i; 
		for (i = 0; i < 5; i = i + 1) 
			begin  
				assign data_in0[0][i*4+:4] = data_in[i*4+:4];      //the data which first to 5s1	
                assign data_in0[1][i*4+:4] = data_in[(i+1)*4+:4];  //the data which second to 5s1
                assign data_in0[2][i*4+:4] = data_in[(i+2)*4+:4];  //the data which third  to 5s1 
                assign data_in0[3][i*4+:4] = data_in[(i+3)*4+:4];  

			end
	endgenerate
	
	// eight groups that four times (4bit) 9S1
    wire [15:0]data_out0;
always @(posedge clk) 
		begin
            data_out<=  data_out0;
		end

     Multiplexer_4x4b_4S1_ext sel (
        .act({data_in0[3],data_in0[2],data_in0[1],data_in0[0]}),  // eight  groups 
        .idx(index),   // 4-bit index
        .sel_4x4b(data_out0) // selected bit
    );

endmodule
