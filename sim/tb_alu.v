`timescale 1ns / 1ps
`default_nettype none
`include "rv32i_defines.vh"

module tb_alu;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;

    // Unit Under Test
    alu uut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );

    task check(input integer test_id, input reg cond, input [255:0] desc);
        begin
            if (!cond) begin
                $display("[FAIL] Test %0d: %0s | result = %h, zero = %b", test_id, desc, result, zero);
                $finish;
            end else begin
                $display("[PASS] Test %0d: %0s", test_id, desc);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);

        // Test 1: ADD
        a = 32'd25; b = 32'd17; alu_ctrl = `ALU_ADD;
        #10;
        check(1, (result === 32'd42 && zero === 1'b0), "ADD (25 + 17 = 42)");

        // Test 2: SUB with Zero assertion
        a = 32'hA5A5_0000; b = 32'hA5A5_0000; alu_ctrl = `ALU_SUB;
        #10;
        check(2, (result === 32'b0 && zero === 1'b1), "SUB with zero flag assertion");

        // Test 3: SLL (Logical Shift Left)
        a = 32'h0000_000F; b = 32'd4; alu_ctrl = `ALU_SLL;
        #10;
        check(3, (result === 32'h0000_00F0), "SLL (0xF << 4 = 0xF0)");

        // Test 4: SLT Signed Comparison (Negative < Positive)
        a = -32'd10; b = 32'd5; alu_ctrl = `ALU_SLT;
        #10;
        check(4, (result === 32'd1), "SLT (-10 < 5 -> true)");

        // Test 5: SLTU Unsigned Comparison (0xFFFFFFF6 is large unsigned)
        a = -32'd10; b = 32'd5; alu_ctrl = `ALU_SLTU;
        #10;
        check(5, (result === 32'd0), "SLTU (0xFFFFFFF6 < 5 -> false)");

        // Test 6: XOR
        a = 32'hFF00_AA55; b = 32'h00FF_AA55; alu_ctrl = `ALU_XOR;
        #10;
        check(6, (result === 32'hFFFF_0000), "XOR bitwise operation");

        // Test 7: SRL (Logical Shift Right - MSB filled with 0)
        a = 32'h8000_0000; b = 32'd2; alu_ctrl = `ALU_SRL;
        #10;
        check(7, (result === 32'h2000_0000), "SRL (0x80000000 >> 2 = 0x20000000)");

        // Test 8: SRA (Arithmetic Shift Right - MSB sign-extended)
        a = 32'h8000_0000; b = 32'd2; alu_ctrl = `ALU_SRA;
        #10;
        check(8, (result === 32'hE000_0000), "SRA (0x80000000 >>> 2 = 0xE0000000)");

        // Test 9: OR
        a = 32'hF0F0_0000; b = 32'h0F0F_0000; alu_ctrl = `ALU_OR;
        #10;
        check(9, (result === 32'hFFFF_0000), "OR bitwise operation");

        // Test 10: AND
        a = 32'hFFFF_0000; b = 32'h0F0F_FFFF; alu_ctrl = `ALU_AND;
        #10;
        check(10, (result === 32'h0F0F_0000), "AND bitwise operation");

        // Test 11: PASS_B (for LUI bypass)
        a = 32'hAAAA_AAAA; b = 32'h1234_5000; alu_ctrl = `ALU_PASS_B;
        #10;
        check(11, (result === 32'h1234_5000), "PASS_B bypass operation");

        $display("\n>>> All 11 ALU verification tests PASSED cleanly. <<<\n");
        $finish;
    end

endmodule
`default_nettype wire
