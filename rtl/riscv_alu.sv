module riscv_alu (
    input  logic [31:0] operand_a,
    input  logic [31:0] operand_b,
    input  logic [3:0]  alu_op,
    input  logic [4:0]  shamt,

    output logic [31:0] result,
    output logic        zero
);

    localparam [3:0] ALU_ADD    = 4'd0;
    localparam [3:0] ALU_SUB    = 4'd1;
    localparam [3:0] ALU_SLL    = 4'd2;
    localparam [3:0] ALU_SLT    = 4'd3;
    localparam [3:0] ALU_SLTU   = 4'd4;
    localparam [3:0] ALU_XOR    = 4'd5;
    localparam [3:0] ALU_SRL    = 4'd6;
    localparam [3:0] ALU_SRA    = 4'd7;
    localparam [3:0] ALU_OR     = 4'd8;
    localparam [3:0] ALU_AND    = 4'd9;
    localparam [3:0] ALU_PASS_B = 4'd10;

    always @(*) begin
        case (alu_op)

            ALU_ADD:
                result = operand_a + operand_b;

            ALU_SUB:
                result = operand_a - operand_b;

            ALU_SLL:
                result = operand_a << shamt;

            ALU_SLT:
                result = ($signed(operand_a) < $signed(operand_b))
                       ? 32'd1 : 32'd0;

            ALU_SLTU:
                result = (operand_a < operand_b)
                       ? 32'd1 : 32'd0;

            ALU_XOR:
                result = operand_a ^ operand_b;

            ALU_SRL:
                result = operand_a >> shamt;

            ALU_SRA:
                result = $signed(operand_a) >>> shamt;

            ALU_OR:
                result = operand_a | operand_b;

            ALU_AND:
                result = operand_a & operand_b;

            ALU_PASS_B:
                result = operand_b;

            default:
                result = 32'd0;

        endcase
    end

    always @(*) begin
        zero = (result == 32'd0);
    end

endmodule