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


module index_buff #(
    parameter Ram_Row = 16,
    parameter Axi_Width = 64,
    parameter Ifm_Width = 9,
    parameter Write_Data_Width = 64,
    parameter Read_Data_Width = 64,//16bit-->64bit
    parameter Write_Addr_Width = 11,
    parameter Read_Addr_Width = 11
)(
    input clki,
    input rst,
    input start,
    output finished,
    input read_start,//no use
    
    //CNN parameters input 

    input [Read_Addr_Width+4:0]Addr_end,

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
    reg [Ifm_Width-1:0]ifm_H_r, ifm_L_r;
    wire rden;
    wire [Read_Addr_Width-1:0]rdaddr;



    assign rden = enout ;
 
    assign rdaddr = addrout;



    /*ping_pong operation*/
    wire [Read_Data_Width*Ram_Row-1:0]dout1,dout2;
    wire                           rden1,rden2;
    wire  [Ram_Row-1:0]  we={Ram_Row{1'b1}};

    wire [Ram_Row-1:0] we1, we2;

    assign dout   = ping_pong_read ? dout2 : dout1 ;
    assign rden1  = ping_pong_read ? 1'b0  : rden  ;
    assign rden2  = ping_pong_read ? rden  : 1'b0  ;
    assign we1    = ping_pong_write ? {Ram_Row{1'b0}} : we    ;
    assign we2    = ping_pong_write ? we   : {Ram_Row{1'b0}}  ;


    index_buff_ctrl #(
        .Ram_Row(Ram_Row),
        .Write_Addr_Width(Write_Addr_Width),
        .Write_Data_Width(Write_Data_Width),
        .Read_Addr_Width(Read_Addr_Width),
        .Ifm_Width(Ifm_Width)
    ) index_buf (
        .clk(clki), 
        .rst(rst),
        .start(start),
        .valid(s_axis_tvalid),
        .datain(s_axis_tdata),
        .dataout(wrdata),
        .addrout_row(addrout_row),
        .Addr_end(Addr_end),
        .weain_row(weain_row),
        .finished(finished),
        .ready(s_axis_tready)
    );

    
    genvar i;
    generate 
        for(i = 0; i < Ram_Row; i = i+1)
        begin :L_row
            wire [Write_Addr_Width-1: 0] rowaddr = addrout_row[Write_Addr_Width*i+Write_Addr_Width-1:Write_Addr_Width*i];

            ram_wr_256x512_rd_64x2048_sync weight_sign_buff_low (
                 //.wr_clk(clki),                    // 1-bit input clock
                 //.rd_clk(clkout),
                 .clka(clki),  
                 .ena(we1[i]),
                 .wea(weain_row[i]),                     // 1-bit input write port enable
                 .dina(wrdata), // Input write data port, width defined by Read_Data_Width
                 .addra(rowaddr),  // Input write address, width defined by Write_Addr_Width
                    /* Ouput Port B */
                 .clkb(clki),
                 .enb(rden1),                     // 1-bit input read port enable
                 .addrb(rdaddr),  // Input read address, width defined by Write_Addr_Width
                 .doutb(dout1[Read_Data_Width*i+Read_Data_Width-1: Read_Data_Width*i])  // Output read data port, width defined by Read_Data_Width
            );
        end
    endgenerate

    generate 
        for(i = 0; i < Ram_Row; i = i+1)
        begin :H_row
            wire [Write_Addr_Width-1: 0] rowaddr = addrout_row[Write_Addr_Width*i+Write_Addr_Width-1:Write_Addr_Width*i];

           ram_wr_256x512_rd_64x2048_sync weight_sign_buff_high (
                 //.wr_clk(clki),                    // 1-bit input clock
                 //.rd_clk(clkout),
                 .clka(clki),                    // 1-bit input clock
                 .ena(we2[i]),
                 .wea(weain_row[i]),                     // 1-bit input write port enable
                 .dina(wrdata), // Input write data port, width defined by Read_Data_Width
                 .addra(rowaddr),  // Input write address, width defined by Write_Addr_Width
                    /* Ouput Port B */
                 .clkb(clki),
                 .enb(rden2),                     // 1-bit input read port enable
                 .addrb(rdaddr),  // Input read address, width defined by Write_Addr_Width
                 .doutb(dout2[Read_Data_Width*i+Read_Data_Width-1: Read_Data_Width*i])  // Output read data port, width defined by Read_Data_Width
            );
        end
    endgenerate
endmodule