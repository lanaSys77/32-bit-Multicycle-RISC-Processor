module InstrMem(
    input [31:0] Addr,
    output [31:0] Instr
);
    // 1K-word memory for 32-bit instructions
    reg [31:0] mem [0:1023];

    // Initialize memory from a hex file at the start of simulation
    initial $readmemh("program.dat", mem);

    // Asynchronously read from the memory.
    // The address is word-addressable, so we use Addr[9:0] to
    // access the 1024 words (2^10 = 1024).
    assign Instr = mem[Addr[9:0]];

endmodule
