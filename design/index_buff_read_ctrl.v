`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/25 16:43:54
// Design Name: 
// Module Name: Idex_buff
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


module index_buff_read_ctrl #(
    parameter Ifm_Width = 9,
    parameter weight_sign_Ram_Row = 16,
    parameter weight_sign_Axi_Width = 64,
    parameter weight_sign_Write_Data_Width = 64,
    parameter weight_sign_Read_Data_Width = 64,//16bit-->64bit
    parameter weight_sign_Write_Addr_Width = 11,
    parameter weight_sign_Read_Addr_Width = 11
)(
    input clk,
    input value_en,
    input weight_sign_Sys_start,
    input rst,

    //input [Ifm_Width-1:0]OH_14,//(((ifm_H+pad_top+pad_bot-kernel_size_a)/stride+1)%14==0)?((ifm_H+pad_top+pad_bot-kernel_size_a)/stride+1)/14:((ifm_H+pad_top+pad_bot-kernel_size_a)/stride+1)/14+1'b1;
    input [Ifm_Width-1:0]Addrtimes_end,//kernel times (W trend) * (H/14)  kernel_times = ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1
    input  [weight_sign_Read_Addr_Width+4:0] k_k_channels,//kernel_size*kernel_size*channels
    
    output reg[63:0] valid,
    
    input [weight_sign_Axi_Width-1: 0] weight_sign_s_axis_tdata,
    input weight_sign_s_axis_tvalid,
    output weight_sign_s_axis_tready,
    input   en_to_fifo,//inbuff read en

    output [weight_sign_Read_Data_Width*weight_sign_Ram_Row-1:0]dout //14*64 for 14 mac use
);  

    reg [2:0]   weight_sign_state;

    localparam  weight_sign_state_IDLE = 3'd0,
                weight_sign_state_0_0 = 3'd1,
                weight_sign_state_0_1 = 3'd2,
                weight_sign_state_1_0 = 3'd3,
                weight_sign_state_1_1  = 3'd4;


    wire         weight_sign_finished;
    reg             weight_sign_read_done;

    reg   weight_sign_ping_pong_write;
    reg   weight_sign_ping_pong_read;



    reg [Ifm_Width-1:0]Addrtimes_end_reg0;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
    reg  [weight_sign_Read_Addr_Width+4:0] k_k_channels_reg0;//kernel_size*kernel_size*channels;



    reg [Ifm_Width-1:0]Addrtimes_end_reg1;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
    reg  [weight_sign_Read_Addr_Width+4:0] k_k_channels_reg1;//kernel_size*kernel_size*channels



    reg [Ifm_Width-1:0]Addrtimes_end_reg;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
    reg  [weight_sign_Read_Addr_Width+4:0] k_k_channels_reg;//kernel_size*kernel_size*channels

 

    reg     weight_sign_start;
    reg     weight_sign_enout;



    wire [Ifm_Width-1:0]                    Addrtimes_end_a=weight_sign_ping_pong_read?Addrtimes_end_reg1:Addrtimes_end_reg0;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
    wire  [weight_sign_Read_Addr_Width+4:0] k_k_channels_a =weight_sign_ping_pong_read?k_k_channels_reg1:k_k_channels_reg0;//kernel_size*kernel_size*channels


    always@(posedge clk)
        begin

            Addrtimes_end_reg<=value_en?Addrtimes_end:Addrtimes_end_reg;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
            k_k_channels_reg <=value_en?k_k_channels:k_k_channels_reg;
        end

        
    always@(posedge clk)
        begin
            case(weight_sign_state)
                weight_sign_state_0_1,weight_sign_state_0_0:
                    begin

                        Addrtimes_end_reg0<=value_en?Addrtimes_end:Addrtimes_end_reg0;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
                        k_k_channels_reg0 <=value_en?k_k_channels:k_k_channels_reg0;
                    end
                default:
                    begin

                        Addrtimes_end_reg0<=Addrtimes_end_reg0;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
                        k_k_channels_reg0 <=k_k_channels_reg0;
                    end
            endcase
        end

    always@(posedge clk)
        begin
            case(weight_sign_state)
                weight_sign_state_1_0:
                    begin

                        Addrtimes_end_reg1<=value_en?Addrtimes_end:Addrtimes_end_reg1;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
                        k_k_channels_reg1 <=value_en?k_k_channels:k_k_channels_reg1;
                    end
                default:
                    begin
                        Addrtimes_end_reg1<=Addrtimes_end_reg1;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
                        k_k_channels_reg1 <=k_k_channels_reg1;
                    end
            endcase
        end


    always@(posedge clk)
        begin 
            if(rst)
                weight_sign_state<=weight_sign_state_IDLE;
            else if(weight_sign_Sys_start)
                weight_sign_state<=weight_sign_state_0_0;
            else
                begin
                    case(weight_sign_state)
                        weight_sign_state_0_0:
                            begin
                                if(weight_sign_finished)
                                    weight_sign_state<=weight_sign_ping_pong_write?weight_sign_state_0_1:weight_sign_state_1_0;
                                else
                                    weight_sign_state<=weight_sign_state;
                            end
                        weight_sign_state_0_1:
                            begin
                                case({weight_sign_finished,weight_sign_read_done})
                                    2'b10:weight_sign_state<=weight_sign_state_1_1;
                                    2'b11:weight_sign_state<=weight_sign_state_1_0;
                                    2'b01:weight_sign_state<=weight_sign_state_0_0;
                                    2'b00:weight_sign_state<=weight_sign_state;
                                    default:weight_sign_state<=weight_sign_state;
                                endcase
                            end
                        weight_sign_state_1_0:
                            begin
                                case({weight_sign_finished,weight_sign_read_done})
                                    2'b10:weight_sign_state<=weight_sign_state_1_1;
                                    2'b11:weight_sign_state<=weight_sign_state_0_1;
                                    2'b01:weight_sign_state<=weight_sign_state_0_0;
                                    2'b00:weight_sign_state<=weight_sign_state;
                                    default:weight_sign_state<=weight_sign_state;
                                endcase
                            end
                        weight_sign_state_1_1:
                            begin
                                case({weight_sign_ping_pong_read,weight_sign_read_done})
                                    2'b11:weight_sign_state<=weight_sign_state_1_0;
                                    2'b01:weight_sign_state<=weight_sign_state_0_1;
                                    default:weight_sign_state<=weight_sign_state;
                                endcase
                            end
                    endcase
                end  
            end
    
    wire[weight_sign_Read_Addr_Width-1:0]Addr_end =k_k_channels>>4;
    reg [weight_sign_Read_Addr_Width-1:0]Out_addr;
    reg [Ifm_Width-1:0]Addrtimes_cnt;
    
    reg Addrtimes_end_cmp;
    reg Addr_end_cmp;
    always@(*)
        begin
            case(weight_sign_state)
                weight_sign_state_1_0,weight_sign_state_1_1,weight_sign_state_0_1:                     
                        weight_sign_read_done=(Addrtimes_end_cmp&Addr_end_cmp)?1'b1:1'b0;
                default:weight_sign_read_done=1'b0;
            endcase
        end
    
    always@(posedge clk)
        begin 
            case(weight_sign_state)
                weight_sign_state_1_0,weight_sign_state_0_0,weight_sign_state_0_1:
                   weight_sign_start<=weight_sign_s_axis_tready?1'b0:1'b1;
                default:weight_sign_start<=1'b0;
            endcase
        end

    always@(posedge clk)
        begin 
            case(weight_sign_state)
                weight_sign_state_0_0:
                    weight_sign_ping_pong_write<=weight_sign_ping_pong_write;
                weight_sign_state_0_1:
                    weight_sign_ping_pong_write<=1'b0;
                weight_sign_state_1_0:
                    weight_sign_ping_pong_write<=1'b1;
                default:
                    weight_sign_ping_pong_write<=1'b0;
            endcase
        end

    always@(posedge clk)
        begin 
            case(weight_sign_state)
                weight_sign_state_0_1:
                    weight_sign_ping_pong_read<=1'b1;
                weight_sign_state_1_0:
                    weight_sign_ping_pong_read<=1'b0;
                weight_sign_state_1_1:
                    weight_sign_ping_pong_read<=weight_sign_ping_pong_read;
                default:
                    weight_sign_ping_pong_read<=1'b0;
            endcase
        end

    always@(posedge clk)
        begin 
            case(weight_sign_state)
                weight_sign_state_1_0,weight_sign_state_1_1,weight_sign_state_0_1:
                    if(weight_sign_enout)
                        begin
                            Out_addr<=(Out_addr==Addr_end-1'b1)?{weight_sign_Read_Addr_Width{1'b0}}:Out_addr+1'b1;
                            Addrtimes_cnt<=(Out_addr==Addr_end-1'b1)?((Addrtimes_cnt==Addrtimes_end-1'b1)?{Ifm_Width{1'b0}}:Addrtimes_cnt+1'b1):Addrtimes_cnt;
                            valid<={64{1'b1}};
                        end
                    else
                        begin
                            Out_addr<=Out_addr;
                            Addrtimes_cnt<=Addrtimes_cnt;
                            valid<=64'D0;
                        end

                default:
                    begin
                        Out_addr<={weight_sign_Read_Addr_Width{1'b0}};
                        Addrtimes_cnt<={Ifm_Width{1'b0}};
                        valid<=1'd0;
                    end
            endcase
        end


    always@(posedge clk)
        begin 
            Addrtimes_end_cmp<=(Addrtimes_cnt==Addrtimes_end-1'b1)?1'b1:1'b0;
            Addr_end_cmp<=(Out_addr==Addr_end-1'b1)?1'b1:1'b0;
        end

 
    reg weight_sign_read_ready;
    always@(*)
        begin 
            case(weight_sign_state)
                weight_sign_state_0_0:
                    weight_sign_read_ready=1'b0;
                weight_sign_state_0_1:
                    weight_sign_read_ready=(weight_sign_ping_pong_read==1'b1)? 1'b1: 1'b0;
                weight_sign_state_1_0:
                    weight_sign_read_ready=(weight_sign_ping_pong_read==1'b0)? 1'b1: 1'b0;
                weight_sign_state_1_1:
                    weight_sign_read_ready=1'b1;
                default:weight_sign_read_ready=1'b0;
            endcase
        end

    always@(*)
        begin
            case(weight_sign_state)
                    weight_sign_state_1_0,weight_sign_state_1_1,weight_sign_state_0_1:
                    weight_sign_enout=en_to_fifo&(!weight_sign_read_done)&weight_sign_read_ready;
                default:weight_sign_enout=1'b0; 
            endcase
        end

index_buff #(
    .Ram_Row(weight_sign_Ram_Row),
    .Axi_Width(weight_sign_Axi_Width),
    .Ifm_Width(Ifm_Width),
    .Write_Data_Width(weight_sign_Write_Data_Width),
    .Read_Data_Width(weight_sign_Read_Data_Width),//16bit-->64bit
    .Write_Addr_Width(weight_sign_Write_Addr_Width),
    .Read_Addr_Width (weight_sign_Read_Addr_Width)
) sign_buff(
    .clki(clk),
    .rst(rst),
    .start(weight_sign_start),
    .finished(weight_sign_finished),
    
    //CNN parameters input 

    .Addr_end(k_k_channels_reg),



    /*ping_pong*/
    .ping_pong_write(weight_sign_ping_pong_write),//From the written data, 0 is low and 1  is high;
    .ping_pong_read(weight_sign_ping_pong_read), //From the raeding data, 0 is low and 1  is high;
    
    //inbuf output
    .clkout(clk),
    .enout(weight_sign_enout),
    .addrout(Out_addr),
    .dout(dout),
    
    //AXI-Stream Slave
    .s_axis_tdata(weight_sign_s_axis_tdata),
    .s_axis_tvalid(weight_sign_s_axis_tvalid),
    .s_axis_tready(weight_sign_s_axis_tready)
);  

endmodule
