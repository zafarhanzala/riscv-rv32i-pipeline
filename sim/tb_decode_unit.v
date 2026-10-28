`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_defines.vh"

module tb_decode_unit;

    reg  [31:0] instr;
    wire [4:0]  rs1_addr, rs2_addr, rd_addr;
    wire [2:0]  funct3;
    wire [6:0]  funct7, opcode;
    wire        reg_write, alu_src_b, alu_src_a;
    wire        mem_read, mem_write, mem_to_reg, branch, jump, illegal_instr;
    wire [3:0]  alu_ctrl;
    wire [31:0] imm;

    // Unit Under Test: Decoder
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

    // Unit Under Test: Immediate Generator
    immediate_gen u_imm_gen (
        .instr(instr),
        .imm(imm)
    );

    task check_condition(input integer test_num, input reg condition, input [255:0] test_name);
        begin
            if (!condition) begin
                $display("[FAIL] Test %0d: %0s failed verification.", test_num, test_name);
                $finish;
            end else begin
                $display("[PASS] Test %0d: %0s passed.", test_num, test_name);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_decode_unit.vcd");
        $dumpvars(0, tb_decode_unit);

        // Test 1: R-type: ADD x3, x1, x2 (0x002081B3)
        instr = 32'h002081B3;
        #10;
        check_condition(1, (reg_write === 1'b1 && alu_src_b === 1'b0 && 
                            rd_addr === 5'd3 && rs1_addr === 5'd1 && rs2_addr === 5'd2 && 
                            alu_ctrl === `ALU_ADD), "R-type (ADD)");

        // Test 2: I-type: ADDI x1, x0, -4 (0xFFC00093)
        instr = 32'hFFC00093;
        #10;
        check_condition(2, (reg_write === 1'b1 && alu_src_b === 1'b1 && 
                            rd_addr === 5'd1 && rs1_addr === 5'd0 && 
                            imm === 32'hFFFF_FFFC && alu_ctrl === `ALU_ADD), "I-type (ADDI negative imm)");

        // Test 3: I-type Load: LW x5, 12(x6) (0x00C32283)
        instr = 32'h00C32283;
        #10;
        check_condition(3, (reg_write === 1'b1 && mem_read === 1'b1 && mem_to_reg === 1'b1 && 
                            rd_addr === 5'd5 && rs1_addr === 5'd6 && imm === 32'd12), "I-type (LW)");

        // Test 4: S-type: SW x2, 8(x3) (0x0021A423)
        instr = 32'h0021A423;
        #10;
        check_condition(4, (mem_write === 1'b1 && reg_write === 1'b0 && alu_src_b === 1'b1 && 
                            rs1_addr === 5'd3 && rs2_addr === 5'd2 && imm === 32'd8), "S-type (SW)");

        // Test 5: B-type: BEQ x4, x5, -8 (0xFE520CE3)
        instr = 32'hFE520CE3;
        #10;
        check_condition(5, (branch === 1'b1 && reg_write === 1'b0 && alu_src_b === 1'b0 && 
                            rs1_addr === 5'd4 && rs2_addr === 5'd5 && 
                            imm === 32'hFFFF_FFF8 && alu_ctrl === `ALU_SUB), "B-type (BEQ negative imm)");

        // Test 6: U-type: LUI x7, 0x12345 (0x123453B7)
        instr = 32'h123453B7;
        #10;
        check_condition(6, (reg_write === 1'b1 && alu_src_b === 1'b1 && 
                            rd_addr === 5'd7 && imm === 32'h12345000 && 
                            alu_ctrl === `ALU_PASS_B), "U-type (LUI)");

        // Test 7: J-type: JAL x1, 16 (0x010000EF)
        instr = 32'h010000EF;
        #10;
        check_condition(7, (reg_write === 1'b1 && jump === 1'b1 && 
                            rd_addr === 5'd1 && imm === 32'd16), "J-type (JAL)");

        $display("\n>>> All 7 instruction decode and immediate assertion tests PASSED cleanly. <<<\n");
        $finish;
    end

endmodule
`default_nettype wire
