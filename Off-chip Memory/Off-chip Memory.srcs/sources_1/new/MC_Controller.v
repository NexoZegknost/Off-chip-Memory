`timescale 1ns / 1ps
`include "DRAM_Param.vh"

module MC_Controller (
    input wire                     clk,
    input wire                     rst_n,
    
    // Queue
    input wire                     queue_empty,
    input wire                     in_rw,
    input wire [ADDR_WIDTH-1:0]   in_addr,
    output reg                     pop_en,
    
    // DRAM (PHY)
    output reg                     dram_ras_n, // Row Address Strobe
    output reg                     dram_cas_n, // Column Address Strobe
    output reg                     dram_we_n,  // Write Enable
    output reg [ADDR_WIDTH-1:0]   dram_addr
);

    // State
    localparam STATE_IDLE      = 3'b000;
    localparam STATE_ACTIVATE  = 3'b001; // Mở hàng (Row)
    localparam STATE_RCD_WAIT  = 3'b010; // Chờ t_RCD
    localparam STATE_CMD_CAS   = 3'b011; // Phát lệnh Đọc/Ghi (CAS)
    localparam STATE_CL_WAIT   = 3'b100; // Chờ t_CL (đối với lệnh Đọc)
    localparam STATE_PRECHARGE = 3'b101; // Đóng hàng (Precharge)
    localparam STATE_RP_WAIT   = 3'b110; // Chờ t_RP

    reg [2:0] current_state, next_state;
    reg [7:0] timer_count;
    
    reg [ADDR_WIDTH-1:0] active_row;
    reg                   row_open;

    wire [ADDR_WIDTH-1:0] current_row = in_addr & 32'hFFFF0000;
    wire [ADDR_WIDTH-1:0] current_col = in_addr & 32'h0000FFFF;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_IDLE: begin
                if (!queue_empty) begin
                    if (row_open && (active_row == current_row))
                        next_state = STATE_CMD_CAS;   // Row Hit
                    else if (row_open)
                        next_state = STATE_PRECHARGE; // Row Miss
                    else
                        next_state = STATE_ACTIVATE;
                end
            end
            
            STATE_ACTIVATE: next_state = STATE_RCD_WAIT;
            
            STATE_RCD_WAIT: begin
                if (timer_count >= T_RCD - 1) next_state = STATE_CMD_CAS;
            end
            
            STATE_CMD_CAS: begin
                if (!in_rw)
                    next_state = STATE_CL_WAIT;
                else
                    next_state = STATE_IDLE;
            end
            
            STATE_CL_WAIT: begin
                if (timer_count >= T_CL - 1) next_state = STATE_IDLE;
            end
            
            STATE_PRECHARGE: next_state = STATE_RP_WAIT;
            
            STATE_RP_WAIT: begin
                if (timer_count >= T_RP - 1) next_state = STATE_ACTIVATE;
            end
            
            default: next_state = STATE_IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_count  <= 0;
            pop_en       <= 0;
            row_open     <= 0;
            active_row   <= 0;
            dram_ras_n   <= 1;
            dram_cas_n   <= 1;
            dram_we_n    <= 1;
            dram_addr    <= 0;
        end else begin
            dram_ras_n   <= 1;
            dram_cas_n   <= 1;
            dram_we_n    <= 1;
            pop_en       <= 0;

            case (current_state)
                STATE_IDLE: begin
                    timer_count <= 0;
                end

                STATE_ACTIVATE: begin
                    dram_ras_n  <= 0;
                    dram_addr   <= current_row;
                    active_row  <= current_row;
                    row_open    <= 1;
                    timer_count <= 0;
                end

                STATE_RCD_WAIT: begin
                    timer_count <= timer_count + 1;
                end

                STATE_CMD_CAS: begin
                    dram_cas_n <= 0;
                    dram_we_n  <= in_rw;
                    dram_addr  <= current_col;
                    pop_en     <= 1;
                    timer_count <= 0;
                end

                STATE_CL_WAIT: begin
                    timer_count <= timer_count + 1;
                end

                STATE_PRECHARGE: begin
                    dram_ras_n  <= 0;
                    dram_we_n   <= 0;
                    row_open    <= 0;
                    timer_count <= 0;
                end

                STATE_RP_WAIT: begin
                    timer_count <= timer_count + 1;
                end
            endcase
        end
    end

endmodule