// Advanced Testbench for the RISC CPU
`timescale 1ns / 1ps

module cpu_tb;

    // Inputs to the CPU
    reg clk;
    reg reset;

    // Outputs from the CPU
    wire [31:0] PC_out;
    wire [31:0] Instr_out;
    wire        RegWrite_out;

    // One-cycle delay register for printing
    reg print_now;
    reg [31:0] pc_at_write, instr_at_write;

    // Instantiate the Unit Under Test (UUT)
    cpu uut (
        .clk(clk),
        .reset(reset),
        .PC_out(PC_out),
        .Instr_out(Instr_out),
        .RegWrite_out(RegWrite_out)
    );

    // 1. Clock Generation
    always begin
        #5 clk = ~clk;
    end

    // 2. Stimulus and Reset
    initial begin
        clk = 0;
        reset = 1;
        print_now = 0;
        #20;
        reset = 0;
        
        // -- UPDATED: Further extended simulation time for the full loop --
        #5000; 
        
        $stop;
    end
    
    // 3. Monitor and Print Register Contents
    always @(posedge clk) begin
        // On the cycle a write happens, set a flag and latch the PC/Instruction.
        if (RegWrite_out) begin
            print_now <= 1;
            pc_at_write <= PC_out;
            instr_at_write <= Instr_out;
        end
        // On the cycle AFTER the write, do the printing.
        else if (print_now) begin
            $display("-----------------------------------------------------");
            $display("Register Write Completed at Time %0t", $time);
            $display("Instruction that caused write:");
            $display("  PC: %h, Instruction: %h", pc_at_write, instr_at_write);
            $display("Non-Zero Register File Contents:");
            
            for (integer i = 0; i < 16; i = i + 1) begin
                if (uut.dp.rf.regs[i] !== 32'd0) begin
                    $display("  R%0d: %h", i, uut.dp.rf.regs[i]);
                end
            end
            $display("-----------------------------------------------------");
            print_now <= 0; // Reset the flag
        end
    end

endmodule
