module ping_pong_ctrl#(
    parameter Ram_Row = 33,
    parameter Axi_Width = 64,
    parameter Ifm_Width = 9,
    parameter Write_Data_Width = 64,
    parameter Read_Data_Width = 64,
    parameter Write_Addr_Width = 12,
    parameter Read_Addr_Width = 12,
    parameter PE_MACS = 14,
    parameter Activation_Data_width = 4,
    parameter Use_Primitives_OReg = 0,
    parameter parallel_channels = 64
)(
    input  clki,
    input  rst,
    input  Ctrl_start, 

    input  done_tile,        // read完成脉冲
    input  last_tile,
    input  write_finish,     // write完成脉冲

    output reg ping_pong_write,
    output reg ping_pong_read,
    output reg inbuffer_enout   // inbuffer的rden
);

    // ================= 状态定义 =================
    localparam  S_IDLE          = 3'd0,
                S_WRITE_TILE1   = 3'd1,
                S_WRITE_TILE2   = 3'd2,
                S_TRANS         = 3'd3;
//                S_LAST_WRITE    = 3'd4;

    reg [2:0] state, next_state;

    // 捕捉 done_tile 和 write_finish 脉冲
    reg tile_read_done;
    reg tile_write_done;

    // ================= next_state 组合逻辑 =================
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (Ctrl_start) 
                    next_state = S_WRITE_TILE1;
            end

            S_WRITE_TILE1: begin
                if (write_finish) 
                    next_state = S_WRITE_TILE2;
            end

            S_WRITE_TILE2: begin
                if (write_finish) begin
                    if (last_tile)
//                        next_state = S_LAST_WRITE;
                        next_state = S_IDLE;
                    else
                        next_state = S_TRANS;
                end
            end

            S_TRANS: begin
//                if (last_tile && tile_write_done && tile_read_done)
//                    next_state = S_LAST_WRITE;
//                else
//                    next_state = S_TRANS;
                if (last_tile && tile_write_done && tile_read_done)
                    next_state = S_TRANS;
                else
                    next_state = S_TRANS;
                end
//            S_LAST_WRITE: begin
//                if (tile_write_done && tile_read_done)
//                    next_state = S_IDLE;
//            end

            default: next_state = S_IDLE;
        endcase
    end

    // ================= 状态寄存器 =================
    always @(posedge clki or posedge rst) begin
        if (rst)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // ================= 输出控制逻辑 =================
    always @(posedge clki or posedge rst) begin
        if (rst) begin
            ping_pong_write <= 1'b0;
            ping_pong_read  <= 1'b0;
            inbuffer_enout  <= 1'b0;
        end else begin
            case (next_state)
                S_IDLE: begin
                    ping_pong_write <= 1'b0;
                    ping_pong_read  <= 1'b0;
                    inbuffer_enout  <= 1'b0;
                end

                S_WRITE_TILE1: begin
                    ping_pong_write <= 1'b0;
                    ping_pong_read  <= 1'b0;
                    inbuffer_enout  <= 1'b0;
                end

                S_WRITE_TILE2: begin
                    ping_pong_write <= 1'b1;
                    ping_pong_read  <= 1'b0;
                    inbuffer_enout  <= 1'b1;
                end

                S_TRANS: begin
                    // 乒乓切换：同时完成读写后翻转
                    if (tile_read_done && tile_write_done) begin
                        ping_pong_write <= ~ping_pong_write;
                        ping_pong_read  <= ~ping_pong_read;
                    end
                    inbuffer_enout <= ~tile_read_done;
                end

//                S_LAST_WRITE:begin
//                    // 最后一块只翻转read
//                    if (tile_read_done && tile_write_done) begin
//                        ping_pong_write <=  ping_pong_write;
//                        ping_pong_read  <= ~ping_pong_read;
//                    end
//                        inbuffer_enout = ~tile_read_done;
//            end

                default: begin
                    ping_pong_write <= 1'b0;
                    ping_pong_read  <= 1'b0;
                    inbuffer_enout  <= 1'b0;
                end
            endcase
        end
    end

    // ================= 捕捉 write_finish 脉冲 =================
    always @(posedge clki or posedge rst) begin
        if (rst)
            tile_write_done <= 1'b0;
        else begin
            case (state)
                S_WRITE_TILE2,S_TRANS /*S_LAST_WRITE8*/: begin
                    if (tile_read_done && tile_write_done) // 同时完成后清零
                        tile_write_done <= 1'b0;
                    else if (write_finish)
                        tile_write_done <= 1'b1;
                end
                default: tile_write_done <= 1'b0;
            endcase
        end
    end

    // ================= 捕捉 done_tile 脉冲 =================
    always @(posedge clki or posedge rst) begin
        if (rst)
            tile_read_done <= 1'b0;
        else begin
            case (state)
                S_WRITE_TILE2,S_TRANS /*S_LAST_WRITE*/: begin
                    if (tile_read_done && tile_write_done)
                        tile_read_done <= 1'b0;
                    else if (done_tile)
                        tile_read_done <= 1'b1;
                end
                default: tile_read_done <= 1'b0;
            endcase
        end
    end

endmodule