`timescale 1ns/1ps

module immediate_gen #(parameter N = 32)(
    input [N-1:0] instruction,
    output reg [N-1:0] out
);
    
  always @ (*) 
  begin
    case (instruction[6:0])
      7'b0110011: // R-type
        out <= 32'b0;

      7'b0010011, 7'b0000011: // I-type (arithmetic, load)
        out <= {20'b0, instruction[31:20]};
        
      7'b0100011: // S-type (store)
        out <= {20'b0, instruction[31:25], instruction[11:7]};
        
      7'b1100011: // SB-type (branch)
        out <= {19'b0, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        
      7'b0110111: // U-type (lui)
        out <= {instruction[31:12], 12'b0};

      7'b1101111: // UJ-type (jal)
        out <= {11'b0, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
        
      default:
        out <= 32'bX; // Default case
    endcase
  end

endmodule