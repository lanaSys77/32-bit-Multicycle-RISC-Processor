module RegFile(
    input         clk,
    input         RegWrite,
    input  [3:0]  Rs,
    input  [3:0]  Rt,
    input  [3:0]  Rd,
    input  [31:0] WriteData,
    output [31:0] ReadData1,
    output [31:0] ReadData2
);
    reg [31:0] regs [0:15];
    integer i;
    initial for (i = 0; i < 16; i = i + 1) regs[i] = 32'd0;
    assign ReadData1 = regs[Rs];
    assign ReadData2 = regs[Rt];
    always @(posedge clk) begin
    if (RegWrite && Rd != 4'b1111) begin
        regs[Rd] <= WriteData;
    end
end
endmodule
