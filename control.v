// FINALIZED AND CORRECTED CONTROL MODULE
module Control(
    input         clk, reset,
    input         Zero, Negative,
    input  [5:0]  Op,

    // Control Signals to Datapath
    output reg    PCWrite, PCWriteEnable, IorD, MemRead, MemWrite, IRWrite,
    output reg    RegWrite, RegDst, ExtSel, IncReg, ALUOutWrite, AWrite, BWrite,
    output reg [1:0]   MemToReg, ALUSrcA, PCSource,
    output reg [2:0]   ALUSrcB, ALUOp
);

    //================================================================
    // 1. State Definitions
    //================================================================
    localparam S_FETCH        = 5'd0;
    localparam S_DECODE       = 5'd1;
    localparam S_EXEC_MEM_ADR = 5'd2;
    localparam S_EXEC_RTYPE   = 5'd3;
    localparam S_EXEC_ITYPE   = 5'd4;
    localparam S_BRANCH_EVAL  = 5'd5; // State to perform the branch comparison
    localparam S_EXEC_BRANCH  = 5'd6; // This state now makes the decision
    localparam S_EXEC_JUMP    = 5'd7;
    localparam S_MEM_READ     = 5'd8;
    localparam S_MEM_WRITE    = 5'd9;
    localparam S_WB_ALU       = 5'd10;
    localparam S_WB_MEM       = 5'd11;
    localparam S_CALL_WB      = 5'd12;
    localparam S_LDW_READ2    = 5'd13;
    localparam S_LDW_WB2      = 5'd14;
    localparam S_SDW_WRITE2   = 5'd15;

    reg [4:0] state, next_state;

    //================================================================
    // 2. State Register (Sequential Logic)
    //================================================================
    always @(posedge clk or posedge reset) begin
        if(reset) state <= S_FETCH;
        else      state <= next_state;
    end

    //================================================================
    // 3. Next-State and Output Logic (Combinational Logic)
    //================================================================
    always @(*) begin
        // --- Set default values for all control signals ---
        PCWrite=0; PCWriteEnable=1; IorD=0; MemRead=0; MemWrite=0; IRWrite=0;
        RegWrite=0; RegDst=0; ExtSel=0; IncReg=0; ALUOutWrite=0; AWrite=0; BWrite=0;
        MemToReg=2'b00; ALUSrcA=2'b00; PCSource=2'b00;
        ALUSrcB=3'b000; ALUOp=3'b000;
        next_state = S_FETCH;

        case(state)
            S_FETCH: begin
                MemRead = 1; IorD = 0; IRWrite = 1;
                next_state = S_DECODE;
            end

            S_DECODE: begin
                AWrite = 1; BWrite = 1;
                ALUOutWrite = 1;
                ALUSrcA = 2'b00; ALUSrcB = 3'b001; ExtSel = 0; ALUOp = 3'b001;

                case(Op)
                    6'h00, 6'h01, 6'h02, 6'h03: next_state = S_EXEC_RTYPE;
                    6'h04, 6'h05: next_state = S_EXEC_ITYPE;
                    6'h06, 6'h08: next_state = S_EXEC_MEM_ADR;
                    6'h07, 6'h09: next_state = S_EXEC_MEM_ADR;
                    6'h0A, 6'h0B, 6'h0C: next_state = S_BRANCH_EVAL;
                    6'h0D, 6'h0E: next_state = S_EXEC_JUMP;
                    6'h0F: next_state = S_CALL_WB;
                    default: next_state = S_FETCH;
                endcase
            end

            S_BRANCH_EVAL: begin
                ALUSrcA = 2'b01; ALUSrcB = 3'b101; ALUOp = 3'b010;
                next_state = S_EXEC_BRANCH;
            end

            S_EXEC_BRANCH: begin
                if ((Op==6'h0A&&Zero) || (Op==6'h0B&&!Zero&&!Negative) || (Op==6'h0C&&Negative)) begin
                    PCSource = 2'b10;
                end else begin
                    ALUOutWrite = 1;
                    ALUSrcA = 2'b00; ALUSrcB = 3'b010; ALUOp = 3'b001;
                    PCSource = 2'b00;
                end
                PCWrite = 1;
                next_state = S_FETCH;
            end
            
            S_EXEC_MEM_ADR: begin
                ALUOutWrite = 1; ALUSrcA = 2'b01; ALUSrcB = 3'b001; ALUOp = 3'b001;
                if (Op == 6'h06 || Op == 6'h08) begin next_state = S_MEM_READ; end
                else begin next_state = S_MEM_WRITE; end
            end

            S_EXEC_RTYPE: begin
                ALUOutWrite = 1; ALUSrcA = 2'b01; ALUSrcB = 3'b000;
                if (Op == 6'h00) ALUOp = 3'b000; else if (Op == 6'h01) ALUOp = 3'b001;
                else if (Op == 6'h02) ALUOp = 3'b010; else if (Op == 6'h03) ALUOp = 3'b011;
                next_state = S_WB_ALU;
            end

            S_EXEC_ITYPE: begin
                ALUOutWrite = 1; ALUSrcA = 2'b01; ALUSrcB = 3'b001;
                if (Op == 6'h04) begin ALUOp = 3'b000; ExtSel = 1; end
                else begin ALUOp = 3'b001; ExtSel = 0; end
                next_state = S_WB_ALU;
            end

            S_EXEC_JUMP: begin
                PCWrite = 1;
                if (Op == 6'h0E) begin PCSource = 2'b10; end
                else begin PCSource = 2'b01; end
                next_state = S_FETCH;
            end

            S_MEM_READ: begin
                IorD = 1; MemRead = 1;
                if (Op == 6'h08) begin PCWriteEnable = 0; end
                next_state = S_WB_MEM;
            end

            S_MEM_WRITE: begin
                IorD = 1; MemWrite = 1;
                if (Op == 6'h09) begin PCWriteEnable = 0; next_state = S_SDW_WRITE2; end
                else begin next_state = S_WB_ALU; end
            end

            S_WB_MEM: begin
                RegWrite = 1; RegDst = 1; MemToReg = 2'b01;
                if (Op == 6'h08) begin PCWriteEnable = 0; next_state = S_LDW_READ2; end
                else begin next_state = S_WB_ALU; end
            end

            S_WB_ALU: begin
                // -- CORRECTED STATE --
                // ALUOutWrite is now 0 to prevent clobbering the result.
                ALUOutWrite = 0; 
                
                if (Op < 6'h06) begin RegWrite = 1; RegDst = 1; MemToReg = 2'b00; end
                
                // Use ALU to calculate PC+1
                ALUSrcA = 2'b00; ALUSrcB = 3'b010; ALUOp = 3'b001;
                PCWrite = 1; PCSource = 2'b00;
                next_state = S_FETCH;
            end

            S_CALL_WB: begin
                RegWrite = 1; RegDst = 0; MemToReg = 2'b10;
                PCWrite = 1; PCSource = 2'b10;
                next_state = S_FETCH;
            end

            S_LDW_READ2: begin
                PCWriteEnable = 0; IorD = 1; MemRead = 1; ALUOutWrite = 1;
                ALUSrcA = 2'b10; ALUSrcB = 3'b010; ALUOp = 3'b001;
                next_state = S_LDW_WB2;
            end
            
            S_LDW_WB2: begin
                // -- CORRECTED STATE --
                ALUOutWrite = 0; // Protect result during PC+1 calculation
                RegWrite = 1; RegDst = 1; IncReg = 1; MemToReg = 2'b01;
                
                ALUSrcA = 2'b00; ALUSrcB = 3'b010; ALUOp = 3'b001;
                PCWrite = 1; PCSource = 2'b00;
                next_state = S_FETCH;
            end

            S_SDW_WRITE2: begin
                PCWriteEnable = 0; IorD = 1; MemWrite = 1; ALUOutWrite = 1;
                ALUSrcA = 2'b10; ALUSrcB = 3'b010; ALUOp = 3'b001;
                next_state = S_WB_ALU;
            end

        endcase
    end
endmodule
