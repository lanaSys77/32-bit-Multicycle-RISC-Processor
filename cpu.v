// FINALIZED AND CORRECTED top-level CPU module
module cpu(
    input         clk,
    input         reset,
    // --- Outputs for simulation and verification ---
    output [31:0] PC_out,
    output [31:0] Instr_out,
    output        RegWrite_out
);

    // --- Wires connecting Control and Datapath ---
    wire        PCWrite, PCWriteEnable, IorD, MemRead, MemWrite, IRWrite;
    wire        RegWrite, RegDst, ExtSel, IncReg, ALUOutWrite, AWrite, BWrite; // ADDED AWrite, BWrite
    wire [1:0]  MemToReg, ALUSrcA, PCSource;
    wire [2:0]  ALUSrcB, ALUOp;
    wire [5:0]  Op;
    wire        Zero, Negative;

    // Instantiate the redesigned datapath
    Datapath dp (
        .clk(clk), .reset(reset),
        .PCWrite(PCWrite), .PCWriteEnable(PCWriteEnable), .IorD(IorD), 
        .MemRead(MemRead), .MemWrite(MemWrite), .IRWrite(IRWrite), 
        .MemToReg(MemToReg), .RegWrite(RegWrite), .RegDst(RegDst), 
        .ExtSel(ExtSel), .IncReg(IncReg), .ALUOutWrite(ALUOutWrite), 
        .AWrite(AWrite), .BWrite(BWrite), // Connect new signals
        .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), .PCSource(PCSource),
        .ALUOp(ALUOp),
        .Op(Op), .Zero(Zero), .Negative(Negative),
        .PC(PC_out), .IR(Instr_out)
    );

    // Instantiate the redesigned control unit
    Control c (
        .clk(clk), .reset(reset),
        .Zero(Zero), .Negative(Negative), .Op(Op),
        .PCWrite(PCWrite), .PCWriteEnable(PCWriteEnable), .IorD(IorD), 
        .MemRead(MemRead), .MemWrite(MemWrite), .IRWrite(IRWrite), 
        .MemToReg(MemToReg), .RegWrite(RegWrite), .RegDst(RegDst), 
        .ExtSel(ExtSel), .IncReg(IncReg), .ALUOutWrite(ALUOutWrite),
        .AWrite(AWrite), .BWrite(BWrite), // Connect new signals
        .ALUSrcA(ALUSrcA), .ALUSrcB(ALUSrcB), .PCSource(PCSource),
        .ALUOp(ALUOp)
    );
    
    assign RegWrite_out = RegWrite;

endmodule
