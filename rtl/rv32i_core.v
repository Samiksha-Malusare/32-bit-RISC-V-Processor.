
`timescale 1ns/1ps

module rv32i_core (
    input wire clk,
    input wire reset,
    input wire [31:0] instr,
    input wire [31:0] mem_rdata,

    output reg [31:0] pc,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    output wire mem_we
);

    reg [31:0] registers [0:31];

    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1 = instr[19:15];
    wire [4:0] rs2 = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

    wire [31:0] A = (rs1 == 0) ? 0 : registers[rs1];
    wire [31:0] B = (rs2 == 0) ? 0 : registers[rs2];

    reg [31:0] immediate;
    reg [31:0] alu_result;
    reg [31:0] write_data;
    reg reg_write;
    reg mem_write;
    reg branch;

    wire [31:0] next_pc;

    assign mem_addr = alu_result;
    assign mem_wdata = B;
    assign mem_we = mem_write;

    always @(*) begin
        immediate = 0;

        case (opcode)
            7'b0010011, 7'b0000011:
                immediate = {{20{instr[31]}}, instr[31:20]};

            7'b0100011:
                immediate = {{20{instr[31]}},
                             instr[31:25], instr[11:7]};

            7'b1100011:
                immediate = {{19{instr[31]}}, instr[31],
                             instr[7], instr[30:25],
                             instr[11:8], 1'b0};

            default: immediate = 0;
        endcase
    end

    always @(*) begin
        alu_result = 0;
        write_data = 0;
        reg_write = 0;
        mem_write = 0;
        branch = 0;

        case (opcode)

            // R-Type Instructions
            7'b0110011: begin
                reg_write = 1;

                case ({funct7, funct3})
                    {7'b0000000, 3'b000}:
                        alu_result = A + B;

                    {7'b0100000, 3'b000}:
                        alu_result = A - B;

                    {7'b0000000, 3'b111}:
                        alu_result = A & B;

                    {7'b0000000, 3'b110}:
                        alu_result = A | B;

                    default: reg_write = 0;
                endcase

                write_data = alu_result;
            end

            // ADDI
            7'b0010011: begin
                if (funct3 == 3'b000) begin
                    alu_result = A + immediate;
                    write_data = alu_result;
                    reg_write = 1;
                end
            end

            // LOAD WORD
            7'b0000011: begin
                if (funct3 == 3'b010) begin
                    alu_result = A + immediate;
                    write_data = mem_rdata;
                    reg_write = 1;
                end
            end

            // STORE WORD
            7'b0100011: begin
                if (funct3 == 3'b010) begin
                    alu_result = A + immediate;
                    mem_write = 1;
                end
            end

            // BRANCH EQUAL
            7'b1100011: begin
                if (funct3 == 3'b000)
                    branch = (A == B);
            end

            default: begin
                // Unsupported instruction
            end

        endcase
    end

    assign next_pc = (opcode == 7'b1100011 && branch)
                   ? pc + immediate
                   : pc + 32'd4;

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 0;

            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 0;
        end
        else begin
            pc <= next_pc;

            if (reg_write && rd != 0)
                registers[rd] <= write_data;

            registers[0] <= 0;
        end
    end

endmodule
