`include "verilog.v"
`timescale 1ns / 1ps

module MIPS_Testbench();

    reg clk, reset;
    reg [7:0] ALUop;
    reg mem_write, mem_read, wren;
    reg alu_src;             // New control signal for ALU operand selection
    reg [31:0] wdata;
    reg [4:0] waddr, raddr1, raddr2;
    wire [31:0] ALUResult, alu_operand_b;
    wire Zero;
    wire [31:0] rdata, reg_data1, reg_data2, instr, PC;

    // Instantiate ALU
    ALU alu_inst(
        .A(reg_data1),
        .B(alu_operand_b),
        .ALUop(ALUop),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    // Instantiate 2-to-1 Multiplexer for ALU operand
    mux2to1 alu_operand_mux (
        .in0(reg_data2),
        .in1({{16{instr[15]}}, instr[15:0]}), // Sign-extended immediate
        .sel(alu_src),
        .out(alu_operand_b)
    );

    // Instantiate PC module
    pc pc_inst(
        .clk(clk),
        .reset(reset),
        .branch_taken(1'b0),
        .jump_taken(1'b0),
        .branch_address(32'b0),
        .jump_address(32'b0),
        .pc_incr(32'd4),
        .pc_out(PC)
    );

    // Instantiate Instruction Memory
    instruction_memory inst_mem_inst(
        .addr(PC),
        .instr(instr)
    );

    // Instantiate Register File
    regfile regfile_inst(
        .clk(clk),
        .reset(reset),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .waddr(waddr),
        .wdata(wdata),
        .wren(wren),
        .rdata1(reg_data1),
        .rdata2(reg_data2)
    );

    // Instantiate Data Memory
    datamem datamem_inst(
        .addr(ALUResult),
        .wdata(reg_data2),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .byte_en(1'b1),
        .halfword_en(1'b0),
        .word_en(1'b1),
        .clk(clk),
        .reset(reset),
        .rdata(rdata)
    );

    // Clock toggling
    always #5 clk = ~clk;

    // Testbench logic
    initial begin
        clk = 0; reset = 1; wren = 0; alu_src = 0;
        mem_write = 0; mem_read = 0; 
        #10 reset = 0;

        $display("Starting MIPS Testbench :");

        // Test Arithmetic Operations
        $display("Test 1: Arithmetic Operations");

        wdata = 32'd10; waddr = 1; wren = 1; #10; // Write 10 to R1
        wdata = 32'd20; waddr = 2; wren = 1; #10; // Write 20 to R2
        wren = 0; 

        raddr1 = 1; raddr2 = 2; alu_src = 0;
        ALUop = 3'b000; #10; // ADD
        $display("ADD Result (10 + 20): %d", ALUResult);

        ALUop = 3'b001; #10; // SUB
        $display("SUB Result (10 - 20): %d", ALUResult);

        // Test Logical Operations
        $display("Test 2: Logical Operations");

        ALUop = 3'b010; #10; // AND
        $display("AND Result: %d", ALUResult);

        ALUop = 3'b011; #10; // OR
        $display("OR Result: %d", ALUResult);

        ALUop = 3'b101; #10; // XOR
        $display("XOR Result: %d", ALUResult);

        // Test Load/Store Operations
        $display("Test 3: Load/Store Operations");

        mem_write = 1; mem_read = 0; #10;
        $display("Stored Value at Address %d: %d", ALUResult, reg_data2);

        mem_write = 0; mem_read = 1; #10;
        $display("Loaded Value from Address %d: %d", ALUResult, rdata);

        // Test Branching
        $display("Test 4: Branching Instruction");

        ALUop = 3'b001;
        raddr1 = 1; raddr2 = 2; #10; 
        if (Zero)
            $display("BEQ: Branch Taken (R1 == R2)");
        else
            $display("BEQ: Branch Not Taken (R1 != R2)");

        $display("Testbench completed.");
        $stop;
    end
endmodule
