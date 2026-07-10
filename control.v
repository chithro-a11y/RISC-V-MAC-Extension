`timescale 1ns/1ps

module control(
    input [6:0] opcode,
    output reg memtoreg, memread, memwrite, branch, alusrc, regwrite,
    output reg [1:0] alu_op,
    output reg mac_en          // NEW: asserted for MACC instruction (custom-0)
);

always @(*) begin
    // Safe default for mac_en — prevents latches
    mac_en = 0;

    case(opcode)
        7'b0000011: begin // LW
            memtoreg = 1;
            memread = 1;
            memwrite = 0;
            branch = 0;
            alusrc = 1;
            regwrite = 1;
            alu_op = 2'b00;
        end
        7'b0100011: begin // SW
            memtoreg = 0; 
            memread = 0;
            memwrite = 1;
            branch = 0;
            alusrc = 1;
            regwrite = 0;
            alu_op = 2'b00;
        end
        7'b1100011: begin // BEQ
            memtoreg = 0; 
            memread = 0;
            memwrite = 0;
            branch = 1;
            alusrc = 0;
            regwrite = 0;
            alu_op = 2'b01;
        end
        7'b0010011: begin // I-type
            memtoreg = 0;
            memread = 0;
            memwrite = 0;
            branch = 0;
            alusrc = 1;
            regwrite = 1;
            alu_op = 2'b00;
        end
        7'b0001011: begin // MACC (custom-0)
            // Bypass ALU entirely — mac_unit handles the computation.
            // regwrite=1 so the result gets written back to rd.
            // memtoreg=0, mac_en=1 → datapath mux selects mac_result.
            memtoreg = 0;
            memread  = 0;
            memwrite = 0;
            branch   = 0;
            alusrc   = 0;
            regwrite = 1;
            alu_op   = 2'b00;  // ALU result ignored; mac_unit drives write_data
            mac_en   = 1;
        end
        default: begin // R-type
            memtoreg = 0; 
            memread = 0;
            memwrite = 0;
            branch = 0;
            alusrc = 0;
            regwrite = 1;
            alu_op = 2'b10;
        end

    endcase    
end


endmodule