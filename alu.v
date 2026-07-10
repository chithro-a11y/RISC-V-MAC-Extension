`timescale 1ns / 1ps
`define n 32

module alu #(parameter N=`n)(
    input [N-1:0] I1, I2,
    input [3:0] alu_ctr,
    output reg [N-1:0] out,
    output reg N_flag, Z_flag, C_flag, V_flag
);
    reg [N-1:0] x, y, t;
    always@(*)
    begin
        N_flag = 0; Z_flag = 0; C_flag = 0; V_flag = 0;
        x = 0; y = 0; t = 0;
        case(alu_ctr)
            4'b0000: out = I1 & I2; // AND
            4'b0001: out = I1 | I2; // OR
            4'b0010: {C_flag, out} = I1 + I2; // ADD
            4'b0011: {C_flag, out} = I1 - I2; // SUB
            4'b0100: out = (I1 < I2) ? 1 : 0; // COMP
            4'b0101: out = I1 << I2; // SL
            4'b0110: out = I1 >> I2; // SR
            4'b0111: out = I1 ^ I2; // XOR
            4'b1000: out = ~(I1 | I2); // NOR
            4'b1001: out = ~(I1 & I2); // NAND
            4'b1011: out = I1 * I2; // MUL (signed truncated to 32b)
            4'b1010: begin // GCD
                     x = I1;
                     y = I2;
                    while(y != 0)
                     begin
                        t = y;
                        y = x % y;
                        x = t;
                     end
                     out = x;
                     end

            default: out = 0; 
        endcase
        
        N_flag = out[N-1];
        Z_flag = (out == 0) ? 1 : 0;
        V_flag = (I1[N-1] == I2[N-1] && out[N-1] != I1[N-1]);
    end
    
endmodule