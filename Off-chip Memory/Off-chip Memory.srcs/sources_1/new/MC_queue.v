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


module MC_Queue #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter QUEUE_DEPTH = 16
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // Giao tiếp với CPU (Phía Frontend)
    input  wire                    cpu_req_valid,
    output reg                     cpu_req_ready,
    input  wire                    cpu_cmd_type, // 0: Đọc (Read), 1: Ghi (Write)
    input  wire [ADDR_WIDTH-1:0]   cpu_addr,
    input  wire [DATA_WIDTH-1:0]   cpu_wr_data,

    // Giao tiếp với Bộ lập lịch (To Scheduler)
    output reg                     queue_empty,
    input  wire                    scheduler_ready,
    output wire                    out_cmd_type,
    output wire [ADDR_WIDTH-1:0]   out_addr,
    output wire [DATA_WIDTH-1:0]   out_wr_data
);

    localparam SLOT_WIDTH = 1 + ADDR_WIDTH + DATA_WIDTH;
    
    reg [$clog2(QUEUE_DEPTH)-1:0] wr_ptr;
    reg [$clog2(QUEUE_DEPTH)-1:0] rd_ptr;
    reg [$clog2(QUEUE_DEPTH):0]   queue_count;

    // Sử dụng mảng thanh ghi làm Hàng đợi lệnh (Command Queue)
    reg [SLOT_WIDTH-1:0] cmd_queue [0:QUEUE_DEPTH-1];

    wire [SLOT_WIDTH-1:0] in_packet  = {cpu_cmd_type, cpu_addr, cpu_wr_data};
    wire [SLOT_WIDTH-1:0] out_packet = cmd_queue[rd_ptr];

    assign {out_cmd_type, out_addr, out_wr_data} = out_packet;

    // Trạng thái Đầy / Trống của hàng đợi
    always @(*) begin
        cpu_req_ready = (queue_count < QUEUE_DEPTH);
        queue_empty   = (queue_count == 0);
    end

    // Logic điều khiển Hàng đợi (FIFO Queue Control)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr      <= 0;
            rd_ptr      <= 0;
            queue_count <= 0;
        end else begin
            // Đẩy lệnh từ CPU vào hàng đợi khi CPU sẵn sàng và Hàng đợi chưa đầy
            if (cpu_req_valid && cpu_req_ready) begin
                cmd_queue[wr_ptr] <= in_packet;
                wr_ptr            <= wr_ptr + 1;
            end

            // Bộ lập lịch lấy lệnh ra khi nó sẵn sàng và Hàng đợi không trống
            if (scheduler_ready && !queue_empty) begin
                rd_ptr <= rd_ptr + 1;
            end

            // Cập nhật bộ đếm số lượng phần tử trong hàng đợi
            if ((cpu_req_valid && cpu_req_ready) && !(scheduler_ready && !queue_empty))
                queue_count <= queue_count + 1;
            else if (!(cpu_req_valid && cpu_req_ready) && (scheduler_ready && !queue_empty))
                queue_count <= queue_count - 1;
        end
    end

endmodule
