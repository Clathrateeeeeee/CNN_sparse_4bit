`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/03 11:53:11
// Design Name: 
// Module Name: tb_activation_ctrl
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


module tb_activation_ctrl();
    parameter Ram_Row = 33;
    parameter Axi_Width = 64;
    parameter Ifm_Width = 9;
    parameter Write_Data_Width = 64;
    parameter Read_Data_Width = 64;//16bit-->64bit
    parameter Write_Addr_Width = 12;
    parameter Read_Addr_Width = 12;
    parameter PE_MACS=14;
    parameter Activation_Data_width=4;
    parameter Use_Primitives_OReg=0;
    parameter parallel_channels=64;
    reg clk, rst;
    reg [Axi_Width-1: 0] m_axis_tdata;
    reg m_axis_tvalid;
    reg [Ifm_Width*2-1:0]ifm_L_channel;
    reg [8: 0] ifm_H_Global, ifm_L_Global;
    reg [2: 0] kernel_size;
    reg [1:0] stride;
    reg [8: 0] channels;
    wire m_axis_tready;
    reg mode_sel;

    reg [3: 0] pad_edge;



    wire [1: 0] pad = kernel_size[2:1];//if K=3 ;  pad = 2'b01;if K=7 ;  pad = 2'b11;if K=1 ;  pad = 2'b00;
    wire [1: 0] pad_top = pad_edge[3]? pad: 2'h0;
    wire [1: 0] pad_bot = pad_edge[2]? pad: 2'h0;
    wire [1: 0] pad_lef = pad_edge[1]? pad: 2'h0;
    wire [1: 0] pad_rig = pad_edge[0]? pad: 2'h0;
    reg en_to_fifo;
    wire [Axi_Width-1: 0] s_axis_tdata;
    wire s_axis_tready;
    wire s_axis_tvalid;
    reg Sys_start;
    wire [Ram_Row*Read_Data_Width-1: 0] dout;
    reg last_tile;
    reg [3: 0] data1, data2,data3, data4,data5, data6,data7, data8,data9, data10,data11, data12,data13, data14,data15, data16;
    always #0.5 clk = ~clk;
        //show dout data
    wire [Read_Data_Width-1:0] dout_temp [Ram_Row-1:0];
    generate
        genvar k;
        for (k = 0; k < Ram_Row; k = k + 1)
        begin:identifier466
            assign dout_temp[k] =dout[Read_Data_Width*(k+1)-1:Read_Data_Width*k] ;
        end
    endgenerate
    integer i;

    initial 
        begin
                data1 = 1;
                data2 = 0;
                data3 = 2;
                data4 = 0;
                data5 = 3;
                data6 = 0;
                data7 = 4;
                data8 = 0;
                data9 = 5;
                data10 = 0;
                data11 = 6;
                data12 = 0;
                data13 = 7;
                data14 = 0;
                data15 = 8;
                data16 = 0;
            clk <= 1'b1;
            Sys_start=1'b0;
            rst <= 1'b0;
            m_axis_tvalid <= 1'b0;
            last_tile=1'b0;
            en_to_fifo<=1'b0;
            @(posedge clk);
            repeat(10)@(posedge clk);
            // while(glbl.GSR) @(posedge clk);
            rst <= 1'b1;
            repeat(10)@(posedge clk);
            rst <= 1'b0;
            repeat(100)@(posedge clk);

            repeat(10)@(posedge clk);

            transfer_data1(
                .Th(9'd40),
                .Tl(9'd11),
                .Tn(9'd32),
                .k(3'd3),
                .s(2'b01),
                .pedge(4'b1111),
                .dif(4'd0),
                .msel(1)
            );

            transfer_data1(
                .Th(9'd40),
                .Tl(9'd11),
                .Tn(9'd32),
                .k(3'd3),
                .s(2'b01),
                .pedge(4'b1111),
                .dif(4'd0),
                .msel(1)
            );
            transfer_data1(
                .Th(9'd40),
                .Tl(9'd11),
                .Tn(9'd32),
                .k(3'd3),
                .s(2'b01),
                .pedge(4'b1111),
                .dif(4'd0),
                .msel(1)
            );
            repeat(10)@(posedge clk);
            Sys_start=1'b1;
            en_to_fifo<=1'b1;
            repeat(10) @(posedge clk);
            Sys_start=1'b0;

            //Case 2: k=3 S=1
            /*transfer_data1(
                .Th(9'd18),
                .Tl(9'd10),
                .Tn(9'd64),
                .k(3'd5),
                .s(2'b01),
                .pedge(4'b0000),
                .msel(1)
            );*/



            //总共十二个不同的大小的输入特征图
            repeat(10) @(posedge clk);
            
        end
        reg [7: 0] s_axis_test;
        reg s_axis_tready_test;
    always @(posedge clk)
        begin
            if(rst) 
                begin
            
                    s_axis_test <= 8'd1;
                    s_axis_tready_test<=1'b0;
                end
            else if(s_axis_tready)
                begin
                    s_axis_test<=(s_axis_tready_test==1'b0)?{s_axis_test[6:0],1'b0}:s_axis_test;
                    s_axis_tready_test<=s_axis_tready;
                end
            else
                begin
                    s_axis_test <= s_axis_test;
                    s_axis_tready_test<=s_axis_tready;
                end
        end
    always @(posedge clk)
        begin
            if(rst)
                last_tile <= 1'b0;
            else
                last_tile <= s_axis_test[3]? 1'b1:last_tile;
        end


    task transfer_data1(
        input [8: 0] Th,
        input [8: 0] Tl,
        input [8: 0] Tn,
        input [2: 0] k,
        input [3:0] pedge,
        input [1:0] s,
        input [3:0 ] dif,
        input  msel
    );
        begin: yongxiangniubi
        integer i;
        //reg [3: 0] data1, data2,data3, data4,data5, data6,data7, data8,data9, data10,data11, data12,data13, data14,data15, data16;
        
        /** Configerate parameters of inbuf. **/
        repeat(10) @(posedge clk);
        ifm_L_channel <= Tl*Tn;
        ifm_L_Global <= Tl;
        ifm_H_Global <= Th;
        channels <= Tn;
        kernel_size <= k;
        stride <=s;
        mode_sel <= msel;
        pad_edge <= pedge;

        
        /** Generate a start pulse. **/

        
        /** Transfer data to fifo. **/
        repeat(10) @(posedge clk);
        m_axis_tvalid <= 1'b0;
        //#0.1;

        for(i =1; i < Th*(Tl*Tn/5'd16)*1+1;i=i+1)
        begin
            if(m_axis_tready)
            begin

                data1 <= (i+1+dif)%16;
                data2 <= (i+2+dif)%16;
                data3 <= (i+3+dif)%16;
                data4 <= (i+4+dif)%16;
                data5 <= (i+5+dif)%16;
                data6 <= (i+6+dif)%16;
                data7 <= (i+7+dif)%16;
                data8 <= 0;
                data9 <= (i+8+dif)%16;
                data10 <= 0;
                data11 <= (i+9+dif)%16;
                data12 <= 0;
                data13 <= (i+10+dif)%16;
                data14 <= (i+11+dif)%16;
                data15 <= (i+12+dif)%16;
                data16 <= (i+13+dif)%16;
                m_axis_tvalid <= 1'b1;
                //last_tile <= dif==2?1'b1:1'b0;
                m_axis_tdata <= {data16, data15,data14,data13,data12,data11,data10,data9,data8, data7,data6, data5,data4, data3,data2, data1};
            end

            #1;
        end
        @(posedge clk);
        m_axis_tvalid <= 1'b0;
        @(posedge clk);
        m_axis_tvalid <= 1'b0;
        repeat(15) @(posedge clk);

        @(posedge clk);
        end
    endtask

Activation_ctrl #(
    .Ram_Row(Ram_Row),
    .Axi_Width(Axi_Width),
    .Ifm_Width(Ifm_Width),
    .Write_Data_Width(Write_Data_Width),
    .Read_Data_Width(Read_Data_Width),//16bit-->64bit
    .Write_Addr_Width(Write_Addr_Width),
    .Read_Addr_Width(Read_Addr_Width),
    .PE_MACS(PE_MACS),
    .Activation_Data_width(Activation_Data_width),
    .Use_Primitives_OReg(Use_Primitives_OReg),
    .parallel_channels(parallel_channels)
) 
    ctrl0 (
    .clki(clk),
    .rst(rst),
    .Sys_start(Sys_start),
    .last_tile(last_tile),
    //CNN parameters input 
    .ifm_L_channel(ifm_L_channel),
    .ifm_L(ifm_L_Global),
    .ifm_H(ifm_H_Global),
    .kernel_size(kernel_size),
    .stride(stride),
    .pad_edge(pad_edge),
    .channels(channels),//channel numbers need to be tansfered. 

    
    .clkout(clk),
    
    //AXI-Stream Slave
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .dout(dout),
    .en_to_fifo(en_to_fifo)
);   
    xpm_fifo_axis #(
      .CDC_SYNC_STAGES(2),            // DECIMAL
      .CLOCKING_MODE("common_clock"), // String
      .ECC_MODE("no_ecc"),            // String
      .FIFO_DEPTH(4096),              // DECIMAL
      .FIFO_MEMORY_TYPE("auto"),      // String
      .PACKET_FIFO("false"),          // String
      .PROG_EMPTY_THRESH(10),         // DECIMAL
      .PROG_FULL_THRESH(10),          // DECIMAL
      .RD_DATA_COUNT_WIDTH(1),        // DECIMAL
      .RELATED_CLOCKS(0),             // DECIMAL
      .TDATA_WIDTH(64),               // DECIMAL
      .TDEST_WIDTH(1),                // DECIMAL
      .TID_WIDTH(1),                  // DECIMAL
      .TUSER_WIDTH(1),                // DECIMAL
      .USE_ADV_FEATURES("1000"),      // String
      .WR_DATA_COUNT_WIDTH(1)         // DECIMAL
   )   xpm_fifo_axis (
      .almost_empty_axis(), 
      .almost_full_axis(),   
      .dbiterr_axis(),           
      .m_axis_tdata(s_axis_tdata),           
      .m_axis_tdest(),           
      .m_axis_tid(),               
      .m_axis_tkeep(),           
      .m_axis_tlast(),           
      .m_axis_tstrb(),           
      .m_axis_tuser(),           
      .m_axis_tvalid(s_axis_tvalid),         
      .prog_empty_axis(),     
      .prog_full_axis(),                            
      .rd_data_count_axis(),
      .s_axis_tready(m_axis_tready),         
      .sbiterr_axis(),           
      .wr_data_count_axis(),
      .injectdbiterr_axis(),
      .injectsbiterr_axis(),
      .m_aclk(clk),                       
      .m_axis_tready(s_axis_tready),         
      .s_aclk(clk),                       
      .s_aresetn(~rst),                 
      .s_axis_tdata(m_axis_tdata),           
      .s_axis_tdest(1'b0), 
      .s_axis_tid(1'b0),   
      .s_axis_tkeep(4'b1111),  
      .s_axis_tlast(1'b0),           
      .s_axis_tstrb(4'b1111), 
      .s_axis_tuser(),    
      .s_axis_tvalid(m_axis_tvalid)           
   );    
endmodule