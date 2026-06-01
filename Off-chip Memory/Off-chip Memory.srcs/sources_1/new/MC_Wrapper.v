`timescale 1ns / 1ps
`include "DRAM_Param.vh"

module MC_Wrapper (
    input wire clk,
    input wire rst_n,
    
    // Frontend
    input wire cpu_req_valid,
    input wire cpu_req_rw,
    input wire [ADDR_WIDTH-1:0] cpu_req_addr,
    output wire controller_ready,
    
    // Physical Layer Backend
    output wire dram_ras_n,
    output wire dram_cas_n,
    output wire dram_we_n,
    output wire [ADDR_WIDTH-1:0]dram_addr
);

    wire q_empty;
    wire q_pop_en;
    wire q_out_rw;
    wire [ADDR_WIDTH-1:0] q_out_addr;
    wire q_full;

    assign controller_ready = !q_full;

    MC_queue UcmdQueue (
        .clk         (clk),
        .rst_n       (rst_n),
        .req_valid   (cpu_req_valid),
        .req_rw      (cpu_req_rw),
        .req_addr    (cpu_req_addr),
        .queue_full  (q_full),
        .pop_en      (q_pop_en),
        .queue_empty (q_empty),
        .out_rw      (q_out_rw),
        .out_addr    (q_out_addr)
    );
    
    MC_Controller Ucontroller (
        .clk         (clk),
        .rst_n       (rst_n),
        .queue_empty (q_empty),
        .in_rw       (q_out_rw),
        .in_addr     (q_out_addr),
        .pop_en      (q_pop_en),
        .dram_ras_n  (dram_ras_n),
        .dram_cas_n  (dram_cas_n),
        .dram_we_n   (dram_we_n),
        .dram_addr   (dram_addr)
    );

endmodule