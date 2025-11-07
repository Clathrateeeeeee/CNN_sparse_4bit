`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/07/17 17:14:38
// Design Name: 
// Module Name: Inbuff
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


module Inbuff#(
    parameter Ram_Row = 33,
    parameter Axi_Width = 64,
    parameter Ifm_Width = 10,
    parameter Write_Data_Width = 64,
    parameter Read_Data_Width = 64,//16bit-->64bit
    parameter Write_Addr_Width = 9,
    parameter Read_Addr_Width = 9,//11-->9 
    parameter Use_Primitives_OReg = 1
)(
    input clki,
    input rst,
    input start,
    output finished,//one tile finish signal
    
    //CNN parameters input 
    input mode_sel,//no use，let it = 1
    input [Ifm_Width*2-1:0]ifm_L_channel,
    input [Ifm_Width-1:0]ifm_L,
    input [Ifm_Width-1:0]ifm_H,
    input [2: 0]kernel_size,
    input [1:0]stride,////no use
    input [3: 0]pad_edge,
    input [Ifm_Width-1:0]channels,//channel numbers need to be tansfered. 

    /*ping_pong*/
    input   ping_pong_write,//From the written data, 0 is low and 1  is high;
    input   ping_pong_read, //From the raeding data, 0 is low and 1  is high;
    
    //inbuf output
    input clkout,
    input enout,
    input [Read_Addr_Width-1:0]addrout,
    output [Read_Data_Width*Ram_Row-1:0]dout,
    
    //AXI-Stream Slave
    input [Axi_Width-1: 0] s_axis_tdata,
    input s_axis_tvalid,
    output s_axis_tready
);  

    wire [Ram_Row-1:0] weain_row;
    wire [Write_Addr_Width*Ram_Row-1:0] addrout_row;
    wire [Write_Data_Width-1: 0] wrdata;
    wire [Write_Data_Width/8-1: 0] we;
    reg [Ifm_Width-1:0]ifm_H_r, ifm_L_r;
    wire rden;//
    wire [Read_Addr_Width-1:0]rdaddr;//

        /*LRpadding*/
    wire [1: 0] pad = kernel_size[2:1];//if K=3 ;  pad = 2'b01;if K=7 ;  pad = 2'b11;if K=1 ;  pad = 2'b00;
    wire [1: 0] pad_lef = pad_edge[1]? pad: 2'h0;
    wire [1: 0] pad_rig = pad_edge[0]? pad: 2'h0;
    reg [Read_Addr_Width-1:0]rdaddr_pad_zero =2**Read_Addr_Width-1;//Read the data of the last address in bram, which corresponds to the data of 0;
    wire [9:0]channels_8 = channels>>4;//one address stores 64bit datas;//If it is not divisible by 8, consider splicing 0 from the outside

    assign rden = enout ;
    // assign rdaddr = pad_edge[1]?((addrout<pad_lef*channels_8)?rdaddr_pad_zero:(addrout-pad_lef*channels_8)):(addrout);
    assign rdaddr = addrout;

    
    always @(posedge clki) begin//Timing. Insert Register.
        ifm_H_r <= ifm_H;
        ifm_L_r <= ifm_L;
    end


    /*ping_pong operation*/
    wire [Read_Data_Width*Ram_Row-1:0]dout1,dout2;
    wire [Write_Data_Width/8-1: 0] we1,we2;
    wire                           rden1,rden2;




    assign dout   = ping_pong_read ? dout2 : dout1 ;
    assign rden1  = ping_pong_read ? 1'b0  : rden  ;
    assign rden2  = ping_pong_read ? rden  : 1'b0  ;
    assign we1    = ping_pong_write ? 8'd0 : we    ;
    assign we2    = ping_pong_write ? we   : 8'd0  ;


    input_buffer_ctrl_01 #(
        .Ram_Row(Ram_Row),
        .Write_Addr_Width(Write_Addr_Width),
        .Write_Data_Width(Write_Data_Width),
        .Ifm_Width(Ifm_Width)
    ) input_buffer_ctrl_inst (
        .clk(clki), 
        .rst(rst),
        .start(start),
        .mode_sel(mode_sel),
        .valid(s_axis_tvalid),
        .ifm_L_channel(ifm_L_channel),
        .ifm_H(ifm_H_r), 
        .ifm_L(ifm_L_r),   
        .pad_edge(pad_edge),
        .stride(stride),
        .kernel_size(kernel_size),//1~7
        .channels(channels),    
        .datain(s_axis_tdata),
        .we(we),
        .dataout(wrdata),
        .addrout_row(addrout_row),
        .weain_row(weain_row),
        .finished(finished),
        .ready(s_axis_tready)
    );

    
    genvar i;
    generate 
        for(i = 0; i < Ram_Row; i = i+1)
        begin :L_row
            wire [Write_Addr_Width-1: 0] rowaddr = addrout_row[Write_Addr_Width*i+Write_Addr_Width-1:Write_Addr_Width*i];

            bram_WR64bit_36KB #(
                .Write_Data_Width(Write_Data_Width),
                .Read_Data_Width(Read_Data_Width),
                .Write_Addr_Width(Write_Addr_Width),
                .Read_Addr_Width(Read_Addr_Width),
                .Use_Primitives_OReg(Use_Primitives_OReg)//if = 1 ,it will delay a clock to output rddata 
            ) bram_low (
                 .wrclk(clki),                    // 1-bit input clock
                 .rdclk(clkout),                    // 1-bit input clock
                 .rst(rst),                      // 1-bit input reset
                    /* Input Port A */
                 .wren(weain_row[i]),                     // 1-bit input write port enable
                 .we(we1),  // input write enable
                 .wrdata(wrdata), // Input write data port, width defined by Read_Data_Width
                 .wraddr(rowaddr),  // Input write address, width defined by Write_Addr_Width
                    /* Ouput Port B */
                 .rden(rden1),                     // 1-bit input read port enable
                 .rdaddr(rdaddr),  // Input read address, width defined by Write_Addr_Width
                 .rddata(dout1[Read_Data_Width*i+Read_Data_Width-1: Read_Data_Width*i])  // Output read data port, width defined by Read_Data_Width
            );
        end
    endgenerate

    generate 
        for(i = 0; i < Ram_Row; i = i+1)
        begin :H_row
            wire [Write_Addr_Width-1: 0] rowaddr = addrout_row[Write_Addr_Width*i+Write_Addr_Width-1:Write_Addr_Width*i];

            bram_WR64bit_36KB #(
                .Write_Data_Width(Write_Data_Width),
                .Read_Data_Width(Read_Data_Width),
                .Write_Addr_Width(Write_Addr_Width),
                .Read_Addr_Width(Read_Addr_Width),
                .Use_Primitives_OReg(Use_Primitives_OReg)//if = 1 ,it will delay a clock to output rddata 
            ) bram_high (
                 .wrclk(clki),                    // 1-bit input clock
                 .rdclk(clkout),                    // 1-bit input clock
                 .rst(rst),                      // 1-bit input reset
                    /* Input Port A */
                 .wren(weain_row[i]),                     // 1-bit input write port enable
                 .we(we2),  // input write enable
                 .wrdata(wrdata), // Input write data port, width defined by Read_Data_Width
                 .wraddr(rowaddr),  // Input write address, width defined by Write_Addr_Width
                    /* Ouput Port B */
                 .rden(rden2),                     // 1-bit input read port enable
                 .rdaddr(rdaddr),  // Input read address, width defined by Write_Addr_Width
                 .rddata(dout2[Read_Data_Width*i+Read_Data_Width-1: Read_Data_Width*i])  // Output read data port, width defined by Read_Data_Width
            );
        end
    endgenerate
endmodule
