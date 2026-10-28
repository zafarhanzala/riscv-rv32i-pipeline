`timescale 1ns / 1ps
`default_nettype none

module register_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        reg_write,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);

    // 32 registers, 32 bits wide
    reg [31:0] regs [0:31];

    // Asynchronous dual read ports; x0 is strictly hardwired to zero
    assign rs1_data = (rs1_addr == 5'd0) ? 32'b0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'b0 : regs[rs2_addr];

    // Synchronous single write port; writes to x0 are discarded
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end else if (reg_write && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_data;
        end
    end

endmodule
`default_nettype wire
