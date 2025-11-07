`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/19 09:56:02
// Design Name: 
// Module Name: mask
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


module mask#(
    parameter Ram_Row = 33,
    parameter Data_Width = 64,//4bits * 16channels
    parameter Pe_Mac = 14,
    parameter deep = 512
)(
    input clk,
    input rst,
    input [2:0]kernel_size,
    input [1:0]stride,
    input tready,
    input reset,
    input [Data_Width*Ram_Row-1:0]din,//4bit * 16channels * 33
    output reg [895:0] select_act, //4bit * 14mac * 16nums
    output wire out_valid
    );
    
    wire [$clog2(Ram_Row)-1:0] Ram_num = (Pe_Mac-1) * stride + kernel_size;
    wire [4:0] group = Ram_num - Pe_Mac;
    reg  [Data_Width*Ram_Row-1:0]din_r;
    //valid
    reg valid,valid_r,valid_rr;
    always@(posedge clk)begin
        valid <= tready;
        din_r <= din;
    end
    always@(posedge clk)begin
        if(rst)begin
            valid_r <= 0;
            valid_rr <= 0;
        end
        else begin
            valid_r <= valid;
            valid_rr <= valid_r;
        end
    end
    //reset_rr
    reg reset_r,reset_rr;
    always@(posedge clk)begin
        if(rst)begin
            reset_r <= 0;
            reset_rr <= 0;
        end
        else begin
            reset_r <= reset;
            reset_rr <= reset_r;
        end
    end
    //select_times
    reg [4:0] select_cnt;
    reg [4:0] condition;
    always@(*)begin
        case(stride)
            2'b01:condition = (group + 1);
            2'b10:condition = 2 + (Ram_num - 2*Pe_Mac);
        endcase
    end
    always@(posedge clk)begin
        if(rst)
            select_cnt <= 1;
        else if(select_cnt == condition)
            select_cnt <= 1;
        else if(valid_r)
            select_cnt <= select_cnt + 1;
    end
    
    // offset for stride=1¡¢2
    reg [$clog2(Ram_Row*Data_Width)-1:0] offset;
    reg half_sel; //0=group1 1=group2
    always@(posedge clk)begin
        if(rst)begin
            half_sel <= 0;
        end
        else if(half_sel && reset_rr)begin
            half_sel <= 0;
        end
        else if(valid_rr && !half_sel && reset_rr)begin
            half_sel <= 1;
        end
        else
            half_sel <= half_sel;
    end
    always@(posedge clk)begin
        if(stride == 1)begin 
            case(half_sel)
                //half_sel = 0
                1'b0:offset <= Data_Width * (select_cnt - 1);
                //half_sel = 1
                1'b1:offset <= Data_Width * (Ram_num-(kernel_size-stride) + select_cnt - 1);
                default:offset <= offset;
            endcase 
        //s = 2
        end else begin
            offset <= select_cnt - 1;
        end
    end
    
    //cut
    integer i;
    reg [Ram_Row*Data_Width-1:0] cut_data;
    always@(*)begin
        for(i=0;i<Ram_Row;i=i+1)begin
          if(stride==2)begin  
            if(i<Ram_num)begin             
                cut_data[i*Data_Width+:Data_Width] = din_r[i*Data_Width+:Data_Width];
            end
            else 
                cut_data = cut_data;
          end
          else //s = 1
            if(i<(2*Pe_Mac-1) * stride + kernel_size)begin             
                cut_data[i*Data_Width+:Data_Width] = din_r[i*Data_Width+:Data_Width];
            end
            else 
                cut_data = cut_data;
        end
    end
    
    //select
    integer j;//the din hold time will be k
    always@(*)begin
        if(valid_rr)begin
            case(stride)
            2'b01:select_act = cut_data[offset +: Pe_Mac*Data_Width];
            2'b10:begin 
                for(j=0;j<Pe_Mac;j=j+1)begin
                    select_act[j*Data_Width+:Data_Width] = cut_data[(offset+j*stride)*Data_Width+:Data_Width];
                end
            end
            default:select_act = select_act;
            endcase
        end
    end
    
    assign out_valid = valid_rr;
    
endmodule
