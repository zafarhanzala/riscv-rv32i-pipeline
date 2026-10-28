`timescale 1ns / 1ps
`default_nettype none

module tb_execution_stage;

    reg         clk;
    reg         rst;
    reg  [31:0] pc;
    reg  [31:0] instr;
    reg  [31:0] mem_rdata;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire        mem_read;
    wire        mem_write;
    wire        branch;
    wire        jump;
    wire        zero;
    wire        illegal_instr;
    wire [31:0] alu_result;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] imm;

    // Unit Under Test
    execution_stage uut (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .instr(instr),
        .mem_rdata(mem_rdata),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .zero(zero),
        .illegal_instr(illegal_instr),
        .alu_result(alu_result),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .imm(imm)
    );

    // 100MHz clock (10ns period)
    always #5 clk = ~clk;

    task check(input integer step_id, input reg cond, input [255:0] desc);
        begin
            if (!cond) begin
                $display("[FAIL] Step %0d: %0s | alu_result=%0d, rs1=%0d, rs2=%0d", 
                          step_id, desc, alu_result, rs1_data, rs2_data);
                $finish;
            end else begin
                $display("[PASS] Step %0d: %0s", step_id, desc);
            end
        end
    endtask

    initial begin
        $dumpfile("tb_execution_stage.vcd");
        $dumpvars(0, tb_execution_stage);

        clk       = 0;
        rst       = 1;
        pc        = 32'h0000_0000;
        instr     = 32'h0000_0013; // NOP (ADDI x0, x0, 0)
        mem_rdata = 32'b0;

        #15;
        rst = 0;
        @(negedge clk);

        // Step 1: ADDI x1, x0, 15 (0x00F00093)
        instr = 32'h00F00093;
        #1;
        check(1, (alu_result === 32'd15), "Decode & compute: ADDI x1, x0, 15");
        @(negedge clk); // Commit to x1

        // Step 2: ADDI x2, x0, 25 (0x01900113)
        instr = 32'h01900113;
        #1;
        check(2, (alu_result === 32'd25), "Decode & compute: ADDI x2, x0, 25");
        @(negedge clk); // Commit to x2

        // Step 3: ADD x3, x1, x2 (0x002081B3) -> 15 + 25 = 40
        instr = 32'h002081B3;
        #1;
        check(3, (rs1_data === 32'd15 && rs2_data === 32'd25 && alu_result === 32'd40), 
              "Register dependency & arithmetic: ADD x3, x1, x2 (15 + 25 = 40)");
        @(negedge clk); // Commit to x3

        // Step 4: SUB x4, x3, x1 (0x40118233) -> 40 - 15 = 25
        instr = 32'h40118233;
        #1;
        check(4, (rs1_data === 32'd40 && rs2_data === 32'd15 && alu_result === 32'd25), 
              "Chained register dependency: SUB x4, x3, x1 (40 - 15 = 25)");
        @(negedge clk); // Commit to x4

        // Step 5: SW x4, 8(x1) (0x0040A423) -> mem_addr = 15 + 8 = 23, mem_wdata = 25
        instr = 32'h0040A423;
        #1;
        check(5, (mem_write === 1'b1 && mem_addr === 32'd23 && mem_wdata === 32'd25), 
              "Store generation: SW x4, 8(x1) -> Addr: 23, Data: 25");
        @(negedge clk);

        // Step 6: LW x5, 8(x1) (0x0080A283) -> mem_addr = 23, mem_read = 1
        instr     = 32'h0080A283;
        mem_rdata = 32'hCAFE_BABE; // Injected data from simulated RAM
        #1;
        check(6, (mem_read === 1'b1 && mem_addr === 32'd23), 
              "Load generation: LW x5, 8(x1) -> Addr: 23, asserting mem_read");
        @(negedge clk); // Commit mem_rdata into x5

        // Verify x5 got CAFEBABE
        instr = 32'h00028313; // ADDI x6, x5, 0 (Probe x5)
        #1;
        check(7, (rs1_data === 32'hCAFE_BABE), 
              "Memory load write-back: x5 successfully holds 0xCAFEBABE");
        @(negedge clk);

        // Step 8: BEQ x2, x4, -8 (0xFE410CE3) -> both hold 25 -> zero = 1
        instr = 32'hFE410CE3;
        #1;
        check(8, (branch === 1'b1 && zero === 1
cat << 'EOF' > Makefile
# Toolchain variables
IVERILOG = iverilog
VVP      = vvp
VERILATOR = verilator
GTKWAVE  = gtkwave

# Flags
IFLAGS   = -g2001 -Irtl
VFLAGS   = --lint-only -Wall -Irtl

# Directories
RTL_DIR  = rtl
SIM_DIR  = sim

# Source files
RTL_SRCS = $(RTL_DIR)/immediate_gen.v \
           $(RTL_DIR)/instruction_decode.v \
           $(RTL_DIR)/register_file.v \
           $(RTL_DIR)/alu.v \
           $(RTL_DIR)/execution_stage.v

.PHONY: all lint test sim_decode sim_regfile sim_alu sim_stage waves clean

all: lint test

# 1. Static Linting Target
lint:
	@echo "=== Running Verilator Lint Checks ==="
	$(VERILATOR) $(VFLAGS) $(RTL_SRCS)
	@echo "[LINT CLEAN] All RTL modules passed Verilator checks."

# 2. Comprehensive Test Target
test: sim_decode sim_regfile sim_alu sim_stage
	@echo "\n=============================================="
	@echo "  ALL RV32I COMPONENT & STAGE TESTS PASSED"
	@echo "=============================================="

# 3. Individual Testbench Targets
sim_decode:
	$(IVERILOG) $(IFLAGS) -o sim_decode $(RTL_DIR)/instruction_decode.v $(RTL_DIR)/immediate_gen.v $(SIM_DIR)/tb_decode_unit.v
	$(VVP) sim_decode

sim_regfile:
	$(IVERILOG) $(IFLAGS) -o sim_regfile $(RTL_DIR)/register_file.v $(SIM_DIR)/tb_regfile.v
	$(VVP) sim_regfile

sim_alu:
	$(IVERILOG) $(IFLAGS) -o sim_alu $(RTL_DIR)/alu.v $(SIM_DIR)/tb_alu.v
	$(VVP) sim_alu

sim_stage:
	$(IVERILOG) $(IFLAGS) -o sim_stage $(RTL_SRCS) $(SIM_DIR)/tb_execution_stage.v
	$(VVP) sim_stage

# 4. Waveform Inspection Target
waves: sim_stage
	$(GTKWAVE) tb_execution_stage.vcd &

# 5. Clean Workspace
clean:
	rm -f sim_decode sim_regfile sim_alu sim_stage
	rm -f *.vcd *.fst *.log
