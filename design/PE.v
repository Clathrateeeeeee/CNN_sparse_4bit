`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/21 20:20:35
// Design Name: 
// Module Name: PE
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


module PE(
    input           clk,
	input	[31:0]	i_Weight,//8 weights form diffrent channels
	input	[447:0]	i_Activation,//provide 14 mac ,each mac has 8 act which from 8 channels,14 mac act from H direction(14) 
	output	reg	[139:0] o_result//10*14,14 mac 's 
    );
	
	reg		[31:0]	i_Weight_reg;
	reg		[31:0]	i_Activation_reg[13:0];
	wire    [9:0]	result[13:0];
	
	integer i;
	
	always@(posedge clk)
		begin
		
			for(i=0;i<14;i=i+1)
				begin
					i_Activation_reg[i]<=i_Activation[i*32+:32];
					o_result[i*10+:10]<=result[i];
				end
			
				i_Weight_reg<=i_Weight;
		
		end
	
    genvar j;
		generate
			for (j = 0; j < 14; j = j + 1) 
				begin 
					MAC_S4_TIM_SM_KN u_mac(
						.clk(clk),
						.i_Activation(i_Activation_reg[j]),
						.i_Weight(i_Weight_reg),
						.o_result(result[j])
					);
				end
		endgenerate
		
		
endmodule
