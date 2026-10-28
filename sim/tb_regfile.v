`timescale 1ns / 1ps
`default_nettype none

module tb_regfile;

    reg         clk;
    reg         rst;
    reg         reg_write;
    reg  [4:0]  rs1_addr;
    reg  [4:0]  rs2_addr;
    reg  [4:0]  rd_addr;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    // Unit Under Test
    register_file uut (
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

    // 100 MHz clock generation (10ns period)
    always #5 clk = ~clk;

    task check(input integer test_id, input reg cond, input [255:0] desc);
        begin
            if (!cond) begin
                $display("[FAIL] Test %0d: %0s", test_id, desc);
                $finish;
            end else begin
                $display("[PASS] Test %0d: %0s", test_id, desc);
            end
        end
    endtask

    integer j;

    initial begin
        $dumpfile("tb_regfile.vcd");
        $dumpvars(0, tb_regfile);

        // Initialize signals
        clk       = 0;
        rst       = 1;
        reg_write = 0;
        rs1_addr  = 0;
        rs2_addr  = 0;
        rd_addr   = 0;
        rd_data   = 0;

        // Apply reset for 2 clock cycles
        #15;
        rst = 0;
        #10;

        // Test 1: Verify all registers reset to 0
        check(1, (rs1_data === 32'b0 && rs2_data === 32'b0), "Reset assertion (initial state 0)");

        // Test 2: Write to x1 and verify via rs1
        @(negedge clk);
        rd_addr   = 5'd1;
        rd_data   = 32'hDEAD_BEEF;
        reg_write = 1'b1;
        @(negedge clk);
        reg_write = 1'b0;
        rs1_addr  = 5'd1;
        #1;
        check(2, (rs1_data === 32'hDEAD_BEEF), "Synchronous write and combinational read on x1");

        // Test 3: Dual simultaneous read on distinct ports
        @(negedge clk);
        rd_addr   = 5'd2;
        rd_data   = 32'hCAFE_BABE;
        reg_write = 1'b1;
        @(negedge clk);
        reg_write = 1'b0;
        rs1_addr  = 5'd1;
        rs2_addr  = 5'd2;
        #1;
        check(3, (rs1_data === 32'hDEAD_BEEF && rs2_data === 32'hCAFE_BABE), "Concurrent dual-port read on x1 and x2");

        // Test 4: Write Enable gating (reg_write = 0 must discard write)
        @(negedge clk);
        rd_addr   = 5'd3;
        rd_data   = 32'h1234_5678;
        reg_write = 1'b0;
        @(negedge clk);
        rs1_addr  = 5'd3;
        #1;
        check(4, (rs1_data === 32'b0), "Write enable gating (data not written when reg_write=0)");

        // Test 5: x0 hardwired invariant (attempt write to x0, must remain 0)
        @(negedge clk);
        rd_addr   = 5'd0;
        rd_data   = 32'hFFFF_FFFF;
        reg_write = 1'b1;
        @(negedge clk);
        reg_write = 1'b0;
        rs1_addr  = 5'd0;
        rs2_addr  = 5'd0;
        #1;
        check(5, (rs1_data === 32'b0 && rs2_data === 32'b0), "x0 hardwired to zero invariant check");

        // Test 6: Bank sweep write and readback across all general-purpose registers (x1 - x31)
        for (j = 1; j < 32; j = j + 1) begin
            @(negedge clk);
            rd_addr   = j[4:0];
            rd_data   = (32'h1000_0000 * j) + 32'hA5;
            reg_write = 1'b1;
        end
        @(negedge clk);
        reg_write = 1'b0;

        for (j = 1; j < 32; j = j + 1) begin
            rs1_addr = j[4:0];
            #1;
            if (rs1_data !== ((32'h1000_0000 * j) + 32'hA5)) begin
                $display("[FAIL] Test 6: Mismatch in register x%0d. Exp: %h, Got: %h", j, ((32'h1000_0000 * j) + 32'hA5), rs1_data);
                $finish;
            end
        end
        $display("[PASS] Test 6: Full register bank (x1–x31) write and readback verification passed.");

        $display("\n>>> All Register File tests PASSED cleanly. <<<\n");
        $finish;
    end

endmodule
`default_nettype wire
