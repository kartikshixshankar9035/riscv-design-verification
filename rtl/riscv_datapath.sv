/**
 * @file riscv_datapath.sv
 * @brief RISC-V 3-Stage Pipeline Datapath
 * @author Design Verification Team
 * @date 2024
 * 
 * Implements a simple 3-stage pipeline:
 * Stage 1 (Fetch):   Fetch instruction from instruction memory
 * Stage 2 (Decode):  Decode instruction, read register file, generate immediates
 * Stage 3 (Execute): Execute ALU operation, access data memory, write-back results
 * 
 * Datapath handles:
 * - Program Counter (PC) management
 * - Instruction fetch and decode
 * - Register file interfacing
 * - Immediate value generation (I, S, B, U, J types)
 * - ALU operand selection and forwarding
 * - Data memory interface
 * - Result write-back
 */

`ifndef RISCV_DATAPATH_SV
`define RISCV_DATAPATH_SV

module riscv_datapath (
    // ========================================================================
    // Clock and Reset
    // ========================================================================
    input  logic        clk,
    input  logic        rst_n,

    // ========================================================================
    // Control Signals from Control Unit
    // ========================================================================
    input  riscv_pkg::alu_op_e alu_op,
    input  logic               alu_src_b,      // Mux control: 0=register, 1=immediate
    input  logic               reg_write_en,
    input  riscv_pkg::mem_op_e mem_op,
    input  logic               mem_read,
    input  logic               mem_write,
    input  logic               is_branch,
    input  logic               is_jump,

    // ========================================================================
    // Instruction Memory Interface
    // ========================================================================
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,

    // ========================================================================
    // Data Memory Interface
    // ========================================================================
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    output logic [3:0]  dmem_we,        // Write enable for each byte
    input  logic [31:0] dmem_rdata,

    // ========================================================================
    // Debug Outputs (optional)
    // ========================================================================
    output logic [31:0] debug_pc,
    output logic [31:0] debug_instr,
    output logic [31:0] debug_alu_result
);

    import riscv_pkg::*;

    // ========================================================================
    // Internal Signals - Stage 1 (Fetch)
    // ========================================================================
    logic [31:0] pc;
    logic [31:0] next_pc;
    logic [31:0] instr;

    // ========================================================================
    // Internal Signals - Stage 2 (Decode)
    // ========================================================================
    logic [4:0]  rs1, rs2, rd;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [6:0]  opcode;
    
    logic [31:0] rf_rdata1, rf_rdata2;
    logic [31:0] imm_extended;

    // ========================================================================
    // Internal Signals - Stage 3 (Execute/Writeback)
    // ========================================================================
    logic [31:0] alu_operand_a, alu_operand_b;
    logic [31:0] alu_result;
    logic [31:0] wb_data;

    // ========================================================================
    // Stage 1: Fetch
    // ========================================================================
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= RESET_VECTOR;
        end else begin
            pc <= next_pc;
        end
    end

    // Simple PC increment (no branching in basic version)
    assign next_pc   = pc + 4;
    assign imem_addr = pc;
    assign instr     = imem_rdata;

    // ========================================================================
    // Stage 2: Decode - Instruction Field Extraction
    // ========================================================================
    
    assign opcode = get_opcode(instr);
    assign funct3 = get_funct3(instr);
    assign funct7 = get_funct7(instr);
    assign rs1    = get_rs1(instr);
    assign rs2    = get_rs2(instr);
    assign rd     = get_rd(instr);

    // ========================================================================
    // Stage 2: Register File Read
    // ========================================================================
    
    riscv_regfile regfile (
        .clk(clk),
        .rst_n(rst_n),
        .rs1(rs1),
        .rs2(rs2),
        .rdata1(rf_rdata1),
        .rdata2(rf_rdata2),
        .we(reg_write_en),
        .rd(rd),
        .wdata(wb_data)
    );

    // ========================================================================
    // Stage 2: Immediate Value Generation
    // ========================================================================
    
    always_comb begin
        case (opcode)
            OP_I_TYPE:  imm_extended = sign_extend_i_imm(instr);
            OP_LOAD:    imm_extended = sign_extend_i_imm(instr);
            OP_STORE:   imm_extended = sign_extend_s_imm(instr);
            OP_BRANCH:  imm_extended = sign_extend_b_imm(instr);
            OP_JAL:     imm_extended = sign_extend_j_imm(instr);
            OP_JALR:    imm_extended = sign_extend_i_imm(instr);
            OP_LUI:     imm_extended = sign_extend_u_imm(instr);
            OP_AUIPC:   imm_extended = sign_extend_u_imm(instr);
            default:    imm_extended = 32'h0;
        endcase
    end

    // ========================================================================
    // Stage 3: ALU Operand Selection
    // ========================================================================
    
    assign alu_operand_a = rf_rdata1;
    assign alu_operand_b = alu_src_b ? imm_extended : rf_rdata2;

    // ========================================================================
    // Stage 3: ALU Instantiation
    // ========================================================================
    
    riscv_alu alu_inst (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .alu_op(alu_op),
        .shamt(rf_rdata2[4:0]),
        .result(alu_result)
    );

    // ========================================================================
    // Stage 3: Data Memory Interface
    // ========================================================================
    
    assign dmem_addr  = alu_result;
    assign dmem_wdata = rf_rdata2;

    // Generate write enable based on memory operation type
    always_comb begin
        dmem_we = 4'b0000;
        if (mem_write) begin
            case (mem_op)
                MEM_BYTE:       dmem_we = 4'b0001; // Byte write
                MEM_HALF:       dmem_we = 4'b0011; // Half-word write
                MEM_WORD:       dmem_we = 4'b1111; // Word write
                default:        dmem_we = 4'b0000;
            endcase
        end
    end

    // ========================================================================
    // Stage 3: Write-Back Mux
    // ========================================================================
    // Select between:
    // - ALU result
    // - Data memory load result
    // - PC+4 (for JAL/JALR)
    
    always_comb begin
        if (opcode == OP_JAL || opcode == OP_JALR) begin
            wb_data = pc + 4;  // Write PC+4 for jump-and-link
        end else if (mem_read && opcode == OP_LOAD) begin
            wb_data = dmem_rdata;  // Write memory data for loads
        end else begin
            wb_data = alu_result;  // Default: write ALU result
        end
    end

    // ========================================================================
    // Debug Outputs
    // ========================================================================
    
    assign debug_pc         = pc;
    assign debug_instr      = instr;
    assign debug_alu_result = alu_result;

endmodule : riscv_datapath

`endif // RISCV_DATAPATH_SV
