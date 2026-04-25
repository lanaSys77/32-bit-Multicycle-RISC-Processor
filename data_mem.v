// CORRECTED Data Memory (RAM)
module DataMem(
    input         clk,
    input         MemRead,
    input         MemWrite,
    input  [31:0] Addr,
    input  [31:0] WriteData,
    output reg [31:0] ReadData
);
    reg [31:0] mem [0:1023];

    initial begin
        // All words default to zero
        integer i;
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 32'd0;
            
        // The following line is commented out to prevent the "Could not open file" error.
        // If you need to test with pre-loaded data, create a "data.hex" file
        // and uncomment this line.
        // $readmemh("data.hex", mem);
    end

    always @(posedge clk) begin
        if (MemWrite)
            mem[Addr[9:0]] <= WriteData;
    end

    always @(*) begin
        if (MemRead)
            ReadData = mem[Addr[9:0]];
        else
            ReadData = 32'bz;
    end
endmodule
