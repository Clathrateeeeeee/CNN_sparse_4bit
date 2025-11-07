`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/21 21:25:59
// Design Name: 
// Module Name: computing_core
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


module computing_core(
    input           clk,
	input	[2047:0] i_Weight,//8 valid weights form diffrent channels , 64 different ochannelsï¼?4bits
	input	[448*64-1:0]i_Activation,//provide 14 mac ,each mac has 8 act which from 8 channels,14 mac act from H direction(14) 4bits
	output	reg	[8959:0] o_result//10*14*64,16PE(each pe has 14 mac) 's 
    );
	
	
	reg		[31:0]	i_Weight_reg[63:0];
	reg		[448*64-1:0] i_Activation_reg;
	wire    [139:0]	result[63:0];
	
	integer i;
	
	always@(posedge clk)
		begin
		
			for(i=0;i<64;i=i+1)
				begin
					i_Weight_reg[i]<=i_Weight[i*32+:32];
					o_result[i*140+:140]<=result[i];
				end
			
				i_Activation_reg<=i_Activation;
		
		end

    genvar j;
		generate
			for (j = 0; j < 64; j = j + 1) 
				begin 
					PE u_pe(
						.clk(clk),
						.i_Activation(i_Activation_reg[(j+1)*448-1:j*448]),
						.i_Weight(i_Weight_reg[j]),
						.o_result(result[j])
					);
				end
		endgenerate
endmodule
