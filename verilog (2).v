module alu(
    input [31:0] A, B, 
    input [2:0] ALUop, 
    output reg [31:0] ALUResult,
    output Zero
);
    always @(*) begin
        case (ALUop)
            3'b000: ALUResult = A + B; 
            3'b001: ALUResult = A - B; 
            3'b010: ALUResult = A & B;
            3'b011: ALUResult = A | B;
            3'b100: ALUResult = ~A;
            3'b101: ALUResult = A ^ B;
            3'b110: ALUResult = {31'b0, A[31]}; // Extract MSB
            3'b111: ALUResult = (A < B) ? 32'b1 : 32'b0; // slt
            default: ALUResult = 32'b0;
        endcase
    end
    assign Zero = (ALUResult == 32'b0); // Zero flag
endmodule

module pc (
    input clk,
    input reset, 
    input branch_taken, 
    input jump_taken, 
    input [31:0] branch_address,
    input [31:0] jump_address,
    input [31:0] pc_incr,
    output reg [31:0] pc_out
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_out <= 32'b0;
        end else begin
            if (branch_taken) begin
                pc_out <= branch_address;
            end else if (jump_taken) begin
                pc_out <= jump_address;
            end else begin
                pc_out <= pc_out + pc_incr;
            end
        end
    end
endmodule

module instruction_memory(
    input [31:0] addr,
    output reg [31:0] instr
);
    reg [31:0] mem [0:31]; // 128 bytes (32 words)
    initial begin
        mem[0]  = 32'h00000000; // NOP
        mem[1]  = 32'h20020005; // ADDI $2, $0, 5
        mem[2]  = 32'h20030003; // ADDI $3, $0, 3
        mem[3]  = 32'h00430820; // ADD $1, $2, $3
        mem[4]  = 32'h10430002; // BEQ $2, $3, offset 2
        mem[5]  = 32'h8C220000; // LW $2, 0($1)
        mem[6]  = 32'hAC230004; // SW $3, 4($1)
        mem[7]  = 32'h00000000; // NOP
        for (integer i = 8; i < 32; i = i + 1) begin
            mem[i] = 32'b0;
        end
    end
    always @(*) begin
        instr <= mem[addr >> 2];
    end
endmodule

module regfile(
    input [4:0] raddr1, raddr2, waddr,
    input [31:0] wdata,
    input wren,
    input clk, reset,
    output reg [31:0] rdata1, rdata2
);
    reg [31:0] regs [31:0];
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (wren && waddr != 0) begin
            regs[waddr] <= wdata;
        end
    end

    always @(*) begin
        rdata1 <= regs[raddr1];
        rdata2 <= regs[raddr2];
    end
endmodule

module datamem (
    input [31:0] addr,
    input [31:0] wdata,
    input mem_read,
    input mem_write,
    input byte_en,
    input halfword_en,
    input word_en,
    input clk,
    input reset,
    output reg [31:0] rdata
);
    reg [7:0] mem [0:511]; // 512 bytes
    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 512; i = i + 1) begin
                mem[i] <= 8'b0;
            end
        end else if (mem_write) begin
            if (word_en) begin
                {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} <= wdata;
            end else if (halfword_en) begin
                {mem[addr+1], mem[addr]} <= wdata[15:0];
            end else if (byte_en) begin
                mem[addr] <= wdata[7:0];
            end
        end
    end

    always @(*) begin
        if (mem_read) begin
            if (word_en) begin
                rdata = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
            end else if (halfword_en) begin
                rdata = {16'b0, mem[addr+1], mem[addr]};
            end else if (byte_en) begin
                rdata = {24'b0, mem[addr]};
            end else begin
                rdata = 32'b0;
            end
        end else begin
            rdata = 32'b0;
        end
    end
endmodule

// 2-to-1 Multiplexer
module mux2to1(
  input [31:0] in0, in1, // Two 32-bit inputs
  input sel,             // Selection signal (1 bit)
  output [31:0] out      // 32-bit output
);
    assign out = sel ? in1 : in0; // If sel=1, out=in1; otherwise, out=in0
endmodule

module datapath (
    input clk,
    input reset,
    input [2:0] alu_op,
    input branch_taken,
    input jump_taken,
    input mem_read,
    input mem_write,
    input byte_en,
    input halfword_en,
    input word_en,
    output [31:0] instr_out,
    output [31:0] alu_result,
    output zero_flag
);
    wire [31:0] pc_incr = 32'd4; 
    wire [31:0] pc_current, instr, reg_data1, reg_data2, mem_data, alu_operand_b;
    wire [31:0] branch_address, jump_address;

    // Program Counter
    pc pc_inst (
        .clk(clk),
        .reset(reset),
        .branch_taken(branch_taken),
        .jump_taken(jump_taken),
        .branch_address(branch_address),
        .jump_address(jump_address),
        .pc_incr(pc_incr),
        .pc_out(pc_current)
    );

    // Instruction Memory
    instruction_memory instr_mem_inst (
        .addr(pc_current),
        .instr(instr)
    );

    // Register File
    regfile regfile_inst (
        .raddr1(instr[25:21]),
        .raddr2(instr[20:16]),
        .waddr(instr[15:11]),
        .wdata(mem_data),
        .wren(mem_read | mem_write),
        .clk(clk),
        .reset(reset),
        .rdata1(reg_data1),
        .rdata2(reg_data2)
    );

    // ALU Operand Multiplexer
   mux2to1 alu_operand_mux (
    .in0(reg_data2),
    .in1({{16{instr[15]}}, instr[15:0]}), // Sign-extended immediate
    .sel(instr[31]), // Use instr[31] to select the source
    .out(alu_operand_b)
);
    // ALU
    alu alu_inst (
        .A(reg_data1),
        .B(alu_operand_b),
        .ALUop(alu_op),
        .ALUResult(alu_result),
        .Zero(zero_flag)
    );

    // Data Memory
    datamem datamem_inst (
        .addr(alu_result),
        .wdata(reg_data2),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .byte_en(byte_en),
        .halfword_en(halfword_en),
        .word_en(word_en),
        .clk(clk),
        .reset(reset),
        .rdata(mem_data)
    );

    // Calculate Branch and Jump Addresses
    assign branch_address = pc_current + ({{16{instr[15]}}, instr[15:0]} << 2);
    assign jump_address = {pc_current[31:28], instr[25:0], 2'b00};

    assign instr_out = instr;
endmodule
