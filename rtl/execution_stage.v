`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_defines.vh"

module execution_stage (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc,
    input  wire [31:0] instr,
    input  wire [31:0] mem_rdata,

    // Memory Bus Interface
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    output wire        mem_read,
    output wire        mem_write,

    // Branch / Jump Status
    output wire        branch,
    output wire        jump,
    output wire        zero,
    output wire        illegal_instr,

    // Diagnostic Probes
    output wire [31:0] alu_result,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    output wire [31:0] imm
);

    // Internal Decoded Signals
    wire [4:0]  rs1_addr;
    wire [4:0]  rs2_addr;
    wire [4:0]  rd_addr;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [6:0]  opcode;
    wire        reg_write;
    wire        alu_src_b;
    wire        alu_src_a;
    wire        mem_to_reg;
    wire [3:0]  alu_ctrl;

    // Decode Unit
    instruction_decode u_decoder (
        .instr(instr),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src_b(alu_src_b),
        .alu_src_a(alu_src_a),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_ctrl(alu_ctrl),
        .illegal_instr(illegal_instr)
    );

    // Immediate Generator
    immediate_gen u_imm_gen (
        .instr(instr),
        .imm(imm)
    );

    // Write-Back Mux: Select between ALU result and Memory Read Data
    wire [31:0] rd_data = (mem_to_reg) ? mem_rdata : alu_result;

    // 32x32-bit Register File
    register_file u_regfile (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // ALU Operand Multiplexers
    wire [31:0] alu_operand_a = (alu_src_a) ? pc : rs1_data;
    wire [31:0] alu_operand_b = (alu_src_b) ? imm : rs2_data;

    // Arithmetic Logic Unit
    alu u_alu (
        .a(alu_operand_a),
        .b(alu_operand_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero)
    );

    // Assign Memory Interface Outputs
    assign mem_addr  = alu_result;
    assign mem_wdata = rs2_data;

endmodule
`default_nettype wire
