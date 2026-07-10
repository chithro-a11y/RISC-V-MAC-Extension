`timescale 1ns/1ps

// instruction_baseline.v — FIR filter using MUL+ADD (no custom instruction)
// Same 4-tap filter, same samples — for cycle count comparison
// Expected result: y = 150
//
// Register map:
//   x1=h[0]=1  x2=h[1]=2  x3=h[2]=2  x4=h[3]=1
//   x5=10      x6=20      x7=30      x8=40
//   x9=acc     x10=temp product
//
// Cycle count: 17 instructions (9 setup + 8 MUL+ADD pairs)

module instruction (
    input  [31:0] pc,
    input         reset,
    output reg [31:0] instruction
);

    reg [31:0] memory [0:31];
    integer i;

    initial begin
        memory[0]  = 32'h00100093; // ADDI x1,x0,1
        memory[1]  = 32'h00200113; // ADDI x2,x0,2
        memory[2]  = 32'h00200193; // ADDI x3,x0,2
        memory[3]  = 32'h00100213; // ADDI x4,x0,1
        memory[4]  = 32'h00A00293; // ADDI x5,x0,10
        memory[5]  = 32'h01400313; // ADDI x6,x0,20
        memory[6]  = 32'h01E00393; // ADDI x7,x0,30
        memory[7]  = 32'h02800413; // ADDI x8,x0,40
        memory[8]  = 32'h00000493; // ADDI x9,x0,0   acc=0
        memory[9]  = 32'h02508533; // MUL  x10,x1,x5  x10=1*10=10
        memory[10] = 32'h00A484B3; // ADD  x9,x9,x10  x9=0+10=10
        memory[11] = 32'h02610533; // MUL  x10,x2,x6  x10=2*20=40
        memory[12] = 32'h00A484B3; // ADD  x9,x9,x10  x9=10+40=50
        memory[13] = 32'h02718533; // MUL  x10,x3,x7  x10=2*30=60
        memory[14] = 32'h00A484B3; // ADD  x9,x9,x10  x9=50+60=110
        memory[15] = 32'h02820533; // MUL  x10,x4,x8  x10=1*40=40
        memory[16] = 32'h00A484B3; // ADD  x9,x9,x10  x9=110+40=150
        for (i = 17; i < 32; i = i + 1)
            memory[i] = 32'h00000013; // NOP
    end

    always @(*) begin
        if (reset) instruction <= 0;
        else       instruction <= memory[pc>>2 & 5'd31];
    end

endmodule
