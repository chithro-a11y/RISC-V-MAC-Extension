module alu_control (
    input [1:0] alu_op,
    input [4:0] func,        // {instr[25], instr[30], instr[14:12]} — 5 bits
    output reg [3:0] alu_cntrl
);

// func[4]   = instr[25]  — M-extension bit (1 for MUL/DIV family)
// func[3]   = instr[30]  — funct7[5] (1 for SUB/SRA)
// func[2:0] = instr[14:12] — funct3

always @(*) begin
    alu_cntrl = 4'd0;
    case(alu_op)
        2'b00: alu_cntrl = 4'b0010; // Load/Store — ADD
        2'b01: alu_cntrl = 4'b0011; // BEQ — SUB
        2'b10: begin
            case(func)
                5'b0_0_000: alu_cntrl = 4'b0010; // ADD  (funct7=0000000, funct3=000)
                5'b0_1_000: alu_cntrl = 4'b0011; // SUB  (funct7=0100000, funct3=000)
                5'b1_0_000: alu_cntrl = 4'b1011; // MUL  (funct7=0000001, funct3=000)
                5'b0_0_111: alu_cntrl = 4'b0000; // AND  (funct7=0000000, funct3=111)
                5'b0_0_110: alu_cntrl = 4'b0001; // OR   (funct7=0000000, funct3=110)
                5'b0_0_100: alu_cntrl = 4'b0111; // XOR  (funct7=0000000, funct3=100)
                5'b0_0_010: alu_cntrl = 4'b0100; // SLT  (funct7=0000000, funct3=010)
                5'b0_1_100: alu_cntrl = 4'b1010; // GCD  (funct7=0100000, funct3=100)
                default:    alu_cntrl = 4'b0000;
            endcase
        end
        default: alu_cntrl = 4'b1111;
    endcase
end

endmodule
