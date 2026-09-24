`ifndef RISCV_PKG_SV
`define RISCV_PKG_SV

package riscv_pkg;

    // ============================================================
    // RV32I Opcodes
    // ============================================================

    localparam logic [6:0] OP_R_TYPE = 7'b0110011;
    localparam logic [6:0] OP_I_TYPE = 7'b0010011;
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;

    // ============================================================
    // Basic Parameters
    // ============================================================

    localparam integer XLEN           = 32;
    localparam integer ADDR_WIDTH     = 32;
    localparam integer REG_DEPTH      = 32;
    localparam integer REG_ADDR_WIDTH = 5;

    // ============================================================
    // ALU Operations
    // ============================================================

    localparam logic [3:0] ALU_ADD    = 4'b0000;
    localparam logic [3:0] ALU_SUB    = 4'b0001;
    localparam logic [3:0] ALU_SLL    = 4'b0010;
    localparam logic [3:0] ALU_SLT    = 4'b0011;
    localparam logic [3:0] ALU_SLTU   = 4'b0100;
    localparam logic [3:0] ALU_XOR    = 4'b0101;
    localparam logic [3:0] ALU_SRL    = 4'b0110;
    localparam logic [3:0] ALU_SRA    = 4'b0111;
    localparam logic [3:0] ALU_OR     = 4'b1000;
    localparam logic [3:0] ALU_AND    = 4'b1001;
    localparam logic [3:0] ALU_PASS_B = 4'b1010;

    // ============================================================
    // Branch Types
    // ============================================================

    localparam logic [2:0] BRANCH_BEQ  = 3'b000;
    localparam logic [2:0] BRANCH_BNE  = 3'b001;
    localparam logic [2:0] BRANCH_BLT  = 3'b100;
    localparam logic [2:0] BRANCH_BGE  = 3'b101;
    localparam logic [2:0] BRANCH_BLTU = 3'b110;
    localparam logic [2:0] BRANCH_BGEU = 3'b111;

    // ============================================================
    // Memory Operations
    // ============================================================

    localparam logic [3:0] MEM_BYTE  = 4'd0;
    localparam logic [3:0] MEM_HALF  = 4'd1;
    localparam logic [3:0] MEM_WORD  = 4'd2;
    localparam logic [3:0] MEM_BYTEU = 4'd3;
    localparam logic [3:0] MEM_HALFU = 4'd4;

    // ============================================================
    // Pipeline Stages
    // ============================================================

    localparam logic [1:0] STAGE_FETCH   = 2'b00;
    localparam logic [1:0] STAGE_DECODE  = 2'b01;
    localparam logic [1:0] STAGE_EXECUTE = 2'b10;
    localparam logic [1:0] STAGE_MEMORY  = 2'b11;

    // ============================================================
    // Instruction Field Extraction
    // ============================================================

    function automatic logic [4:0] get_rs1(input logic [31:0] instr);
        get_rs1 = instr[19:15];
    endfunction

    function automatic logic [4:0] get_rs2(input logic [31:0] instr);
        get_rs2 = instr[24:20];
    endfunction

    function automatic logic [4:0] get_rd(input logic [31:0] instr);
        get_rd = instr[11:7];
    endfunction

    function automatic logic [2:0] get_funct3(input logic [31:0] instr);
        get_funct3 = instr[14:12];
    endfunction

    function automatic logic [6:0] get_funct7(input logic [31:0] instr);
        get_funct7 = instr[31:25];
    endfunction

    function automatic logic [6:0] get_opcode(input logic [31:0] instr);
        get_opcode = instr[6:0];
    endfunction

    // ============================================================
    // Immediate Generation
    // ============================================================

    function automatic logic [31:0] sign_extend_i_imm(
        input logic [31:0] instr
    );
        sign_extend_i_imm = {{20{instr[31]}}, instr[31:20]};
    endfunction

    function automatic logic [31:0] sign_extend_s_imm(
        input logic [31:0] instr
    );
        sign_extend_s_imm = {
            {20{instr[31]}},
            instr[31:25],
            instr[11:7]
        };
    endfunction

    function automatic logic [31:0] sign_extend_b_imm(
        input logic [31:0] instr
    );
        sign_extend_b_imm = {
            {19{instr[31]}},
            instr[31],
            instr[7],
            instr[30:25],
            instr[11:8],
            1'b0
        };
    endfunction

    function automatic logic [31:0] sign_extend_u_imm(
        input logic [31:0] instr
    );
        sign_extend_u_imm = {instr[31:12], 12'b0};
    endfunction

    function automatic logic [31:0] sign_extend_j_imm(
        input logic [31:0] instr
    );
        sign_extend_j_imm = {
            {11{instr[31]}},
            instr[31],
            instr[19:12],
            instr[20],
            instr[30:21],
            1'b0
        };
    endfunction

    // ============================================================
    // Reset
    // ============================================================

    localparam logic [31:0] RESET_VECTOR = 32'h0000_0000;

endpackage

`endif