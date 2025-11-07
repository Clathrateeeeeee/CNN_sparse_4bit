`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/31 21:28:59
// Design Name: 
// Module Name: input_buffer_ctrl_01
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

module input_buffer_ctrl_01 #(
    parameter Ram_Row = 25,
    parameter Write_Addr_Width = 9,
     parameter Write_Data_Width =64,
    parameter Ifm_Width = 10
)(
    input clk, 
    input rst,
    input start,
    input mode_sel,
    input valid,
    input [Ifm_Width*2-1:0] ifm_L_channel,
    input [Ifm_Width-1:0]ifm_H, 
    input [Ifm_Width-1:0]ifm_L,
    input [1:0]stride,//还没有使�?----应该与重叠部分的数据有关�?
    input [2: 0]kernel_size,//1~7 if kernel_size = 3
    input [3: 0] pad_edge, //{top, bottom, left, right}
    input [Ifm_Width-1: 0]channels,//channel numbers need to be tansfered. 
    input [Write_Data_Width-1: 0] datain,
    output reg [7: 0] we,
    output reg [Write_Data_Width-1: 0] dataout,//为了让输出端口可以和输出端口连接
    output reg [Write_Addr_Width*Ram_Row-1:0]addrout_row,
    output reg [Ram_Row-1:0]weain_row,
    output reg finished,
    output reg ready
);
    localparam row0 = 6'd0, row1=6'd1, row2=6'd2, row3=6'd3, row4=6'd4, row5=6'd5, row6=6'd6, row7=6'd7, row8=6'd8,row9=6'd9,
               row10=6'd10, row11=6'd11, row12=6'd12, row13=6'd13, row14=6'd14, row15=6'd15, row16=6'd16, row17=6'd17,row18=5'd18,
               row19=6'd19, row20=6'd20, row21=6'd21, row22=6'd22, row23=6'd23, row24=6'd24, row25=6'd25, row26=6'd26, row27=6'd27, 
               row28=6'd28, row29=6'd29, row30=6'd30, row31=6'd31, row32=6'd32;
                
    localparam idle= 6'd34, init = 6'd35;

    reg [5:0]state;
    reg [Ifm_Width-1:0]cnt_ifm_row;
    reg [Write_Addr_Width-1:0] addr_end;
    reg [Write_Addr_Width-1:0] addr_start;
    reg [Write_Addr_Width-1:0]cnt_col;
    reg [Write_Addr_Width-1:0] addrout_curr, addrout_next;
    reg cmp_ifm_H, cmp_channels, cmp_addr_end, cmp_state;
    wire weain = (state == idle)?1'b0:1'b1;//
    wire [1: 0] pad = kernel_size[2:1];//if K=3 ;  pad = 2'b01;if K=7 ;  pad = 2'b11;if K=1 ;  pad = 2'b00;
    wire [1: 0] pad_top = pad_edge[3]? pad: 2'h0; // 这里要大�?
    wire [1: 0] pad_bot = pad_edge[2]? pad: 2'h0;
    wire [1: 0] pad_lef = pad_edge[1]? pad: 2'h0;
    wire [1: 0] pad_rig = pad_edge[0]? pad: 2'h0;
    reg overlap_enable;//the enable signal of overlap
    reg [7:0] cnt_overlap; //the count signal of overlap

    /*pad_lef and pad_rig */
    reg [8:0] pad_lef_addr_num;//pad_lef_addr_num = pad_lef * (channel/3)
    reg [8:0] pad_rig_addr_num;//pad_rig_addr_num = pad_rig * (channel/3)
    reg [8:0] pad_cnt;
        //pad_lef_addr_num and pad_rig_addr_num
    always@(posedge clk)
        begin
            if      (kernel_size==1)
                begin
                    pad_lef_addr_num <= 9'd0;
                    pad_rig_addr_num <= 9'd0;
                end
            else if (kernel_size==3)
                begin
                    pad_lef_addr_num <= pad_edge[1]? (channels>>4): 9'd0;
                    pad_rig_addr_num <= pad_edge[0]? (channels>>4): 9'd0;
                end
            else if (kernel_size==5)
                begin
                    pad_lef_addr_num <= pad_edge[1]? (channels>>4)<<1: 9'd0;
                    pad_rig_addr_num <= pad_edge[0]? (channels>>4)<<1: 9'd0;
                end
            else if (kernel_size==7)
                begin
                    pad_lef_addr_num <= pad_edge[1]? (((channels>>4)<<1)+(channels>>4)): 9'd0;
                    pad_rig_addr_num <= pad_edge[0]? (((channels>>4)<<1)+(channels>>4)): 9'd0;
                end
            else  
                begin
                    pad_lef_addr_num <= 9'd0;
                    pad_rig_addr_num <= 9'd0;
                end  
        end

        //pad_cnt (cmp_addr_end==1'b1)&&(cmp_state==1'b1|cmp_ifm_H==1'b1)
    always@(posedge clk)//state //这部分如果要改成25bram,并且要增加上下padding的话，冲冲冲
        begin
            case(state)
                6'd34:  pad_cnt <= pad_lef_addr_num;
                default: pad_cnt <= (cmp_addr_end==1'b1)&&(cmp_state==1'b1|cmp_ifm_H==1'b1) ? pad_cnt+pad_lef_addr_num+pad_rig_addr_num:pad_cnt;
            endcase
        end

    
    always@(posedge clk)//state //这部分如果要改成25bram,并且要增加上下padding的话，冲冲冲
        begin
            if(rst)
                state<=idle;
            else case(state)
                    6'd35:state<=(cnt_col==(512-1))? pad_top:init;//Clear all data
                    6'd34:state<=start?init:idle;//1. Start data transmission;
                    6'd0,6'd1,6'd2,6'd3,6'd4,6'd5,6'd6,6'd7,6'd8,6'd9,6'd10,6'd11,6'd12,6'd13,6'd14,6'd15,6'd16,6'd17,6'd18,6'd19,6'd20,6'd21,6'd22,6'd23,6'd24,
                    6'd25,6'd26,6'd27,6'd28,6'd29,6'd30,6'd31,6'd32://The functions of this part include: 1. Start data transmission; 2. When kernel=3, the state switches from 15 to 2; 3. Switch between different input channels
                        begin
                            if(finished==1'b1) state <= idle;
                            else if(cmp_addr_end&&cmp_ifm_H)//The function here is to determine if the transmission had completed a channel, and if so skip to pad_top----- 3. Switch between different input channels
                                begin
                                    state <= pad_top;//这部分如果是按照通道先传输，那就不存在这个部分了  还没有改
                                end///这里是要改的关键，因为不同stride会有不同的跳�?---还没有改
                            else state<=(cmp_state==1'b1)&&(cmp_addr_end==1'b1)?((kernel_size>stride)?kernel_size-stride:0):((cmp_addr_end==1'b1)?state+1'b1:state);//2. When kernel=3, the state switches from 15 to 2; When kernel=7, the state switches from 15 to 5; 
                        end
                    default:state<=idle;  
            endcase
        end

    always@(*)//cmp_state------the key signal which state 16 jumps to state 3(if kernel size equals to 3 )
        begin
            case(state)//if kernel_size = 7, it is going to write 19 rows instead of  writing  20 rows instead.Because of stride equeals to 2 when kernel_size equeals to 7.
                default:cmp_state=(state==6'd28+kernel_size-stride-1'b1)?1:0;//大改
            endcase
        end

    always@(*)//cmp_addr_end------the key signal which state jumps to next state (such as, state 3 jumps to next state 4 )
        begin
            case(state)
                default:cmp_addr_end=(cnt_col==addr_end-1'b1)&&valid;
            endcase
        end

    always@(posedge clk)//addr_start-----the start address of bram1-16 
        begin
            case(state)//?
                6'd35:addr_start<={Write_Addr_Width{1'b0}};//这里可以合并�?下代码，通道优先模式不需要这种所谓的极端例子
                6'd34:addr_start<={Write_Addr_Width{1'b0}};
                // 5'd20,5'd21,5'd22,5'd23,5'd24:addr_start<=(cmp_state==1'b1|cmp_ifm_H==1'b1)&&(cmp_addr_end==1'b1)?addr_end:addr_start;//Here's an extreme case where you must add twice ifm_L
                default:addr_start<=(cmp_state==1'b1|cmp_ifm_H==1'b1)&&(cmp_addr_end==1'b1)?addr_end:addr_start;
            endcase
        end

    always@(*)//addr_end-----the start address of overlap part,or the addr_end-1 is the end address of bram1-16.there are two ways to depict addr_end 
        begin
            case(state)
                default:addr_end=addr_start+(ifm_L_channel>>4);//因为先�?�道再L，所以这里是应该是addr_start+ifm_L*channels/4'd8?
            endcase
        end

    always@(posedge clk)//cnt_col----we use cnt_col to write address in bram
        begin
            case(state)//思�?�一下这里�?�辑变换，然后改�?�?
                6'd35:cnt_col<=(cnt_col==(512-1))? 0: cnt_col+1'd1;//This state is used to count the address about clearing up data
                6'd34:cnt_col<={Ifm_Width{1'b0}};//还没有改下面的两行？
                6'd28,6'd29,6'd30,6'd31,6'd32:cnt_col<=(cmp_addr_end==1'b1)&&(cmp_state==1'b1|cmp_ifm_H==1'b1)?addr_end:((cmp_addr_end==1'b1)?addr_start:(valid?cnt_col+1'b1:cnt_col));//Here's an extreme case where you must add twice ifm_L
                default:cnt_col<=(cmp_addr_end==1'b1)&&(cmp_state==1'b1|cmp_ifm_H==1'b1)?addr_end:((cmp_addr_end==1'b1)?addr_start:(valid?cnt_col+1'b1:cnt_col));
            endcase
        end

    always@(posedge clk)//cnt_ifm_row   Counts the number of rows of input feature graphs that have been written to bram
        begin
            case(state)
                6'd34,6'd35:cnt_ifm_row<={Ifm_Width{1'b0}};
                default:cnt_ifm_row<=cmp_addr_end?(cmp_ifm_H?{Ifm_Width{1'b0}}:cnt_ifm_row+1'b1):cnt_ifm_row;
            endcase
        end


    always@(*)//cmp_ifm_H---obviously,this is pretty useful signal
        begin
            case(state)//思�?�一下这里�?�辑变换，然后改�?�?
                default:cmp_ifm_H=(cnt_ifm_row==ifm_H-1'b1);
            endcase
        end

    always@(*)//addrout_curr---
        begin
            case(state)
                6'd35: addrout_curr=cnt_col;
                // default:addrout_curr=cnt_col+pad_cnt;//根据padding（pad_cnt=1 3 5 ....）来调控真实的写入地�?
                default:addrout_curr=cnt_col+pad_cnt;
            endcase
        end

    always@(*)//addrout_next 写BRAM1-15�?2�?16�?1�?2地址不用pad_cnt来赋�?,直接采用两次数据传输之间的差值就行赋值，差�?�为input feature map的宽�?+上一个传输的右padding,以及下一次传输的的左padding
        begin     //addrout_curr �? addrout_next 之间由一些本质的关系：input feature map的宽�? 以及padding，这里分�?从两个角度利用这些本质进行赋值，设计思路非常nice�?
            case(state)
                // default:addrout_next=addrout_curr+ifm_L+pad_lef+pad_rig;
                default:addrout_next=addrout_curr+(ifm_L_channel>>4)+pad_lef_addr_num+pad_rig_addr_num;//这里面要改，因为先�?�道再L，所以这里是应该是addrout_next=addrout_curr+ifm_L*channel/8?
            endcase
        end

    always@(*)//addrout_row------------This part shows the address written to the bram
        begin
            case(state)               
                6'd32:addrout_row={addrout_curr,{(Write_Addr_Width*27){1'b0}},addrout_next,{(Write_Addr_Width*4){1'b0}}};
                6'd31:addrout_row={{(Write_Addr_Width*1){1'b0}},addrout_curr,{(Write_Addr_Width*27){1'b0}},addrout_next,{(Write_Addr_Width*3){1'b0}}};
                6'd30:addrout_row={{(Write_Addr_Width*2){1'b0}},addrout_curr,{(Write_Addr_Width*27){1'b0}},addrout_next,{(Write_Addr_Width*2){1'b0}}};
                6'd29:addrout_row={{(Write_Addr_Width*3){1'b0}},addrout_curr,{(Write_Addr_Width*27){1'b0}},addrout_next,{(Write_Addr_Width*1){1'b0}}};
                6'd28:addrout_row={{(Write_Addr_Width*4){1'b0}},addrout_curr,{(Write_Addr_Width*27){1'b0}},addrout_next};
                6'd27:addrout_row={{(Write_Addr_Width*5){1'b0}},addrout_curr,{(Write_Addr_Width*27){1'b0}}};
                6'd26:addrout_row={{(Write_Addr_Width*6){1'b0}},addrout_curr,{(Write_Addr_Width*26){1'b0}}};
                6'd25:addrout_row={{(Write_Addr_Width*7){1'b0}},addrout_curr,{(Write_Addr_Width*25){1'b0}}};
                6'd24:addrout_row={{(Write_Addr_Width*8){1'b0}},addrout_curr,{(Write_Addr_Width*24){1'b0}}};
                6'd23:addrout_row={{(Write_Addr_Width*9){1'b0}},addrout_curr,{(Write_Addr_Width*23){1'b0}}};
                6'd22:addrout_row={{(Write_Addr_Width*10){1'b0}},addrout_curr,{(Write_Addr_Width*22){1'b0}}};
                6'd21:addrout_row={{(Write_Addr_Width*11){1'b0}},addrout_curr,{(Write_Addr_Width*21){1'b0}}};
                6'd20:addrout_row={{(Write_Addr_Width*12){1'b0}},addrout_curr,{(Write_Addr_Width*20){1'b0}}};
                6'd19:addrout_row={{(Write_Addr_Width*13){1'b0}},addrout_curr,{(Write_Addr_Width*19){1'b0}}};
                6'd18:addrout_row={{(Write_Addr_Width*14){1'b0}},addrout_curr,{(Write_Addr_Width*18){1'b0}}};
                6'd17:addrout_row={{(Write_Addr_Width*15){1'b0}},addrout_curr,{(Write_Addr_Width*17){1'b0}}};
                6'd16:addrout_row={{(Write_Addr_Width*16){1'b0}},addrout_curr,{(Write_Addr_Width*16){1'b0}}};
                6'd15:addrout_row={{(Write_Addr_Width*17){1'b0}},addrout_curr,{(Write_Addr_Width*15){1'b0}}};
                6'd14:addrout_row={{(Write_Addr_Width*18){1'b0}},addrout_curr,{(Write_Addr_Width*14){1'b0}}};
                6'd13:addrout_row={{(Write_Addr_Width*19){1'b0}},addrout_curr,{(Write_Addr_Width*13){1'b0}}};
                6'd12:addrout_row={{(Write_Addr_Width*20){1'b0}},addrout_curr,{(Write_Addr_Width*12){1'b0}}};
                6'd11:addrout_row={{(Write_Addr_Width*21){1'b0}},addrout_curr,{(Write_Addr_Width*11){1'b0}}};
                6'd10:addrout_row={{(Write_Addr_Width*22){1'b0}},addrout_curr,{(Write_Addr_Width*10){1'b0}}};
                6'd9:addrout_row={{(Write_Addr_Width*23){1'b0}},addrout_curr,{(Write_Addr_Width*9){1'b0}}};
                6'd8:addrout_row={{(Write_Addr_Width*24){1'b0}},addrout_curr,{(Write_Addr_Width*8){1'b0}}};
                6'd7:addrout_row={{(Write_Addr_Width*25){1'b0}},addrout_curr,{(Write_Addr_Width*7){1'b0}}};
                6'd6:addrout_row={{(Write_Addr_Width*26){1'b0}},addrout_curr,{(Write_Addr_Width*6){1'b0}}};
                6'd5:addrout_row={{(Write_Addr_Width*27){1'b0}},addrout_curr,{(Write_Addr_Width*5){1'b0}}};
                6'd4:addrout_row={{(Write_Addr_Width*28){1'b0}},addrout_curr,{(Write_Addr_Width*4){1'b0}}};
                6'd3:addrout_row={{(Write_Addr_Width*29){1'b0}},addrout_curr,{(Write_Addr_Width*3){1'b0}}};
                6'd2:addrout_row={{(Write_Addr_Width*30){1'b0}},addrout_curr,{(Write_Addr_Width*2){1'b0}}};
                6'd1:addrout_row={{(Write_Addr_Width*31){1'b0}},addrout_curr,{(Write_Addr_Width*1){1'b0}}};
                6'd0:addrout_row={{(Write_Addr_Width*32){1'b0}},addrout_curr};
                6'd35:addrout_row={Ram_Row{addrout_curr}};
                default:addrout_row={(Write_Addr_Width*Ram_Row){1'b0}};
            endcase
        end


    always@(*)//dataout
        begin
            case(state)
                6'd35:dataout=64'h0;
                default:dataout=datain;
            endcase
        end

    always@(*)//we----Enable to write a valid number of bytes,be careful
        begin
                case(state)
                    6'd35:we=8'hff;
                    default:we=8'hff;
                endcase
            end   

    always@(*)//ready---Controlling the FIFO for data transmission
        begin
            case(state)
                6'd0,6'd1,6'd2,6'd3,6'd4,6'd5,6'd6,6'd7,6'd8,6'd9,6'd10,6'd11,6'd12,6'd13,6'd14,6'd15,6'd16,6'd17,6'd18,6'd19,
                6'd20,6'd21,6'd22,6'd23,6'd24,6'd25,6'd26,6'd27,6'd28,6'd29,6'd30,6'd31,6'd32:ready=1'b1;
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

                6'd32:weain_row=(overlap_enable)?{weain,27'b0,weain,4'b0}:{weain,32'b0};
                6'd31:weain_row=(overlap_enable)?{1'b0,weain,27'b0,weain,3'b0}:{1'b0,weain,31'b0};
                6'd30:weain_row=(overlap_enable)?{2'b0,weain,27'b0,weain,2'b0}:{2'b0,weain,30'b0};
                6'd29:weain_row=(overlap_enable)?{3'b0,weain,27'b0,weain,1'b0}:{3'b0,weain,29'b0};
                6'd28:weain_row=(overlap_enable)?{4'b0,weain,27'b0,weain}:{4'b0,weain,28'b0};
                6'd27:weain_row={5'b0,weain,27'b0};
                6'd26:weain_row={6'b0,weain,26'b0};
                6'd25:weain_row={7'b0,weain,25'b0};
                6'd24:weain_row={8'b0,weain,24'b0};
                6'd23:weain_row={9'b0,weain,23'b0};
                6'd22:weain_row={10'b0,weain,22'b0};
                6'd21:weain_row={11'b0,weain,21'b0};
                6'd20:weain_row={12'b0,weain,20'b0};
                6'd19:weain_row={13'b0,weain,19'b0};
                6'd18:weain_row={14'b0,weain,18'b0};
                6'd17:weain_row={15'b0,weain,17'b0};
                6'd16:weain_row={16'b0,weain,16'b0};
                6'd15:weain_row={17'b0,weain,15'b0};
                6'd14:weain_row={18'b0,weain,14'b0};
                6'd13:weain_row={19'b0,weain,13'b0};
                6'd12:weain_row={20'b0,weain,12'b0};
                6'd11:weain_row={21'b0,weain,11'b0};
                6'd10:weain_row={22'b0,weain,10'b0};
                6'd9:weain_row={23'b0,weain,9'b0};
                6'd8:weain_row={24'b0,weain,8'b0};
                6'd7:weain_row={25'b0,weain,7'b0};
                6'd6:weain_row={26'b0,weain,6'b0};
                6'd5:weain_row={27'b0,weain,5'b0};
                6'd4:weain_row={28'b0,weain,4'b0};
                6'd3:weain_row={29'b0,weain,3'b0};
                6'd2:weain_row={30'b0,weain,2'b0};
                6'd1:weain_row={31'b0,weain,1'b0};
                6'd0:weain_row={32'b0,weain};
                
                6'd35:weain_row={Ram_Row{1'b1}};
                default:weain_row=33'h0;
            endcase
        end
//--------------------------the command of overlapping part--------------------------begin

     always@(posedge clk)//the command of overlap_enable  
         begin
            case(state)
                default:
                    begin
                        if((state==idle))                                                                                   overlap_enable <= 1'b0;
                        else if((ifm_H+pad_top) <=(9'd28+kernel_size-stride))                                               overlap_enable <= 1'b0;
                        else if ((ifm_H+pad_top-(jump_ifm_H_20+((cnt_overlap==8'd0)?0:kernel_size-stride)))<=28)            overlap_enable <= 1'b0;
                        else                                                                                                overlap_enable <= 1'b1;
                    end
            endcase
         end

    always@(posedge clk)//the command of cnt_overlap  
         begin
            case(state)
                default:
                    begin
                        if (state==idle) cnt_overlap <= 8'd0;
                        else             cnt_overlap <= (cmp_state==1'b1)&&(cmp_addr_end==1'b1)?cnt_overlap+1:cnt_overlap;
                    end
            endcase
         end

         //jump_ifm_H_20
         reg [9:0]jump_ifm_H_20;
    always@(posedge clk)
        begin
            case(state)
                default:
                    begin
                        if (state==idle)    jump_ifm_H_20 <= 10'd0;
                        else                jump_ifm_H_20 <= (cmp_state==1'b1)&&(cmp_addr_end==1'b1)?jump_ifm_H_20+28:jump_ifm_H_20;
                    end
            endcase
         end
//--------------------------the command of overlapping--------------------------end
    





    
    
endmodule
