`timescale 1ns/1ps

// instruction_macc.v — FIR filter using custom MACC instruction
// 4-tap low-pass: h=[1,2,2,1], samples=[10,20,30,40]
// Expected result: y = 1*10 + 2*20 + 2*30 + 1*40 = 150
//
// Register map:
//   x1=h[0]=1  x2=h[1]=2  x3=h[2]=2  x4=h[3]=1
//   x5=10      x6=20      x7=30      x8=40
//   x9=acc (y[n])
//
// Cycle count: 13 instructions (9 setup + 4 MACC)

module instruction (
    input  [31:0] pc,
    input         reset,
    output reg [31:0] instruction
);

    reg [31:0] memory [0:31];
    integer i;

    initial begin
        memory[0]  = 32'h00100093; // ADDI x1,x0,1    h[0]=1
        memory[1]  = 32'h00200113; // ADDI x2,x0,2    h[1]=2
        memory[2]  = 32'h00200193; // ADDI x3,x0,2    h[2]=2
        memory[3]  = 32'h00100213; // ADDI x4,x0,1    h[3]=1
        memory[4]  = 32'h00A00293; // ADDI x5,x0,10   x[n]=10
        memory[5]  = 32'h01400313; // ADDI x6,x0,20   x[n-1]=20
        memory[6]  = 32'h01E00393; // ADDI x7,x0,30   x[n-2]=30
        memory[7]  = 32'h02800413; // ADDI x8,x0,40   x[n-3]=40
        memory[8]  = 32'h00000493; // ADDI x9,x0,0    acc=0
        memory[9]  = 32'h0050848B; // MACC x9,x1,x5   x9=0+1*10=10
        memory[10] = 32'h0061048B; // MACC x9,x2,x6   x9=10+2*20=50
        memory[11] = 32'h0071848B; // MACC x9,x3,x7   x9=50+2*30=110
        memory[12] = 32'h0082048B; // MACC x9,x4,x8   x9=110+1*40=150
        for (i = 13; i < 32; i = i + 1)
            memory[i] = 32'h00000013; // NOP
    end

    always @(*) begin
        if (reset) instruction <= 0;
        else       instruction <= memory[pc>>2 & 5'd31];
    end

endmodule
