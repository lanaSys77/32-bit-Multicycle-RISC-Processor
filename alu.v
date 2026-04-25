module ALU(
    input  [31:0] A,
    input  [31:0] B,
    input  [2:0]  ALUOp,      // 000=OR, 001=ADD, 010=SUB, 011=CMP, 100=ORI
    output reg [31:0] Result,
    output        Zero,
    output        Negative
);
    always @(*) begin
        case (ALUOp)
            3'b000: Result = A | B;                   // OR, ORI
            3'b001: Result = A + B;                   // ADD, ADDI, address calc, CALL
            3'b010: Result = A - B;                   // SUB, BEQ, BZ, BGZ, BLZ, JR
            3'b011: begin                             // CMP
                if      (A == B)               Result = 32'd0;
                else if ($signed(A) < $signed(B)) Result = -32'd1;
                else                            Result = 32'd1;
            end
            default: Result = 32'd0;
        endcase
    end
    assign Zero     = (Result == 32'd0);
    assign Negative = Result[31];
endmodule