`ifndef RV32I_DEFINES_VH
`define RV32I_DEFINES_VH

// Major Opcodes (instr[6:0])
`define OPCODE_R_TYPE   7'b0110011
`define OPCODE_I_ARITH  7'b0010011
`define OPCODE_LOAD     7'b0000011
`define OPCODE_STORE    7'b0100011
`define OPCODE_BRANCH   7'b1100011
`define OPCODE_JAL      7'b1101111
`define OPCODE_JALR     7'b1100111
`define OPCODE_LUI      7'b0110111
`define OPCODE_AUIPC    7'b0010111
`define OPCODE_SYSTEM   7'b1110011

// Funct3 Arithmetic / Logical
`define FUNCT3_ADD_SUB  3'b000
`define FUNCT3_SLL      3'b001
`define FUNCT3_SLT      3'b010
`define FUNCT3_SLTU     3'b011
`define FUNCT3_XOR      3'b100
`define FUNCT3_SRL_SRA  3'b101
`define FUNCT3_OR       3'b110
`define FUNCT3_AND      3'b111

// Funct3 Conditional Branches
`define FUNCT3_BEQ      3'b000
`define FUNCT3_BNE      3'b001
`define FUNCT3_BLT      3'b100
`define FUNCT3_BGE      3'b101
`define FUNCT3_BLTU     3'b110
`define FUNCT3_BGEU     3'b111

// Decoded ALU Operation Select (4-bit internal control)
`define ALU_ADD         4'b0000
`define ALU_SUB         4'b1000
`define ALU_SLL         4'b0001
`define ALU_SLT         4'b0010
`define ALU_SLTU        4'b0011
`define ALU_XOR         4'b0100
`define ALU_SRL         4'b0101
`define ALU_SRA         4'b1101
`define ALU_OR          4'b0110
`define ALU_AND         4'b0111
`define ALU_PASS_B      4'b1111

`endif // RV32I_DEFINES_VH
