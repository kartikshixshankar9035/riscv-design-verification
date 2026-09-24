`ifndef RISCV_REGFILE_SV
`define RISCV_REGFILE_SV

module riscv_regfile (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,

    output logic [31:0] rdata1,
    output logic [31:0] rdata2,

    input  logic        we,
    input  logic [4:0]  rd,
    input  logic [31:0] wdata
);

    logic [31:0] regs [0:31];

    integer i;

    // Register write and reset
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end
        else if (we && (rd != 5'd0)) begin
            regs[rd] <= wdata;
        end
    end

    // Combinational read
    always_comb begin
        if (rs1 == 5'd0)
            rdata1 = 32'd0;
        else
            rdata1 = regs[rs1];

        if (rs2 == 5'd0)
            rdata2 = 32'd0;
        else
            rdata2 = regs[rs2];
    end

endmodule

`endif