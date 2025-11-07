`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/07 12:53:08
// Design Name: 
// Module Name: selector_14groups
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


module selector_14groups(
	input	clk,
	input	in_valid,//invaid signal
	input	[15:0]   weight,       // Index is shared across all streams
	input	[895:0]  in_act,     // 14 * 64-bit streams
	output reg   out_valid,   // 14 in 1 valid signals
	output reg [447:0]  valid_act     // 14 * 32-bit outputs
    );

    reg out_valid_reg;
    reg [11:0] index0; // postions of valid_act 3*4
	reg [11:0] index1; 
    integer  cnt0;  // use to save 8 valid positions 4=2bit
	integer  cnt1;
    wire [223:0] inst_data_out0;
	wire [223:0] inst_data_out1;
    integer  i;
    // select the location where the valid data currently entered is extracted
    always @(*) begin
        cnt0 = 0;
        for ( i = 0; i < 8; i=i+1) 
			begin
				if (weight[i]) 
					begin
						index0[cnt0*3 +: 3] =i[2:0];
						cnt0=cnt0+1;
					end
				else 
					begin
						index0=index0;
						cnt0=cnt0;
					end
			end
    end
	always @(*) begin
			cnt1 = 0;
			for ( i = 0; i < 8; i=i+1) 
				begin
					if (weight[i+8]) 
						begin
							index1[cnt1*3 +: 3] =i[2:0];
							cnt1=cnt1+1;
						end
					else 
						begin
							index1=index1;
							cnt1=cnt1;
						end
				end
	end
	
    wire [11:0] index0_t;
    assign  index0_t[9+:3]=index0[9+:3]-3;
	//3-7
    assign  index0_t[6+:3]=index0[6+:3]-2;
	//2-6
    assign  index0_t[3+:3]=index0[3+:3]-1;
	//1-5
    assign  index0_t[0+:3]=index0[0+:3];
	//0-4
    wire [11:0] index1_t;
    assign  index1_t[9+:3]=index1[9+:3]-3;
	//3-7
    assign  index1_t[6+:3]=index1[6+:3]-2;
	//2-6
    assign  index1_t[3+:3]=index1[3+:3]-1;
	//1-5
    assign  index1_t[0+:3]=index1[0+:3];
	//0-4
	//14 groups
    genvar j;
		generate
			for (j = 0; j < 14; j = j + 1) 
				begin : gen_packer_instances0
					data_packe_lut_8s4 core_inst0 (
						.clk(clk),
						.index(index0_t),
						.data_in(in_act[j*64 +: 32]),
						.data_out(inst_data_out0[j*16 +: 16])
					);
				end
		endgenerate

    genvar k;
		generate
			for (k = 0; k < 14; k = k + 1) 
				begin : gen_packer_instances1
					data_packe_lut_8s4 core_inst1 (
						.clk(clk),
						.index(index1_t),
						.data_in(in_act[(k*64+32) +: 32]),
						.data_out(inst_data_out1[k*16 +: 16])
					);
				end
		endgenerate
		wire [447:0]data_out;
    genvar m;
		generate
		  for (m = 0; m < 14; m = m + 1) 
			begin
                assign data_out[m*32+:32]={inst_data_out1[m*16+:16],inst_data_out0[m*16+:16]};
			end
		endgenerate
    // output
    always @(posedge clk ) 
		begin
			if (!out_valid_reg) 
				begin
					valid_act <= 448'b0;
				end 
			else 
				begin
					valid_act <= data_out;
				end
		end
		
    always @(posedge clk ) 
		begin
					out_valid_reg <=in_valid;
					out_valid<=out_valid_reg;
		end

endmodule
