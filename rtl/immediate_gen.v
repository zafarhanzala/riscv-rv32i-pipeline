`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_defines.vh"

module immediate_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);

    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            // I-type: Loads, Immediate Arithmetic, JALR, Environment calls
            `OPCODE_I_ARITH,
            `OPCODE_LOAD,
            `OPCODE_JALR,
            `OPCODE_SYSTEM: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            // S-type: Stores
            `OPCODE_STORE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // B-type: Conditional Branches
            `OPCODE_BRANCH: begin
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            // U-type: LUI, AUIPC (Upper 20 bits shifted left by 12)
            `OPCODE_LUI,
            `OPCODE_AUIPC: begin
                imm = {instr[31:12], 12'b0};
            end

            // J-type: Unconditional Jump (JAL)
            `OPCODE_JAL: begin
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            // Default / R-type (no immediate utilized)
            default: begin
                imm = 32'b0;
            end
        endcase
    end

endmodule
`default_nettype wire
