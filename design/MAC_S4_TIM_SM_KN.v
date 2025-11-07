`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/21 10:27:15
// Design Name: 
// Module Name: MAC_S4_TIM_SM_KN
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


module MAC_S4_TIM_SM_KN #(
        parameter Activation_Data_Width = 4,  //unsigned
        parameter Weight_Data_Width = 4, //SM 1bit + 3bits
        parameter Parallelism = 8
    )(
        input clk,
        input [Activation_Data_Width*Parallelism-1:0] i_Activation,
        input [Weight_Data_Width*Parallelism-1:0] i_Weight,
        output reg [9:0] o_result
    );
        wire [Parallelism-1:0] sign;
        wire [Activation_Data_Width + Weight_Data_Width -2 : 0] Psum0[7:0];
        reg  [Activation_Data_Width + Weight_Data_Width -1 : 0] Psum1[3:0];
        reg  [Activation_Data_Width + Weight_Data_Width -0 : 0] Psum2[1:0];


        genvar i;
        generate
            for(i = 0; i < Parallelism; i = i+1)
                begin:Mult
                    clm_sm_kn UU (
                        .A(i_Activation[(i+1)*Activation_Data_Width-1:i*Activation_Data_Width]),  // input wire [3 : 0] A
                        .B(i_Weight[(i+1)*Weight_Data_Width-1:i*Weight_Data_Width]),  // input wire [3 : 0] B
                        .sign(sign[i]),
                        .result(Psum0[i])  // output wire [6 : 0] P
                        );
                end
        endgenerate


        wire [3:0] SM_bit_acc;
        reg [7:0] SM_bit_acc_shift;
        adder_8x1b uuu1(
        .In_data(sign),
        .Out_data(SM_bit_acc)
        );

        always@(posedge clk )
            begin
                SM_bit_acc_shift <= {SM_bit_acc_shift[3:0],SM_bit_acc};
            end

        always @(posedge clk ) 
            begin
                Psum1[0] <= {Psum0[0][6],Psum0[0]} + {Psum0[1][6],Psum0[1]};
                Psum1[1] <= {Psum0[2][6],Psum0[2]} + {Psum0[3][6],Psum0[3]};
                Psum1[2] <= {Psum0[4][6],Psum0[4]} + {Psum0[5][6],Psum0[5]};
                Psum1[3] <= {Psum0[6][6],Psum0[6]} + {Psum0[7][6],Psum0[7]};
            end

        always @(posedge clk ) 
            begin
                Psum2[0] <= {Psum1[0][7],Psum1[0]} + {Psum1[1][7],Psum1[1]};
                Psum2[1] <= {Psum1[2][7],Psum1[2]} + {Psum1[3][7],Psum1[3]};
            end

        always @(posedge clk ) 
            begin
                o_result <= ({Psum2[0][8],Psum2[0]} + {Psum2[1][8],Psum2[1]}) + {6'd0,SM_bit_acc_shift[7:4]};
            end

endmodule
