`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/20 21:48:23
// Design Name: 
// Module Name: tb_read_ctrl
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


module tb_read_ctrl( );
    parameter Ifm_Width = 9;
    parameter weight_sign_Ram_Row = 32;
    parameter weight_sign_Axi_Width = 64;
    parameter weight_sign_Write_Data_Width = 64;
    parameter weight_sign_Read_Data_Width = 64;//16bit-->64bit
    parameter weight_sign_Write_Addr_Width = 11;
    parameter weight_sign_Read_Addr_Width = 11;

    reg value_en;
    reg weight_sign_Sys_start;
    reg rst;
    reg clk;

    //input [Ifm_Width-1:0]OH_14,//(((ifm_H+pad_top+pad_bot-kernel_size_a)/stride+1)%14==0)?((ifm_H+pad_top+pad_bot-kernel_size_a)/stride+1)/14:((ifm_H+pad_top+pad_bot-kernel_size_a)/stride+1)/14+1'b1;
    reg [Ifm_Width-1:0]Addrtimes_end;// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
    reg  [weight_sign_Read_Addr_Width+4:0] k_k_channels;//kernel_size*kernel_size*channels
    wire weight_sign_m_axis_tready;
    wire [63:0] valid;
    
    reg [weight_sign_Axi_Width-1: 0] weight_sign_m_axis_tdata;
    wire[weight_sign_Axi_Width-1: 0] weight_sign_s_axis_tdata;
    wire weight_sign_s_axis_tvalid;
    wire weight_sign_s_axis_tready;
    reg   en_to_fifo;

    wire [weight_sign_Read_Data_Width*weight_sign_Ram_Row-1:0]dout;


    reg [63:0] index_data;
    always #0.5 clk = ~clk;

    reg weight_sign_m_axis_tvalid;
        integer i;
        integer j,m;
        reg [3:0] base_value;
        reg [3:0] group_base;
        reg [15:0] segment_pattern;
        reg [3:0] start_bit;
            
            // 生成单个256位数据块


    initial 
        begin
            value_en=1'b1;
            for (i = 0; i < 8; i = i + 1) begin
                // 计算当前段的起始位（循环移动）
                segment_pattern = 16'b0;
                
                // 设置8个连续的1，考虑16位边界循环
                for (j = 0; j < 4; j = j + 1) begin
                    segment_pattern[( i + j) % 8] = 1'b1;
                end
                
                // 将生成的16位段放入输出数据中
                index_data[i*8 +: 8] = segment_pattern;
            end
            clk <= 1'b1;
            weight_sign_Sys_start<=1'b0;
            rst <= 1'b0;
            weight_sign_m_axis_tvalid <= 1'b0;

            en_to_fifo<=1'b0;
            @(posedge clk);
            
            repeat(10)@(posedge clk);
            // while(glbl.GSR) @(posedge clk);
            rst <= 1'b1;
            repeat(10)@(posedge clk);
            rst <= 1'b0;
            repeat(10)@(posedge clk);

            transfer_weight_data(
            .Addrtimes_end_r(16),
            .k_k_channels_r(1152)
            );
           
            transfer_weight_data(
            .Addrtimes_end_r(16),
            .k_k_channels_r(1152)
            );
            transfer_weight_data(
            .Addrtimes_end_r(16),
            .k_k_channels_r(1152)
            );

             repeat(100)@(posedge clk);
            weight_sign_Sys_start<=1'b1;
           repeat(1)@(posedge clk); 
           weight_sign_Sys_start<=1'b0;
            repeat(10)@(posedge clk);
             repeat(100)@(posedge clk);
             en_to_fifo<=1;
            
       end
         reg [weight_sign_Read_Addr_Width-1:0]addr_end;
         reg  [weight_sign_Read_Addr_Width-1:0]Addr_end_5;
  //input [Ifm_Width-1:0]OH_14,//(((ifm_H+pad_top+pad_bot-kernel_size_a)/stride+1)%14==0)?((ifm_H+pad_top+pad_bot-kernel_size_a)/stride+1)/14:((ifm_H+pad_top+pad_bot-kernel_size_a)/stride+1)/14+1'b1;
    task transfer_weight_data(
    input [Ifm_Width-1:0]Addrtimes_end_r,// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
    input  [weight_sign_Read_Addr_Width+4:0] k_k_channels_r//kernel_size*kernel_size*channels
    );
        begin

         Addr_end_5=k_k_channels_r>>5;
        addr_end = k_k_channels_r;       

        repeat(10) @(posedge clk);
       Addrtimes_end <= Addrtimes_end_r;
       k_k_channels <= k_k_channels_r;

        /** Generate a start pulse. **/

        
        /** Transfer data to fifo. **/
        repeat(10) @(posedge clk);
        weight_sign_m_axis_tvalid <= 1'b0;
        //#0.1;
        for(i =1; i <8*addr_end+1;i=i+1)
        begin
            if(weight_sign_m_axis_tready)
            begin
                for (m = 0; m <8; m = m + 1) begin
                    // 计算当前段的起始位（循环移动）
                    segment_pattern = 16'b0;
                    
                    // 设置8个连续的1，考虑16位边界循环
                    for (j = 0; j < 4; j = j + 1) begin
                        segment_pattern[( i+m + j) % 8] = 1'b1;
                    end
                    
                    // 将生成的16位段放入输出数据中
                    index_data[i*8 +: 8] <= segment_pattern;
                end

                weight_sign_m_axis_tvalid <= 1'b1;
                //last_tile <= dif==2?1'b1:1'b0;
                weight_sign_m_axis_tdata <= index_data;
            end

            #1;
        end
        @(posedge clk);
        weight_sign_m_axis_tvalid <= 1'b0;
        repeat(15) @(posedge clk);
        end
    endtask

 axis_data_fifo_0 instance_name (
  .s_axis_aresetn(!rst),  // input wire s_axis_aresetn
  .s_axis_aclk(clk),        // input wire s_axis_aclk
  .s_axis_tvalid(weight_sign_m_axis_tvalid),    // input wire s_axis_tvalid
  .s_axis_tready(weight_sign_m_axis_tready),    // output wire s_axis_tready
  .s_axis_tdata(weight_sign_m_axis_tdata),      // input wire [255 : 0] s_axis_tdata
  .m_axis_tvalid(weight_sign_s_axis_tvalid),    // output wire m_axis_tvalid
  .m_axis_tready(weight_sign_s_axis_tready),    // input wire m_axis_tready
  .m_axis_tdata(weight_sign_s_axis_tdata)      // output wire [255 : 0] m_axis_tdata
);
 
    weight_sign_buff_read_ctrl #(
   .Ifm_Width (Ifm_Width),
   .weight_sign_Ram_Row (weight_sign_Ram_Row),
   .weight_sign_Axi_Width (weight_sign_Axi_Width),
   .weight_sign_Write_Data_Width (weight_sign_Write_Data_Width),
   .weight_sign_Read_Data_Width (weight_sign_Read_Data_Width),//16bit-->64bit
   .weight_sign_Write_Addr_Width (weight_sign_Write_Addr_Width),
   .weight_sign_Read_Addr_Width (weight_sign_Read_Addr_Width)
)  
ctrl (

   .clk(clk),
   .value_en(value_en),
   .weight_sign_Sys_start(weight_sign_Sys_start),
   .rst(rst),


   .Addrtimes_end(Addrtimes_end),// = ((ifm_L+pad_lef+pad_rig-kernel_size_a)/stride+1)*OH_14;
   .k_k_channels(k_k_channels),//kernel_size*kernel_size*channels
   .valid(valid),

   .weight_sign_s_axis_tdata(weight_sign_s_axis_tdata),
   .weight_sign_s_axis_tvalid(weight_sign_s_axis_tvalid),
   .weight_sign_s_axis_tready(weight_sign_s_axis_tready),
   .en_to_fifo(en_to_fifo),
   .dout(dout)
);  

endmodule
