`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/02 15:26:19
// Design Name: 
// Module Name: c_psum
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


module c_psum#(
    parameter mac_number = 14,
    parameter pe_number = 64,
    parameter width = 10,
    parameter c_number_max = 64
)(
    //computing_core
    input clk,
    input rst,
    input in_valid,
    input [mac_number*pe_number*width-1:0] i_result,//mac first pe later,in next clock,the mac will send the next col
    //contorl
    input [2:0] kernel,
    input [9:0] c_tile_in,
    //output
    output reg [22*mac_number*pe_number-1:0] o_cpsum,//K_data width = 22
    output reg o_finish
    );
    
    reg [width + $clog2(8) - 1:0] H_data [pe_number*mac_number-1:0];//width = 13
    reg [13 + $clog2(c_number_max)-1:0] C_data [pe_number*mac_number-1:0];
    reg [19 + $clog2(8)-1:0] K_data [pe_number*mac_number-1:0];
    reg [2:0] add_times,k_times;
    reg [$clog2(c_number_max):0]c_count;
    reg c_finish,c_reset;
    wire valid_delay;
    reg valid_delay_r;
    reg [6:0] delay_chain;  //ccdata has 7 clock delay

    always @(posedge clk) begin
        if (rst)
            delay_chain <= 7'd0;
        else
            delay_chain <= {delay_chain[5:0], in_valid};
    end

    assign valid_delay = delay_chain[6];

    always@(posedge clk)begin
        if(rst)
            valid_delay_r <= 0;
        else
            valid_delay_r <= valid_delay;
    end
    
    always@(posedge clk)begin
        if(rst)
            add_times <= 0;
        else if(add_times == kernel)
            add_times <= 1;
        else if(valid_delay)
            add_times <= add_times + 1;
        else
            add_times <= add_times;
    end
    always@(posedge clk)begin
        if(rst)begin
            c_count <= 0;
            c_finish <= 0;
        end
        else if(c_count == (c_tile_in >>4)-1 && add_times == kernel)begin //the last one
            c_count <= 0;
            c_finish <= 1;
        end   
        else if(valid_delay && add_times == kernel)
            c_count <= c_count + 1;
        else begin
            c_count <= c_count;
            c_finish <= 0;
        end
    end
    always@(*)begin
        if(rst)
            c_reset = 0;
        else if(valid_delay && c_count == 0 && add_times == kernel)
            c_reset = 1;
        else
            c_reset = 0;
    end
    always@(posedge clk)begin
        if(rst)
            k_times <= 0;
        else if(k_times == kernel && c_finish)
            k_times <= 1;
        else if(valid_delay && c_finish)
            k_times <= k_times + 1;
        else 
            k_times <= k_times;
    end
    
    integer i;
        always@(posedge clk)begin
          for(i=0;i<896;i=i+1)begin
            if(rst)begin
                    H_data[i] <= 0;
                    C_data[i] <= 0;
            end
            else begin
                    if (add_times == kernel) begin
                        H_data[i] <= i_result[(i*width)+:width];
                        C_data[i] <= (c_reset == 1'b0)?C_data[i] + H_data[i]:H_data[i];
                    end
                    else begin
                        H_data[i] <= H_data[i] + i_result[(i*width)+:width];
                        C_data[i] <= C_data[i];
                    end
                end
          end
        end
        
    always @(posedge clk) begin
        for (i = 0; i < 896; i = i + 1) begin
                if (rst) begin
                K_data[i] <= 0;
            end 
            else if ((k_times == kernel) && (c_finish == 1'b1)) begin
                K_data[i] <= C_data[i];
            end 
            else if ((k_times != kernel) && (c_finish == 1'b1)) begin
                K_data[i] <= K_data[i] + C_data[i];
            end 
            else begin
                K_data[i] <= K_data[i];
            end
        end
    end
    
    always@(*)begin
        for(i=0;i<896;i=i+1)begin
            o_cpsum[(i*22)+:22] = (k_times==kernel)?K_data[i]:o_cpsum[(i*22)+:22];
        end
    end
    
    always@(posedge clk)begin
        if(rst)
            o_finish <= 0;
        else if(k_times==kernel - 1 && c_finish)
            o_finish <= 1;
        else 
            o_finish <= 0;
    end
    
endmodule