
`timescale 1ns/1ps

module tb_rv32i_core;

    reg clk = 0;
    reg reset = 1;

    reg [31:0] instr;
    reg [31:0] mem_rdata;

    wire [31:0] pc;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire mem_we;

    reg [31:0] instruction_memory [0:15];
    reg [31:0] data_memory [0:15];

    integer i;

    rv32i_core uut (
        .clk(clk),
        .reset(reset),
        .instr(instr),
        .mem_rdata(mem_rdata),
        .pc(pc),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_we(mem_we)
    );

    always #5 clk = ~clk;

    always @(*) begin
        instr = instruction_memory[pc[5:2]];
        mem_rdata = data_memory[mem_addr[5:2]];
    end

    always @(posedge clk) begin
        if (!reset && mem_we)
            data_memory[mem_addr[5:2]] <= mem_wdata;
    end

    initial begin

        for (i = 0; i < 16; i = i + 1) begin
            instruction_memory[i] = 32'h00000013;
            data_memory[i] = 0;
        end

        instruction_memory[0] = 32'h00A00093;
        instruction_memory[1] = 32'h00700113;
        instruction_memory[2] = 32'h002081B3;
        instruction_memory[3] = 32'h40208233;
        instruction_memory[4] = 32'h00302023;
        instruction_memory[5] = 32'h00002283;

        #12 reset = 0;

        repeat (8) @(posedge clk);
        #1;

        $display("Register x1 = %d", uut.registers[1]);
        $display("Register x2 = %d", uut.registers[2]);
        $display("Register x3 = %d", uut.registers[3]);
        $display("Register x4 = %d", uut.registers[4]);
        $display("Register x5 = %d", uut.registers[5]);

        if (uut.registers[1] == 10 &&
            uut.registers[2] == 7 &&
            uut.registers[3] == 17 &&
            uut.registers[4] == 3 &&
            uut.registers[5] == 17)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");

        $finish;
    end

endmodule
