`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/09/22 17:45:46
// Design Name: 
// Module Name: tb_Inbuff
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


module tb_Inbuff();

    parameter Ram_Row = 33;//(14*2-1)+K
    parameter Axi_Width = 64;//4bit 16个�?�道
    parameter Ifm_Width = 9;//0-1023 宽度和高�?
    parameter Write_Data_Width = 64;
    parameter Read_Data_Width = 64;
    parameter Write_Addr_Width = 9;
    parameter Read_Addr_Width = 9;
    parameter Use_Primitives_OReg = 1;
    
    
    //mask2selector
    parameter deep = 512;
    parameter Data_Width = 64;
    
    
    reg clk, rst;
    reg start;
    reg read_start;
    wire finished;
    reg [Axi_Width-1: 0] m_axis_tdata;
    reg m_axis_tvalid;
    reg m_axis_tvalid_reg;
    reg [Ifm_Width*2-1:0]ifm_L_channel;
    reg [8: 0] ifm_H_Global, ifm_L_Global;
    reg [2: 0] kernel_size;
    reg [1:0] stride;
    reg [8: 0] channels;
    wire m_axis_tready;
    reg mode_sel;
    reg enout;
    reg [Read_Data_Width-1: 0] addrout;
    reg [3: 0] pad_edge;




    //mask2selector
    reg [$clog2(deep):0] ram_deep;
    reg [15:0] index;
    wire sele_outvalid;
    wire [447:0] valid_act;



        /*ping_pong*/
    reg   ping_pong_write;//From the written data, 0 is low and 1  is high;From the reading data, 0 is high and 1  is low.
    reg   ping_pong_read;  // At the same time, reading data and writing data are the opposite.


    wire [1: 0] pad = kernel_size[2:1];//if K=3 ;  pad = 2'b01;if K=7 ;  pad = 2'b11;if K=1 ;  pad = 2'b00;
    wire [1: 0] pad_top = pad_edge[3]? pad: 2'h0;
    wire [1: 0] pad_bot = pad_edge[2]? pad: 2'h0;
    wire [1: 0] pad_lef = pad_edge[1]? pad: 2'h0;
    wire [1: 0] pad_rig = pad_edge[0]? pad: 2'h0;
    
    wire [Axi_Width-1: 0] s_axis_tdata;
    wire s_axis_tready;
    wire s_axis_tvalid;
 
    wire [Ifm_Width-1:0] ifm_H_20 =((ifm_H_Global+pad_top+pad_bot-kernel_size+stride)%5'd28==1'b0)?(ifm_H_Global+pad_top+pad_bot-kernel_size+stride)/5'd28:(ifm_H_Global+pad_top+pad_bot-kernel_size+stride)/5'd28+1'b1;//Calculate how many ifm_Ls are stored in an ifm_H;
    wire [Ram_Row*Read_Data_Width-1: 0] dout;

    //show dout data
    wire [Read_Data_Width-1:0] dout_temp [Ram_Row-1:0];
    generate
        genvar k;
        for (k = 0; k < Ram_Row; k = k + 1)
        begin:identifier466
            assign dout_temp[k] =dout[Read_Data_Width*(k+1)-1:Read_Data_Width*k] ;
        end
    endgenerate
     reg [3: 0] data1, data2,data3, data4,data5, data6,data7, data8,data9, data10,data11, data12,data13, data14,data15, data16;
    always #0.5 clk = ~clk;

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
                ram_deep = 512;
                index = 16'b00111100_00001111;
            clk <= 1'b1;
            rst <= 1'b0;
            start <= 1'b0;
            enout <= 1'b0;
            ping_pong_write<= 1'b0;
            ping_pong_read<=1'b0;
            m_axis_tvalid <= 1'b0;
            m_axis_tvalid_reg<=1'b0;
            @(posedge clk);
            repeat(10)@(posedge clk);
            // while(glbl.GSR) @(posedge clk);
            rst <= 1'b1;
            repeat(10)@(posedge clk);
            rst <= 1'b0;
            repeat(100)@(posedge clk);
            
            // //Case 0 k=3
            // transfer_data1(
            //     .Th(9'd15),
            //     .Tl(9'd10),
            //     .Tn(9'd8),
            //     .k(3'd3),
            //     .pedge(4'b1011),
            //     .msel(1)
            // );
            ping_pong_write<= 1'b0;
            ping_pong_read <= 1'b0;
            repeat(10)@(posedge clk);
            //Case 1 k=3
            transfer_data1(
                .Th(9'd46),//h
                .Tl(9'd36),//w
                .Tn(9'd16),//c
                .k(3'd3),
                .s(2'b10),
                .pedge(4'b1111),
                .msel(1)
            );
            repeat(10)@(posedge clk);
            ping_pong_write<= 1'b1;
            ping_pong_read <= 1'b1;
            repeat(10)@(posedge clk);
            //Case 2: k=3 S=1
            transfer_data1(
                .Th(9'd18),
                .Tl(9'd10),
                .Tn(9'd64),
                .k(3'd5),
                .s(2'b01),
                .pedge(4'b0000),
                .msel(1)
            );


            ping_pong_write<= 1'b0;
            ping_pong_read <= 1'b0;
            repeat(10)@(posedge clk);
            for(i = 0; i < 96; i = i+1)
                begin
                    enout <= 1'b1;
                    addrout <= i;
                    @(posedge clk);
                end
                enout <= 1'b0;
            repeat(100)@(posedge clk);

            ping_pong_write<= 1'b1;
            ping_pong_read <= 1'b1;
            repeat(10)@(posedge clk);
            for(i = 0; i < 80; i = i+1)
                begin
                    enout <= 1'b1;
                    addrout <= i;
                    @(posedge clk);
                end
                enout <= 1'b0;
            repeat(100)@(posedge clk);

            // //Case 3: k=3 S=2
            // transfer_data1(
            //     .Th(9'd18),
            //     .Tl(9'd10),
            //     .Tn(9'd64),
            //     .k(3'd3),
            //     .s(2'b01),
            //     .pedge(4'b1001),
            //     .msel(1)
            // );

            // //Case 4: k=3 S=2
            // transfer_data1(
            //     .Th(9'd18),
            //     .Tl(9'd10),
            //     .Tn(9'd64),
            //     .k(3'd3),
            //     .s(2'b01),
            //     .pedge(4'b0111),
            //     .msel(1)
            // );

            // //Case 5: k=3 S=2
            // transfer_data1(
            //     .Th(9'd21),
            //     .Tl(9'd10),
            //     .Tn(9'd64),
            //     .k(3'd3),
            //     .s(2'b01),
            //     .pedge(4'b0010),
            //     .msel(1)
            // );


            




            //总共十二个不同的大小的输入特征图
            repeat(10) @(posedge clk);
            $finish;
        end


    task transfer_data1(
        input [8: 0] Th,
        input [8: 0] Tl,
        input [8: 0] Tn,
        input [2: 0] k,
        input [3:0] pedge,
        input [1:0] s,
        input  msel
    );
        begin: yongxiangniubi
        integer i;
        reg [19:0]  addr_range;
        reg [19:0]  fla;
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
        repeat(10) @(posedge clk);
        start <= 1'b0;
        @(posedge clk);
        start <= 1'b0;
        @(posedge clk);
        start <= 1'b0;
        
        /** Transfer data to fifo. **/
        repeat(10) @(posedge clk);
        m_axis_tvalid <= 1'b0;
        //#0.1;

        for(i =1; i < Th*(Tl*Tn/5'd16)*1+1;i=i+1)
        begin
            if(m_axis_tready)
            begin
                data1 <= (i+1)%16;
                data2 <= (i+2)%16;
                data3 <= (i+3)%16;
                data4 <= (i+4)%16;
                data5 <= (i+5)%16;
                data6 <= (i+6)%16;
                data7 <= (i+7)%16;
                data8 <= 0;
                data9 <= (i+8)%16;
                data10 <= 0;
                data11 <= (i+9)%16;
                data12 <= 0;
                data13 <= (i+10)%16;
                data14 <= (i+11)%16;
                data15 <= (i+12)%16;
                data16 <= (i+13)%16;
                
                
                
                m_axis_tvalid <= 1'b1;
                m_axis_tdata <= {data16, data15,data14,data13,data12,data11,data10,data9,data8, data7,data6, data5,data4, data3,data2, data1};
                
                
            end
            /*else begin
            @(posedge clk);
            m_axis_tvalid<=0;
            m_axis_tdata<=0;
            end*/
            
            #1;
        end
        @(posedge clk);
        m_axis_tvalid <= 1'b0;
        @(posedge clk);
        m_axis_tvalid <= 1'b0;
        repeat(5) @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;
        
        /** Wait inbuf finish. **/
        while(finished == 1'b0) @(posedge clk);
        repeat(5) @(posedge clk);
        
          addr_range <= ifm_H_20*(Tl+pad_lef+pad_rig)*Tn/5'd16;
        /** View data. **/
        repeat(10) @(posedge clk);
        #0.1;
            read_start <= 1'b1;
            enout <= 1'b0;
            addrout<='hx;
            #1;
            read_start <= 1'b0;
        repeat(10) @(posedge clk);
        for(i = 0; i < addr_range; i = i+1)
        begin
            enout <= 1'b1;
            addrout <= i;
            @(posedge clk);
        end
        enout <= 1'b0;
        addrout<='hx;
        repeat(10) @(posedge clk);
        end
    endtask

    //Inbuff
    Inbuff #(
   .Ram_Row(33),
   .Axi_Width(64),
   .Ifm_Width(9),
   .Write_Data_Width(64),
   .Read_Data_Width(64),
   .Write_Addr_Width(9),
   .Read_Addr_Width(9),
   .Use_Primitives_OReg(0)
    )
    Inbuff_init
    (
        .clki(clk),
        .rst(rst),
        .start(start),
        .finished(finished),
        .read_start(read_start),
        
        //CNN parameters input
        .ifm_L_channel(ifm_L_channel), 
        .mode_sel(mode_sel),
        .ifm_H(ifm_H_Global),
        .ifm_L(ifm_L_Global),
        .kernel_size(kernel_size),
        .stride(stride),
        .pad_edge(pad_edge),
        .channels(channels),//channel numbers need to be tansfered. 

        .ping_pong_write(ping_pong_write),
        .ping_pong_read(ping_pong_read),
        
        //inbuf output
        .clkout(clk),
        .enout(enout),
        .addrout(addrout),
        .dout(dout),
        
        //AXI-Stream Slave
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready)
    );  
    
    // axis_fifo_01 axis_fifo_inst(
    //     .clk(clk),
    //     .rstn(~rst),
    //     .m_axis_tdata(s_axis_tdata),
    //     .m_axis_tvalid(s_axis_tvalid),
    //     .m_axis_tready(s_axis_tready),
    //     .s_axis_tdata(m_axis_tdata),
    //     .s_axis_tvalid(m_axis_tvalid),
    //     .s_axis_tready(m_axis_tready)
    // );

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
   )   xpm_fifo_axis_inst515 (
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
   
    //mask2selector
    mask2selector#(
        .deep(deep),
        .Ram_Row(Ram_Row),
        .Data_Width(Data_Width)
    )mask2selector_test(
        //mask
        .clk(clk),
        .rst(rst),
        .kernel_size(kernel_size),
        .stride(stride),
        .inbuff_ready(enout),
        .din(dout),//4bit * 16channels * 33
        //selector
        .index(index),
        .sele_outvalid(sele_outvalid),
        .valid_act(valid_act)
    );

















endmodule
