// FINALIZED AND CORRECTED DATAPATH MODULE
module Datapath(
    input         clk, reset,
    // --- Control Signals from Controller ---
    input         PCWrite, PCWriteEnable, IorD, MemRead, MemWrite, IRWrite,
    input         RegWrite, ExtSel, ALUOutWrite, AWrite, BWrite,
    input [1:0]   MemToReg,
    input [1:0]   ALUSrcA,
    input [2:0]   ALUSrcB,
    input [1:0]   PCSource,
    input         RegDst, // 0=Rt, 1=Rd
    input         IncReg, // For LDW/SDW
    input [2:0]   ALUOp,

    // --- Outputs to Controller and Memory ---
    output [5:0]  Op,
    output        Zero, Negative,
    output [31:0] PC,
    output [31:0] IR
);

    //================================================================
    // 1. Core Registers and Wires
    //================================================================
    reg  [31:0] PC_reg, IR_reg; 
    reg  [31:0] MDR, A, B, ALUOut_reg;
    wire [31:0] ALUOut_wire;
    wire [31:0] Instr;
    wire [31:0] MemData;

    assign PC = PC_reg;
    assign IR = IR_reg;

    //================================================================
    // 2. Program Counter (PC) Logic
    //================================================================
    wire [31:0] PC_Next;

    always @(posedge clk or posedge reset) begin
        if (reset) PC_reg <= 32'd0;
        else if (PCWriteEnable && PCWrite) PC_reg <= PC_Next;
    end

    // -- CORRECTED MUX: Now includes the path for Branch/Jump targets --
    assign PC_Next = (PCSource == 2'b00) ? ALUOut_wire : // For PC+1
                     (PCSource == 2'b01) ? A :           // For JR
                     (PCSource == 2'b10) ? ALUOut_reg :  // For Branch, J, CALL
                                           PC_reg;      // Default: Hold

    //================================================================
    // 3. Instruction Fetch and Decode
    //================================================================
    InstrMem imem(.Addr(PC_reg[9:0]), .Instr(Instr));
    
    always @(posedge clk) begin
        if (IRWrite) IR_reg <= Instr;
    end

    assign Op = IR_reg[31:26];
    wire [3:0] Rd_addr = IR_reg[25:22];
    wire [3:0] Rs_addr = IR_reg[21:18];
    wire [3:0] Rt_addr = IR_reg[17:14];

    //================================================================
    // 4. Immediate Generation
    //================================================================
    wire [31:0] ImmSign = {{18{IR_reg[13]}}, IR_reg[13:0]};
    wire [31:0] ImmZero = {{18{1'b0}},   IR_reg[13:0]};
    wire [31:0] Imm = ExtSel ? ImmZero : ImmSign;

    //================================================================
    // 5. Register File
    //================================================================
    wire [31:0] RD1_raw, RD2_raw;
    wire [31:0] WriteData;
    wire [3:0]  WriteRegAddr;

    assign WriteData = (MemToReg == 2'b01) ? MDR :
                     (MemToReg == 2'b10) ? PC_reg :
                                           ALUOut_reg;

    assign WriteRegAddr = RegDst ? Rd_addr : Rt_addr;

    RegFile rf(
        .clk(clk), .RegWrite(RegWrite && (WriteRegAddr != 4'b1111)),
        .Rs(Rs_addr), .Rt(Rt_addr), .Rd(WriteRegAddr),
        .WriteData(WriteData), .ReadData1(RD1_raw), .ReadData2(RD2_raw)
    );

    always @(posedge clk) begin
        if (AWrite) A <= (Rs_addr == 4'b1111) ? PC_reg : RD1_raw;
        if (BWrite) B <= (Rt_addr == 4'b1111) ? PC_reg : RD2_raw;
    end

    //================================================================
    // 6. ALU
    //================================================================
    wire [31:0] ALUIn1, ALUIn2;

    always @(posedge clk) begin
        if (ALUOutWrite) ALUOut_reg <= ALUOut_wire;
    end

    assign ALUIn1 = (ALUSrcA == 2'b00) ? PC_reg : 
                    (ALUSrcA == 2'b01) ? A :
                    (ALUSrcA == 2'b10) ? ALUOut_reg:
                                         A;

    assign ALUIn2 = (ALUSrcB == 3'b000) ? B : 
                    (ALUSrcB == 3'b001) ? Imm :
                    (ALUSrcB == 3'b010) ? 32'd1 :
                    (ALUSrcB == 3'b101) ? 32'd0 :
                                          B;

    ALU alu(.A(ALUIn1), .B(ALUIn2), .ALUOp(ALUOp), .Result(ALUOut_wire), .Zero(Zero), .Negative(Negative));

    //================================================================
    // 7. Data Memory Interface
    //================================================================
    wire [31:0] Addr_to_mem = IorD ? ALUOut_reg : PC_reg;

    DataMem dmem(
        .clk(clk), .MemRead(MemRead), .MemWrite(MemWrite),
        .Addr(Addr_to_mem[9:0]), .WriteData(B),
        .ReadData(MemData)
    );

    always @(posedge clk) begin
        if(MemRead && IorD) MDR <= MemData;
    end

endmodule
