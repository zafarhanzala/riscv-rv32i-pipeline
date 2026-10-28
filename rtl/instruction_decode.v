`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_defines.vh"

module instruction_decode (
    input  wire [31:0] instr,

    // Extracted Register Addresses & Metadata
    output wire [4:0]  rs1_addr,
    output wire [4:0]  rs2_addr,
    output wire [4:0]  rd_addr,
    output wire [2:0]  funct3,
    output wire [6:0]  funct7,
    output wire [6:0]  opcode,

    // Pipeline Datapath Control Flags
    output reg         reg_write,
    output reg         alu_src_b,    // 0 = rs2_data, 1 = immediate
    output reg         alu_src_a,    // 0 = rs1_data, 1 = PC (for AUIPC / JAL)
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,   // 0 = ALU result, 1 = memory data
    output reg         branch,
    output reg         jump,
    output reg  [3:0]  alu_ctrl,
    output reg         illegal_instr
);

    // Fixed bitfield assignments (RV32I specification)
    assign opcode   = instr[6:0];
    assign rd_addr  = instr[11:7];
    assign funct3   = instr[14:12];
    assign rs1_addr = instr[19:15];
    assign rs2_addr = instr[24:20];
    assign funct7   = instr[31:25];

    always @(*) begin
        // Safe default assignments to avoid latch inference
        reg_write     = 1'b0;
        alu_src_b     = 1'b0;
        alu_src_a     = 1'b0;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        mem_to_reg    = 1'b0;
        branch        = 1'b0;
        jump          = 1'b0;
        alu_ctrl      = `ALU_ADD;
        illegal_instr = 1'b0;

        case (opcode)
            `OPCODE_R_TYPE: begin
                reg_write = 1'b1;
                alu_src_b = 1'b0; // Operand B is rs2
                case (funct3)
                    `FUNCT3_ADD_SUB: alu_ctrl = (funct7[5]) ? `ALU_SUB : `ALU_ADD;
                    `FUNCT3_SLL:     alu_ctrl = `ALU_SLL;
                    `FUNCT3_SLT:     alu_ctrl = `ALU_SLT;
                    `FUNCT3_SLTU:    alu_ctrl = `ALU_SLTU;
                    `FUNCT3_XOR:     alu_ctrl = `ALU_XOR;
                    `FUNCT3_SRL_SRA: alu_ctrl = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                    `FUNCT3_OR:      alu_ctrl = `ALU_OR;
                    `FUNCT3_AND:     alu_ctrl = `ALU_AND;
                    default:         illegal_instr = 1'b1;
                endcase
            end

            `OPCODE_I_ARITH: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1; // Operand B is immediate
                case (funct3)
                    `FUNCT3_ADD_SUB: alu_ctrl = `ALU_ADD;
                    `FUNCT3_SLL:     alu_ctrl = `ALU_SLL;
                    `FUNCT3_SLT:     alu_ctrl = `ALU_SLT;
                    `FUNCT3_SLTU:    alu_ctrl = `ALU_SLTU;
                    `FUNCT3_XOR:     alu_ctrl = `ALU_XOR;
                    `FUNCT3_SRL_SRA: alu_ctrl = (funct7[5]) ? `ALU_SRA : `ALU_SRL;
                    `FUNCT3_OR:      alu_ctrl = `ALU_OR;
                    `FUNCT3_AND:     alu_ctrl = `ALU_AND;
                    default:         illegal_instr = 1'b1;
                endcase
            end

            `OPCODE_LOAD: begin
                reg_write  = 1'b1;
                alu_src_b  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_ctrl   = `ALU_ADD; // Effective address calculation
            end

            `OPCODE_STORE: begin
                alu_src_b = 1'b1;
                mem_write = 1'b1;
                alu_ctrl  = `ALU_ADD; // Effective address calculation
            end

            `OPCODE_BRANCH: begin
                branch    = 1'b1;
                alu_src_b = 1'b0;
                alu_ctrl  = `ALU_SUB; // Arithmetic comparison
            end

            `OPCODE_LUI: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_ctrl  = `ALU_PASS_B; // Forward upper immediate directly
            end

            `OPCODE_AUIPC: begin
                reg_write = 1'b1;
                alu_src_a = 1'b1; // Source PC
                alu_src_b = 1'b1; // Source upper immediate
                alu_ctrl  = `ALU_ADD;
            end

            `OPCODE_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src_a = 1'b1; // PC link calculation
                alu_src_b = 1'b1;
                alu_ctrl  = `ALU_ADD;
            end

            `OPCODE_JALR: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src_b = 1'b1;
                alu_ctrl  = `ALU_ADD;
            end

            default: begin
                illegal_instr = 1'b1;
            end
        endcase
    end

endmodule
`default_nettype wire
