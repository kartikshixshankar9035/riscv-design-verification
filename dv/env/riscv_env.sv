/**
 * @file riscv_env.sv
 * @brief RISC-V Verification Environment
 * @author Verification Team
 * @date 2024
 * 
 * Encapsulates:
 * - Driver (stimulus generation)
 * - Monitor (bus observation)
 * - Scoreboard (result prediction & checking)
 * - Configuration propagation
 */

`ifndef RISCV_ENV_SV
`define RISCV_ENV_SV

class riscv_env extends uvm_env;

    `uvm_component_utils(riscv_env)

    // ========================================================================
    // Verification Components
    // ========================================================================
    
    riscv_driver     driver;
    riscv_monitor    monitor;
    riscv_scoreboard scoreboard;

    // ========================================================================
    // Constructor
    // ========================================================================
    
    function new(string name = "riscv_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ========================================================================
    // UVM Build Phase - Create Environment Components
    // ========================================================================
    
    function void build_phase(uvm_build_phase phase);
        super.build_phase(phase);

        `uvm_info("ENV", "Building RISC-V verification environment", UVM_LOW)

        // Create driver
        driver = riscv_driver::type_id::create("driver", this);

        // Create monitor
        monitor = riscv_monitor::type_id::create("monitor", this);

        // Create scoreboard
        scoreboard = riscv_scoreboard::type_id::create("scoreboard", this);
    endfunction

    // ========================================================================
    // UVM Connect Phase - Bind Components Together
    // ========================================================================
    
    function void connect_phase(uvm_connect_phase phase);
        super.connect_phase(phase);

        `uvm_info("ENV", "Connecting RISC-V verification environment", UVM_LOW)

        // Connect monitor's analysis port to scoreboard's FIFO
        monitor.item_ap.connect(scoreboard.item_fifo.analysis_export);
    endfunction

endclass : riscv_env

`endif // RISCV_ENV_SV
