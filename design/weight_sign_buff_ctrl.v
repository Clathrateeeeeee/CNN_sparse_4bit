`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/26 09:44:36
// Design Name: 
// Module Name: Idex_ctrl
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


module weight_sign_buff_ctrl #(
    parameter Ram_Row = 32,
    parameter Write_Addr_Width = 11,
    parameter Write_Data_Width = 64,
    parameter Read_Addr_Width= 11,
    parameter Ifm_Width = 9
)(
    input clk, 
    input rst,
    input start,
    input valid,
    input [Read_Addr_Width+4:0]Addr_end,
    input [Write_Data_Width-1: 0] datain,
    output reg [Write_Data_Width-1: 0] dataout,//为了让输出端口可以和输出端口连接
    output reg [Write_Addr_Width*Ram_Row-1:0]addrout_row,
    output reg [Ram_Row-1:0]weain_row,
    output reg finished,
    output reg ready
);
    localparam row0=6'd0, row1=6'd1, row2=6'd2, row3=6'd3, row4=6'd4, row5=6'd5, row6=6'd6, row7=6'd7,row8=6'd8,row9=6'd9,row10=6'd10,row11=6'd11,row12=6'd12,
    row13=6'd13,row14=6'd14,row15=6'd15,row16=6'd16,row17=6'd17,row18=6'd18,row19=6'd19,row20=6'd20,row21=6'd21,row22=6'd22,row23=6'd23,row24=6'd24,row25=6'd25,
    row26=6'd26,row27=6'd27,row28=6'd28,row29=6'd29,row30=6'd30,row31=6'd31;
               
    localparam idle= 6'd34;

    reg [5:0]state;
    reg [Write_Addr_Width-1:0] addr_end;
    reg [Write_Addr_Width-1:0]cnt_col;
    reg [Write_Addr_Width-1:0] addrout_curr;
    reg cmp_ifm_H,cmp_addr_end;
    wire weain = (state == idle)?1'b0:1'b1;//


    always@(posedge clk)
        begin
            if(rst)
                state<=idle;
            else case(state)
                    6'd34:state<=start?row0:idle;//1. Start data transmission;
                    6'd0,6'd1,6'd2,6'd3,6'd4,6'd5,6'd6,6'd7,6'd8,6'd9,6'd10,6'd11,6'd12,6'd13,6'd14,6'd15,6'd16,6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23,6'd24,6'd25,6'd26,6'd27,6'd28,6'd29,6'd30,6'd31
://The functions of this part include: 1. Start data transmission; 2. When kernel=3, the state switches from 15 to 2; 3. Switch between different input channels
                        begin
                            if(finished==1'b1) state <= idle;
                            else state<=(cmp_addr_end==1'b1)?state+1'b1:state;//2. When kernel=3, the state switches from 15 to 2; When kernel=7, the state switches from 15 to 5; 
                        end
                    default:state<=idle;  
            endcase
        end

    always@(*)//cmp_addr_end------the key signal which state jumps to next state (such as, state 3 jumps to next state 4 )
        begin
            case(state)
                default:cmp_addr_end=(cnt_col==addr_end-1'b1)&&valid;
            endcase
        end
    wire [Read_Addr_Width-1:0]Addr_end_5=Addr_end>>4;
    always@(*)//addr_end-----the start address of overlap part,or the addr_end-1 is the end address of bram1-16.there are two ways to depict addr_end 
        begin
            case(state)
                default:addr_end=Addr_end_5/*Addr_end*/;//因为先�?�道再L，所以这里是应该是addr_start+ifm_L*channels/4'd8?
            endcase
        end
    always@(*)//
        begin
            case(state)//思�?�一下这里�?�辑变换，然后改�???�???
                default:cmp_ifm_H=(state==row31);
            endcase
        end

    always@(posedge clk)//cnt_col----we use cnt_col to write address in bram
        begin
            case(state)//思�?�一下这里�?�辑变换，然后改�???�???
                6'd34:cnt_col<={Ifm_Width{1'b0}};//还没有改下面的两行？
                default:cnt_col<=(cmp_addr_end==1'b1)?{Ifm_Width{1'b0}}:(valid?cnt_col+1'b1:cnt_col);
            endcase
        end

    always@(*)//addrout_curr---
        begin
            case(state)
                // default:addrout_curr=cnt_col+pad_cnt;//根据padding（pad_cnt=1 3 5 ....）来调控真实的写入地�???
                default:addrout_curr=cnt_col;
            endcase
        end

    always@(*)//addrout_row------------This part shows the address written to the bram
        begin
            case(state)               
                6'd31:addrout_row={addrout_curr,{(Write_Addr_Width*31){1'b0}}};
                6'd30:addrout_row={{(Write_Addr_Width*1){1'b0}},addrout_curr,{(Write_Addr_Width*30){1'b0}}};
                6'd29:addrout_row={{(Write_Addr_Width*2){1'b0}},addrout_curr,{(Write_Addr_Width*29){1'b0}}};
                6'd28:addrout_row={{(Write_Addr_Width*3){1'b0}},addrout_curr,{(Write_Addr_Width*28){1'b0}}};
                6'd27:addrout_row={{(Write_Addr_Width*4){1'b0}},addrout_curr,{(Write_Addr_Width*27){1'b0}}};
                6'd26:addrout_row={{(Write_Addr_Width*5){1'b0}},addrout_curr,{(Write_Addr_Width*26){1'b0}}};
                6'd25:addrout_row={{(Write_Addr_Width*6){1'b0}},addrout_curr,{(Write_Addr_Width*25){1'b0}}};
                6'd24:addrout_row={{(Write_Addr_Width*7){1'b0}},addrout_curr,{(Write_Addr_Width*24){1'b0}}};
                6'd23:addrout_row={{(Write_Addr_Width*8){1'b0}},addrout_curr,{(Write_Addr_Width*23){1'b0}}};
                6'd22:addrout_row={{(Write_Addr_Width*9){1'b0}},addrout_curr,{(Write_Addr_Width*22){1'b0}}};
                6'd21:addrout_row={{(Write_Addr_Width*10){1'b0}},addrout_curr,{(Write_Addr_Width*21){1'b0}}};
                6'd20:addrout_row={{(Write_Addr_Width*11){1'b0}},addrout_curr,{(Write_Addr_Width*20){1'b0}}};
                6'd19:addrout_row={{(Write_Addr_Width*12){1'b0}},addrout_curr,{(Write_Addr_Width*19){1'b0}}};
                6'd18:addrout_row={{(Write_Addr_Width*13){1'b0}},addrout_curr,{(Write_Addr_Width*18){1'b0}}};
                6'd17:addrout_row={{(Write_Addr_Width*14){1'b0}},addrout_curr,{(Write_Addr_Width*17){1'b0}}};
                6'd16:addrout_row={{(Write_Addr_Width*15){1'b0}},addrout_curr,{(Write_Addr_Width*16){1'b0}}};
                6'd15:addrout_row={{(Write_Addr_Width*16){1'b0}},addrout_curr,{(Write_Addr_Width*15){1'b0}}};
                6'd14:addrout_row={{(Write_Addr_Width*17){1'b0}},addrout_curr,{(Write_Addr_Width*14){1'b0}}};
                6'd13:addrout_row={{(Write_Addr_Width*18){1'b0}},addrout_curr,{(Write_Addr_Width*13){1'b0}}};
                6'd12:addrout_row={{(Write_Addr_Width*19){1'b0}},addrout_curr,{(Write_Addr_Width*12){1'b0}}};
                6'd11:addrout_row={{(Write_Addr_Width*20){1'b0}},addrout_curr,{(Write_Addr_Width*11){1'b0}}};
                6'd10:addrout_row={{(Write_Addr_Width*21){1'b0}},addrout_curr,{(Write_Addr_Width*10){1'b0}}};
                6'd9:addrout_row={{(Write_Addr_Width*22){1'b0}},addrout_curr,{(Write_Addr_Width*9){1'b0}}};
                6'd8:addrout_row={{(Write_Addr_Width*23){1'b0}},addrout_curr,{(Write_Addr_Width*8){1'b0}}};
                6'd7:addrout_row={{(Write_Addr_Width*24){1'b0}},addrout_curr,{(Write_Addr_Width*7){1'b0}}};
                6'd6:addrout_row={{(Write_Addr_Width*25){1'b0}},addrout_curr,{(Write_Addr_Width*6){1'b0}}};
                6'd5:addrout_row={{(Write_Addr_Width*26){1'b0}},addrout_curr,{(Write_Addr_Width*5){1'b0}}};
                6'd4:addrout_row={{(Write_Addr_Width*27){1'b0}},addrout_curr,{(Write_Addr_Width*4){1'b0}}};
                6'd3:addrout_row={{(Write_Addr_Width*28){1'b0}},addrout_curr,{(Write_Addr_Width*3){1'b0}}};
                6'd2:addrout_row={{(Write_Addr_Width*29){1'b0}},addrout_curr,{(Write_Addr_Width*2){1'b0}}};
                6'd1:addrout_row={{(Write_Addr_Width*30){1'b0}},addrout_curr,{(Write_Addr_Width*1){1'b0}}};
                6'd0:addrout_row={{(Write_Addr_Width*31){1'b0}},addrout_curr};
                default:addrout_row={(Write_Addr_Width*Ram_Row){1'b0}};
            endcase
        end

    always@(*)//dataout
        begin
            case(state)
                6'd34:dataout={Write_Data_Width{1'b0}};
                default:dataout=datain;
            endcase
        end

    always@(*)//ready---Controlling the FIFO for data transmission
        begin
            case(state)
                6'd0,6'd1,6'd2,6'd3,6'd4,6'd5,6'd6,6'd7,6'd8,6'd9,6'd10,6'd11,6'd12,6'd13,6'd14,6'd15,6'd16,6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23,6'd24,6'd25,6'd26,6'd27,6'd28,6'd29,6'd30,6'd31:ready=1'b1;
                default:ready=1'b0;
            endcase
        end

    always@(*)//finished-------Monitors the completion of writing a tiling block input feature map
        begin
            case(state)
                default:finished=(cmp_ifm_H&cmp_addr_end);
            endcase
        end

    always@(*)//weain_row (the real command of state-jump)
        begin
            case(state)//
                6'd31:weain_row={weain,31'd0};
                6'd30:weain_row={1'd0,weain,30'd0};
                6'd29:weain_row={2'd0,weain,29'd0};
                6'd28:weain_row={3'd0,weain,28'd0};
                6'd27:weain_row={4'd0,weain,27'd0};
                6'd26:weain_row={5'd0,weain,26'd0};
                6'd25:weain_row={6'd0,weain,25'd0};
                6'd24:weain_row={7'd0,weain,24'd0};
                6'd23:weain_row={8'd0,weain,23'd0};
                6'd22:weain_row={9'd0,weain,22'd0};
                6'd21:weain_row={10'd0,weain,21'd0};
                6'd20:weain_row={11'd0,weain,20'd0};
                6'd19:weain_row={12'd0,weain,19'd0};
                6'd18:weain_row={13'd0,weain,18'd0};
                6'd17:weain_row={14'd0,weain,17'd0};
                6'd16:weain_row={15'd0,weain,16'd0};
                6'd15:weain_row={16'd0,weain,15'd0};
                6'd14:weain_row={17'd0,weain,14'd0};
                6'd13:weain_row={18'd0,weain,13'd0};
                6'd12:weain_row={19'd0,weain,12'd0};
                6'd11:weain_row={20'd0,weain,11'd0};
                6'd10:weain_row={21'd0,weain,10'd0};
                6'd9:weain_row={22'd0,weain,9'd0};
                6'd8:weain_row={23'd0,weain,8'd0};
                6'd7:weain_row={24'd0,weain,7'd0};
                6'd6:weain_row={25'd0,weain,6'd0};
                6'd5:weain_row={26'd0,weain,5'd0};
                6'd4:weain_row={27'd0,weain,4'd0};
                6'd3:weain_row={28'd0,weain,3'd0};
                6'd2:weain_row={29'd0,weain,2'd0};
                6'd1:weain_row={30'd0,weain,1'd0};
                6'd0:weain_row={31'd0,weain};
                default:weain_row={Ram_Row{1'b0}};
            endcase
        end

endmodule