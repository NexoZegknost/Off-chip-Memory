`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.06.2026 20:36:53
// Design Name: 
// Module Name: MC_scheduler
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


module MC_Scheduler #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // Giao tiếp với Hàng đợi lệnh (From Command Queue)
    input  wire                    queue_empty,
    output reg                     scheduler_ready,
    input  wire                    in_cmd_type, // 0: Read, 1: Write
    input  wire [ADDR_WIDTH-1:0]   in_addr,
    input  wire [DATA_WIDTH-1:0]   in_wr_data,

    // Giao tiếp với Khối vật lý PHY / Bộ nhớ ngoài (To Memory PHY)
    output reg                     mem_cmd_valid,
    output reg                     mem_cmd_type,
    output reg  [ADDR_WIDTH-1:0]   mem_addr,
    output reg  [DATA_WIDTH-1:0]   mem_wr_data,
    input  wire                    mem_phy_ready
);

    // Định nghĩa các trạng thái của Bộ lập lịch
    localparam IDLE         = 2'b00,
               FETCH_CMD    = 2'b01,
               ISSUE_CMD    = 2'b10,
               WAIT_PHY     = 2'b11;

    reg [1:0] current_state, next_state;
    
    // Các thanh ghi tạm lưu trữ lệnh đang xử lý
    reg                  reg_cmd_type;
    reg [ADDR_WIDTH-1:0] reg_addr;
    reg [DATA_WIDTH-1:0] reg_wr_data;

    // Máy trạng thái chuyển đổi (FSM State Register)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Logic chuyển trạng thái và điều khiển (FSM Combinational Logic)
    always @(*) begin
        next_state = current_state;
        scheduler_ready = 1'b0;
        mem_cmd_valid   = 1'b0;

        case (current_state)
            IDLE: begin
                if (!queue_empty)
                    next_state = FETCH_CMD;
            end

            FETCH_CMD: begin
                scheduler_ready = 1'b1; // Báo cho Queue cho phép lấy dữ liệu ra
                next_state      = ISSUE_CMD;
            end

            ISSUE_CMD: begin
                mem_cmd_valid = 1'b1; // Phát lệnh sang phía Bộ nhớ ngoài
                if (mem_phy_ready)
                    next_state = IDLE;
                else
                    next_state = WAIT_PHY; // Nếu PHY bận, chuyển sang trạng thái chờ
            end

            WAIT_PHY: begin
                mem_cmd_valid = 1'b1;
                if (mem_phy_ready)
                    next_state = IDLE;
            end
        endcase
    end

    // Lưu trữ dữ liệu lệnh vào thanh ghi khi lấy ra từ hàng đợi
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_cmd_type <= 1'b0;
            reg_addr     <= 0;
            reg_wr_data  <= 0;
        end else if (current_state == FETCH_CMD) begin
            reg_cmd_type <= in_cmd_type;
            reg_addr     <= in_addr;
            reg_wr_data  <= in_wr_data;
        end
    end

    // Gán dữ liệu ngõ ra sang khối PHY
    always @(*) begin
        mem_cmd_type = reg_cmd_type;
        mem_addr     = reg_addr;
        mem_wr_data  = reg_wr_data;
    end

endmodule
