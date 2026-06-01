`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.06.2026 20:34:47
// Design Name: 
// Module Name: MC_queue
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
`include "DRAM_Param.vh"

module MC_queue (
    input wire                     clk,
    input wire                     rst_n,
    
    // CPU / System Bus
    input wire                     req_valid,
    input wire                     req_rw,       // 0: Read, 1: Write
    input wire [ADDR_WIDTH-1:0]   req_addr,
    output wire                    queue_full,
    
    // Scheduler
    input wire                     pop_en,
    output wire                    queue_empty,
    output wire                    out_rw,
    output wire [ADDR_WIDTH-1:0]  out_addr
);

    // FIFO
    reg [ADDR_WIDTH-1:0] addr_fifo [QUEUE_SIZE-1:0];
    reg rw_fifo   [QUEUE_SIZE-1:0];
    
    reg [$clog2(QUEUE_SIZE):0] wr_ptr;
    reg [$clog2(QUEUE_SIZE):0] rd_ptr;
    reg [$clog2(QUEUE_SIZE):0] count;

    assign queue_full  = (count == QUEUE_SIZE);
    assign queue_empty = (count == 0);
    
    assign out_addr = addr_fifo[rd_ptr[$clog2(QUEUE_SIZE)-1:0]];
    assign out_rw = rw_fifo[rd_ptr[$clog2(QUEUE_SIZE)-1:0]];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (req_valid && !queue_full) begin
            addr_fifo[wr_ptr[$clog2(QUEUE_SIZE)-1:0]] <= req_addr;
            rw_fifo[wr_ptr[$clog2(QUEUE_SIZE)-1:0]]   <= req_rw;
            wr_ptr <= wr_ptr + 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (pop_en && !queue_empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({ (req_valid && !queue_full), (pop_en && !queue_empty) })
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end

endmodule
