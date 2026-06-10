/**
 * @file riscv_pkg.sv
 * @brief RISC-V ISA Package - Global Constants, Opcodes, and Type Definitions
 * @author Design Verification Team
 * @date 2024
 * 
 * This package centralizes all RV32I Base Integer ISA definitions including:
 * - Instruction opcodes and funct fields
 * - ALU operation enumerations
 * - Control signals and state machine enums
 * - Memory operation types
 */

package riscv_pkg;

    // ============================================================================
    // RV32I Base Instruction Set Architecture Opcodes (7-bit)
    // ============================================================================
    
    localparam [6:0] OP_R_TYPE      = 7'b0110011;  // ADD, SUB, SLL, SLT, XOR, SRL, OR, AND
    localparam [6:0] OP_I_TYPE      = 7'b0010011;  // ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    localparam [6:0] OP_LOAD        = 7'b0000011;  // LB, LH, LW, LBU, LHU
    localparam [6:0] OP_STORE       = 7'b0100011;  // SB, SH, SW
    localparam [6:0] OP_BRANCH      = 7'b1100011;  // BEQ, BNE, BLT, BGE, BLTU, BGEU
    localparam [6:0] OP_JAL         = 7'b1101111;  // JAL (Jump and Link)
    localparam [6:0] OP_JALR        = 7'b1100111;  // JALR (Jump and Link Register)
    localparam [6:0] OP_LUI         = 7'b0110111;  // LUI (Load Upper Immediate)
    localparam [6:0] OP_AUIPC       = 7'b0010111;  // AUIPC (Add Upper Immediate to PC)

    // ============================================================================
    // Instruction Field Widths
    // ============================================================================
    
    localparam int XLEN             = 32;          // Register width (RV32)
    localparam int ADDR_WIDTH       = 32;          // Address space
    localparam int REG_DEPTH        = 32;          // Number of registers
    localparam int REG_ADDR_WIDTH   = 5;           // 5-bit register address (log2(32))

    // ============================================================================
    // ALU Operations Enumeration
    // ============================================================================
    
    typedef enum logic [3:0] {
        ALU_ADD     = 4'b0000,
        ALU_SUB     = 4'b0001,
        ALU_SLL     = 4'b0010,  // Shift Left Logical
        ALU_SLT     = 4'b0011,  // Set Less Than (signed)
        ALU_SLTU    = 4'b0100,  // Set Less Than Unsigned
        ALU_XOR     = 4'b0101,
        ALU_SRL     = 4'b0110,  // Shift Right Logical
        ALU_SRA     = 4'b0111,  // Shift Right Arithmetic
        ALU_OR      = 4'b1000,
        ALU_AND     = 4'b1001,
        ALU_PASS_B  = 4'b1010   // Pass operand B (for immediates)
    } alu_op_e;

    // ============================================================================
    // Branch Comparison Types (funct3 field in BRANCH instructions)
    // ============================================================================
    
    typedef enum logic [2:0] {
        BRANCH_BEQ  = 3'b000,   // Branch Equal
        BRANCH_BNE  = 3'b001,   // Branch Not Equal
        BRANCH_BLT  = 3'b100,   // Branch Less Than (signed)
        BRANCH_BGE  = 3'b101,   // Branch Greater or Equal (signed)
        BRANCH_BLTU = 3'b110,   // Branch Less Than Unsigned
        BRANCH_BGEU = 3'b111    // Branch Greater or Equal Unsigned
    } branch_type_e;

    // ============================================================================
    // Load/Store Operation Types (funct3 field in LOAD/STORE instructions)
    // ============================================================================
    
    typedef enum logic [2:0] {
        MEM_BYTE       = 3'b000,  // 8-bit (LB, SB)
        MEM_HALF       = 3'b001,  // 16-bit (LH, SH)
        MEM_WORD       = 3'b010,  // 32-bit (LW, SW)
        MEM_BYTE_UNSIGNED = 3'b100, // 8-bit unsigned (LBU)
        MEM_HALF_UNSIGNED = 3'b101  // 16-bit unsigned (LHU)
    } mem_op_e;

    // ============================================================================
    // Control Unit Output Enumerations
    // ============================================================================
    
    typedef enum logic [1:0] {
        WB_ALU      = 2'b00,    // Write ALU result
        WB_MEM      = 2'b01,    // Write memory load data
        WB_PC_PLUS4 = 2'b10     // Write PC+4 (JAL, JALR)
    } wb_mux_sel_e;

    typedef enum logic [1:0] {
        ALU_SRC_REG = 2'b00,    // ALU operand from register
        ALU_SRC_IMM = 2'b01,    // ALU operand from immediate
        ALU_SRC_PC  = 2'b10     // ALU operand from PC
    } alu_src_e;

    // ============================================================================
    // Pipeline Stage Enumerations (for hazard detection)
    // ============================================================================
    
    typedef enum logic [1:0] {
        STAGE_FETCH    = 2'b00,
        STAGE_DECODE   = 2'b01,
        STAGE_EXECUTE  = 2'b10,
        STAGE_MEMORY   = 2'b11
    } pipeline_stage_e;

    // ============================================================================
    // Instruction Format Extraction Helper Functions
    // ============================================================================
    
    // R-type: funct7[31:25] rs2[24:20] rs1[19:15] funct3[14:12] rd[11:7] opcode[6:0]
    function automatic logic [REG_ADDR_WIDTH-1:0] get_rs1(input logic [31:0] instr);
        return instr[19:15];
    endfunction

    function automatic logic [REG_ADDR_WIDTH-1:0] get_rs2(input logic [31:0] instr);
        return instr[24:20];
    endfunction

    function automatic logic [REG_ADDR_WIDTH-1:0] get_rd(input logic [31:0] instr);
        return instr[11:7];
    endfunction

    function automatic logic [2:0] get_funct3(input logic [31:0] instr);
        return instr[14:12];
    endfunction

    function automatic logic [6:0] get_funct7(input logic [31:0] instr);
        return instr[31:25];
    endfunction

    function automatic logic [6:0] get_opcode(input logic [31:0] instr);
        return instr[6:0];
    endfunction

    // ============================================================================
    // Immediate Value Extraction and Sign Extension
    // ============================================================================
    
    // I-type immediate: sign-extend bits [31:20]
    function automatic logic [31:0] sign_extend_i_imm(input logic [31:0] instr);
        return {{20{instr[31]}}, instr[31:20]};
    endfunction

    // S-type immediate: sign-extend bits [31:25] and [11:7]
    function automatic logic [31:0] sign_extend_s_imm(input logic [31:0] instr);
        return {{20{instr[31]}}, instr[31:25], instr[11:7]};
    endfunction

    // B-type immediate: sign-extend bits [31], [7], [30:25], [11:8]
    function automatic logic [31:0] sign_extend_b_imm(input logic [31:0] instr);
        return {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    endfunction

    // U-type immediate: bits [31:12] shifted left by 12
    function automatic logic [31:0] sign_extend_u_imm(input logic [31:0] instr);
        return {instr[31:12], 12'b0};
    endfunction

    // J-type immediate: sign-extend bits [31], [19:12], [20], [30:21]
    function automatic logic [31:0] sign_extend_j_imm(input logic [31:0] instr);
        return {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
    endfunction

    // ============================================================================
    // Default Parameters
    // ============================================================================
    
    localparam int RESET_VECTOR     = 32'h0000_0000;  // Program counter reset value
    localparam int INSTR_QUEUE_SIZE = 8;              // Instruction queue depth
    localparam int DATA_QUEUE_SIZE  = 8;              // Data queue depth

endpackage : riscv_pkg
