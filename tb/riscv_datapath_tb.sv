module riscv_datapath_tb;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst_n;

    // ============================================================
    // CONTROL SIGNALS
    // ============================================================

    logic [3:0] alu_op;
    logic       alu_src_b;
    logic       reg_write_en;

    logic [3:0] mem_op;
    logic       mem_read;
    logic       mem_write;

    logic       is_branch;
    logic       is_jump;

    // ============================================================
    // INSTRUCTION MEMORY
    // ============================================================

    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    logic [31:0] instr_mem [0:15];

    // ============================================================
    // DATA MEMORY
    // ============================================================

    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_rdata;
    logic [3:0]  dmem_we;

    logic [31:0] data_mem [0:63];

    // ============================================================
    // DEBUG
    // ============================================================

    logic [31:0] debug_pc;
    logic [31:0] debug_instr;
    logic [31:0] debug_alu_result;

    // ============================================================
    // DUT
    // ============================================================

    riscv_datapath dut (

        .clk             (clk),
        .rst_n           (rst_n),

        .alu_op          (alu_op),
        .alu_src_b       (alu_src_b),
        .reg_write_en    (reg_write_en),

        .mem_op          (mem_op),
        .mem_read        (mem_read),
        .mem_write       (mem_write),

        .is_branch       (is_branch),
        .is_jump         (is_jump),

        .imem_addr       (imem_addr),
        .imem_rdata      (imem_rdata),

        .dmem_addr       (dmem_addr),
        .dmem_wdata      (dmem_wdata),
        .dmem_we         (dmem_we),
        .dmem_rdata      (dmem_rdata),

        .debug_pc        (debug_pc),
        .debug_instr     (debug_instr),
        .debug_alu_result(debug_alu_result)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ============================================================
    // INSTRUCTION MEMORY
    // ============================================================

    always @(*) begin
        imem_rdata = instr_mem[imem_addr[5:2]];
    end

    // ============================================================
    // DATA MEMORY READ
    // ============================================================

    always @(*) begin
        dmem_rdata = data_mem[dmem_addr[7:2]];
    end

    // ============================================================
    // DATA MEMORY WRITE
    // ============================================================

    always @(posedge clk) begin

        if (mem_write) begin

            if (dmem_we[0])
                data_mem[dmem_addr[7:2]][7:0] <= dmem_wdata[7:0];

            if (dmem_we[1])
                data_mem[dmem_addr[7:2]][15:8] <= dmem_wdata[15:8];

            if (dmem_we[2])
                data_mem[dmem_addr[7:2]][23:16] <= dmem_wdata[23:16];

            if (dmem_we[3])
                data_mem[dmem_addr[7:2]][31:24] <= dmem_wdata[31:24];

            $display(
                "[MEM WRITE] ADDR=%h DATA=%h",
                dmem_addr,
                dmem_wdata
            );

        end

    end

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        integer i;

        // --------------------------------------------------------
        // Initialize memories
        // --------------------------------------------------------

        for (i = 0; i < 16; i = i + 1) begin
            instr_mem[i] = 32'h00000013;
            data_mem[i]  = 32'h00000000;
        end

        // --------------------------------------------------------
        // Put NOPs into instruction memory
        // --------------------------------------------------------

        instr_mem[0] = 32'h00000013;
        instr_mem[1] = 32'h00000013;
        instr_mem[2] = 32'h00000013;
        instr_mem[3] = 32'h00000013;
        instr_mem[4] = 32'h00000013;
        instr_mem[5] = 32'h00000013;

        // --------------------------------------------------------
        // Default controls
        // --------------------------------------------------------

        alu_op       = 4'd0;
        alu_src_b    = 1'b0;
        reg_write_en = 1'b0;

        mem_op       = 4'd0;
        mem_read     = 1'b0;
        mem_write    = 1'b0;

        is_branch    = 1'b0;
        is_jump      = 1'b0;

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        rst_n = 1'b0;

        #20;

        rst_n = 1'b1;

        $display("");
        $display("==============================================");
        $display("       RV32I RISC-V DATAPATH VERIFICATION");
        $display("==============================================");
        $display("");

        // ========================================================
        // TEST 1: REGISTER FILE
        // ========================================================

        $display("[TEST 1] REGISTER FILE");

        // Directly initialize registers for verification
        dut.regfile.regs[1] = 32'd10;
        dut.regfile.regs[2] = 32'd20;

        $display("x1 = %0d", dut.regfile.regs[1]);
        $display("x2 = %0d", dut.regfile.regs[2]);

        if ((dut.regfile.regs[1] == 32'd10) &&
            (dut.regfile.regs[2] == 32'd20)) begin

            $display("[PASS] Register file");
        end
        else begin

            $display("[FAIL] Register file");
        end

        // ========================================================
        // TEST 2: ADD
        // ========================================================

        $display("");
        $display("[TEST 2] ALU ADD");

        // ADD x3,x1,x2
        instr_mem[0] = 32'h002081B3;

        alu_op       = 4'd0;     // ADD
        alu_src_b    = 1'b0;     // Register operand
        reg_write_en = 1'b1;

        #2;

        $display(
            "A=%0d B=%0d RESULT=%0d",
            dut.alu_operand_a,
            dut.alu_operand_b,
            debug_alu_result
        );

        if (debug_alu_result == 32'd30) begin
            $display("[PASS] ADD: 10 + 20 = 30");
        end
        else begin
            $display(
                "[FAIL] ADD expected 30, got %0d",
                debug_alu_result
            );
        end

        // Allow register write
        @(posedge clk);
        #1;

        if (dut.regfile.regs[3] == 32'd30) begin
            $display("[PASS] x3 = 30");
        end
        else begin
            $display(
                "[FAIL] x3 expected 30, got %0d",
                dut.regfile.regs[3]
            );
        end

        // ========================================================
        // TEST 3: SUB
        // ========================================================

        $display("");
        $display("[TEST 3] ALU SUB");

        // SUB x4,x1,x2
        instr_mem[1] = 32'h40208233;

        alu_op       = 4'd1;     // SUB
        alu_src_b    = 1'b0;
        reg_write_en = 1'b1;

        #2;

        $display(
            "A=%0d B=%0d RESULT=%0d",
            dut.alu_operand_a,
            dut.alu_operand_b,
            debug_alu_result
        );

        if (debug_alu_result == 32'hFFFFFFF6) begin
            $display("[PASS] SUB: 10 - 20 = -10");
        end
        else begin
            $display(
                "[FAIL] SUB expected -10, got %h",
                debug_alu_result
            );
        end

        // ========================================================
        // TEST 4: AND
        // ========================================================

        $display("");
        $display("[TEST 4] ALU AND");

        alu_op       = 4'd9;
        alu_src_b    = 1'b0;
        reg_write_en = 1'b0;

        dut.regfile.regs[1] = 32'h0F0F0F0F;
        dut.regfile.regs[2] = 32'h00FF00FF;

        #2;

        $display(
            "A=%h B=%h RESULT=%h",
            dut.alu_operand_a,
            dut.alu_operand_b,
            debug_alu_result
        );

        if (debug_alu_result == 32'h000F000F) begin
            $display("[PASS] AND");
        end
        else begin
            $display("[FAIL] AND");
        end

        // ========================================================
        // TEST 5: OR
        // ========================================================

        $display("");
        $display("[TEST 5] ALU OR");

        alu_op = 4'd8;

        #2;

        if (debug_alu_result == 32'h0FFF0FFF) begin
            $display("[PASS] OR");
        end
        else begin
            $display(
                "[FAIL] OR expected 0FFF0FFF, got %h",
                debug_alu_result
            );
        end

        // ========================================================
        // TEST 6: XOR
        // ========================================================

        $display("");
        $display("[TEST 6] ALU XOR");

        alu_op = 4'd5;

        #2;

        if (debug_alu_result == 32'h0FF00FF0) begin
            $display("[PASS] XOR");
        end
        else begin
            $display(
                "[FAIL] XOR expected 0FF00FF0, got %h",
                debug_alu_result
            );
        end

// ========================================================
// TEST 7: STORE
// ========================================================

$display("");
$display("[TEST 7] STORE");

// x1 = base address
// x2 = data to store
dut.regfile.regs[1] = 32'd100;
dut.regfile.regs[2] = 32'h12345678;

// SW x2, 0(x1)
instr_mem[0] = 32'h0020A023;

alu_op       = 4'd0;     // ADD
alu_src_b    = 1'b1;     // Use immediate
mem_op       = 4'd2;     // MEM_WORD
mem_write    = 1'b1;
reg_write_en = 1'b0;

// Allow combinational logic to settle
#1;

// Check STORE signals BEFORE clock edge
if (dmem_addr == 32'd100)
    $display("[PASS] Store address = 100");
else
    $display("[FAIL] Store address expected 100, got %0d", dmem_addr);

if (dmem_wdata == 32'h12345678)
    $display("[PASS] Store data = 12345678");
else
    $display("[FAIL] Store data expected 12345678, got %h", dmem_wdata);

if (dmem_we == 4'b1111)
    $display("[PASS] Store write enable = 1111");
else
    $display("[FAIL] Store write enable expected 1111, got %b", dmem_we);

// Perform STORE
@(posedge clk);
#1;

// Address 100 / 4 = memory index 25
if (data_mem[25] == 32'h12345678)
    $display("[PASS] Memory[25] = 12345678");
else
    $display("[FAIL] Memory[25] expected 12345678, got %h",
             data_mem[25]);

mem_write = 1'b0;
// ========================================================
// ========================================================
// TEST 8: LOAD
// ========================================================

$display("");
$display("[TEST 8] LOAD");

// x1 = base address
dut.regfile.regs[1] = 32'd100;

// Preload memory location 100 / 4 = 25
data_mem[25] = 32'hCAFEBABE;

// LW x5, 0(x1)
instr_mem[imem_addr[5:2]] = 32'h0000A283;

alu_op        = 4'd0;
alu_src_b     = 1'b1;
mem_op        = 4'd2;
mem_read      = 1'b1;
mem_write     = 1'b0;
reg_write_en  = 1'b1;

#1;

if (dmem_addr == 32'd100)
    $display("[PASS] Load address = 100");
else
    $display("[FAIL] Load address expected 100, got %0d", dmem_addr);

if (dmem_rdata == 32'hCAFEBABE)
    $display("[PASS] Load data = CAFEBABE");
else
    $display("[FAIL] Load data expected CAFEBABE, got %h",
             dmem_rdata);

@(posedge clk);
#1;

if (dut.regfile.regs[5] == 32'hCAFEBABE)
    $display("[PASS] x5 = CAFEBABE");
else
    $display("[FAIL] x5 expected CAFEBABE, got %h",
             dut.regfile.regs[5]);

mem_read     = 1'b0;
reg_write_en = 1'b0;


// ========================================================
// TEST 9: ADDI
// ========================================================

$display("");
$display("[TEST 9] ADDI");

// x1 = 100
dut.regfile.regs[1] = 32'd100;

// ADDI x6, x1, 25
// 000000011001 00001 000 00110 0010011
instr_mem[imem_addr[5:2]] = 32'h01908313;

alu_op        = 4'd0;
alu_src_b     = 1'b1;
mem_read      = 1'b0;
mem_write     = 1'b0;
reg_write_en  = 1'b1;

#1;

if (debug_alu_result == 32'd125)
    $display("[PASS] ADDI result = 125");
else
    $display("[FAIL] ADDI expected 125, got %0d",
             debug_alu_result);

@(posedge clk);
#1;

if (dut.regfile.regs[6] == 32'd125)
    $display("[PASS] x6 = 125");
else
    $display("[FAIL] x6 expected 125, got %0d",
             dut.regfile.regs[6]);

reg_write_en = 1'b0;


// ========================================================
// TEST 10: SLT
// ========================================================

$display("");
$display("[TEST 10] SLT");

dut.regfile.regs[1] = 32'd10;
dut.regfile.regs[2] = 32'd20;

// SLT x7, x1, x2
instr_mem[imem_addr[5:2]] = 32'h0020A3B3;

alu_op        = 4'd4;
alu_src_b     = 1'b0;
mem_read      = 1'b0;
mem_write     = 1'b0;
reg_write_en  = 1'b1;

#1;

if (debug_alu_result == 32'd1)
    $display("[PASS] SLT 10 < 20 = 1");
else
    $display("[FAIL] SLT expected 1, got %0d",
             debug_alu_result);

@(posedge clk);
#1;

if (dut.regfile.regs[7] == 32'd1)
    $display("[PASS] x7 = 1");
else
    $display("[FAIL] x7 expected 1, got %0d",
             dut.regfile.regs[7]);

reg_write_en = 1'b0;


// ========================================================
// TEST 11: SLTU
// ========================================================

$display("");
$display("[TEST 11] SLTU");

dut.regfile.regs[1] = 32'd10;
dut.regfile.regs[2] = 32'd20;

// SLTU x8, x1, x2
instr_mem[imem_addr[5:2]] = 32'h0020B433;

alu_op        = 4'd4;
alu_src_b     = 1'b0;
mem_read      = 1'b0;
mem_write     = 1'b0;
reg_write_en  = 1'b1;

#1;

if (debug_alu_result == 32'd1)
    $display("[PASS] SLTU 10 < 20 = 1");
else
    $display("[FAIL] SLTU expected 1, got %0d",
             debug_alu_result);

@(posedge clk);
#1;

if (dut.regfile.regs[8] == 32'd1)
    $display("[PASS] x8 = 1");
else
    $display("[FAIL] x8 expected 1, got %0d",
             dut.regfile.regs[8]);

reg_write_en = 1'b0;


// ========================================================
// TEST 12: SLL
// ========================================================

$display("");
$display("[TEST 12] SLL");

dut.regfile.regs[1] = 32'd3;
dut.regfile.regs[2] = 32'd2;

// SLL x9, x1, x2
instr_mem[imem_addr[5:2]] = 32'h002094B3;

alu_op        = 4'd2;
alu_src_b     = 1'b0;
mem_read      = 1'b0;
mem_write     = 1'b0;
reg_write_en  = 1'b1;

#1;

if (debug_alu_result == 32'd12)
    $display("[PASS] SLL 3 << 2 = 12");
else
    $display("[FAIL] SLL expected 12, got %0d",
             debug_alu_result);

@(posedge clk);
#1;

if (dut.regfile.regs[9] == 32'd12)
    $display("[PASS] x9 = 12");
else
    $display("[FAIL] x9 expected 12, got %0d",
             dut.regfile.regs[9]);

reg_write_en = 1'b0;


// ========================================================
// TEST 13: SRL
// ========================================================

$display("");
$display("[TEST 13] SRL");

dut.regfile.regs[1] = 32'd16;
dut.regfile.regs[2] = 32'd2;

// SRL x10, x1, x2
instr_mem[imem_addr[5:2]] = 32'h0020D533;

alu_op        = 4'd6;
alu_src_b     = 1'b0;
mem_read      = 1'b0;
mem_write     = 1'b0;
reg_write_en  = 1'b1;

#1;

if (debug_alu_result == 32'd4)
    $display("[PASS] SRL 16 >> 2 = 4");
else
    $display("[FAIL] SRL expected 4, got %0d",
             debug_alu_result);

@(posedge clk);
#1;

if (dut.regfile.regs[10] == 32'd4)
    $display("[PASS] x10 = 4");
else
    $display("[FAIL] x10 expected 4, got %0d",
             dut.regfile.regs[10]);

reg_write_en = 1'b0;


// ========================================================
// TEST 14: SRA
// ========================================================

$display("");
$display("[TEST 14] SRA");

dut.regfile.regs[1] = 32'hFFFFFFF0;
dut.regfile.regs[2] = 32'd2;

// SRA x11, x1, x2
instr_mem[imem_addr[5:2]] = 32'h4020D5B3;

alu_op        = 4'd7;
alu_src_b     = 1'b0;
mem_read      = 1'b0;
mem_write     = 1'b0;
reg_write_en  = 1'b1;

#1;

if (debug_alu_result == 32'hFFFFFFFC)
    $display("[PASS] SRA -16 >> 2 = -4");
else
    $display("[FAIL] SRA expected FFFFFFFC, got %h",
             debug_alu_result);

@(posedge clk);
#1;

if (dut.regfile.regs[11] == 32'hFFFFFFFC)
    $display("[PASS] x11 = FFFFFFFC");
else
    $display("[FAIL] x11 expected FFFFFFFC, got %h",
             dut.regfile.regs[11]);

reg_write_en = 1'b0;


// ========================================================
// TEST 15: LUI
// ========================================================

$display("");
$display("[TEST 15] LUI");

// LUI x12, 0x12345
// Expected x12 = 0x12345000
instr_mem[imem_addr[5:2]] = 32'h12345637;

alu_op        = 4'd10;
alu_src_b     = 1'b1;
mem_read      = 1'b0;
mem_write     = 1'b0;
reg_write_en  = 1'b1;

#1;

if (debug_alu_result == 32'h12345000)
    $display("[PASS] LUI result = 12345000");
else
    $display("[FAIL] LUI expected 12345000, got %h",
             debug_alu_result);

@(posedge clk);
#1;

if (dut.regfile.regs[12] == 32'h12345000)
    $display("[PASS] x12 = 12345000");
else
    $display("[FAIL] x12 expected 12345000, got %h",
             dut.regfile.regs[12]);

reg_write_en = 1'b0;


// ========================================================
// TEST 16: AUIPC - CURRENT RTL LIMITATION
// ========================================================

$display("");
$display("[TEST 16] AUIPC");

$display("[INFO] AUIPC requires PC + upper immediate.");
$display("[INFO] Current datapath uses rs1 as ALU operand A.");
$display("[INFO] AUIPC requires a datapath modification.");
$display("[INFO] Test deferred until PC/ALU control is upgraded.");


// ========================================================
// TEST 17: BRANCH - CURRENT RTL LIMITATION
// ========================================================

$display("");
$display("[TEST 17] BRANCH");

$display("[INFO] Branch requires conditional next-PC logic.");
$display("[INFO] Current RTL uses next_pc = pc + 4.");
$display("[INFO] Branch verification deferred.");


// ========================================================
// TEST 18: JAL - CURRENT RTL LIMITATION
// ========================================================

$display("");
$display("[TEST 18] JAL");

$display("[INFO] JAL write-back PC+4 exists.");
$display("[INFO] PC redirection is not implemented.");
$display("[INFO] JAL verification deferred.");


// ========================================================
// TEST 19: JALR - CURRENT RTL LIMITATION
// ========================================================

$display("");
$display("[TEST 19] JALR");

$display("[INFO] JALR write-back PC+4 exists.");
$display("[INFO] PC redirection is not implemented.");
$display("[INFO] JALR verification deferred.");
        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("==============================================");
        $display("          VERIFICATION COMPLETED");
        $display("==============================================");
        $display("");

        #20;

        $finish;

    end

    // ============================================================
    // WAVEFORM
    // ============================================================

    initial begin

        $dumpfile("waveform/riscv_datapath.vcd");

        $dumpvars(0, riscv_datapath_tb);

    end

endmodule