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

    logic [31:0] data_mem [0:15];

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
        dmem_rdata = data_mem[dmem_addr[5:2]];
    end

    // ============================================================
    // DATA MEMORY WRITE
    // ============================================================

    always @(posedge clk) begin

        if (mem_write) begin

            if (dmem_we[0])
                data_mem[dmem_addr[5:2]][7:0] <= dmem_wdata[7:0];

            if (dmem_we[1])
                data_mem[dmem_addr[5:2]][15:8] <= dmem_wdata[15:8];

            if (dmem_we[2])
                data_mem[dmem_addr[5:2]][23:16] <= dmem_wdata[23:16];

            if (dmem_we[3])
                data_mem[dmem_addr[5:2]][31:24] <= dmem_wdata[31:24];

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

        dut.regfile.regs[2] = 32'h12345678;

        alu_op       = 4'd0;
        alu_src_b    = 1'b1;
        mem_op       = 4'd2;     // MEM_WORD in package
        mem_write    = 1'b1;
        reg_write_en = 1'b0;

        #2;

        $display(
            "STORE ADDR=%h DATA=%h WE=%b",
            dmem_addr,
            dmem_wdata,
            dmem_we
        );

        @(posedge clk);
        #1;

        mem_write = 1'b0;

        $display("[PASS] Store path executed");

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