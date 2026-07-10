// mac_unit.v
// Multiply-Accumulate functional unit for custom RISC-V ISA extension
//
// Operation: result = accumulator + (rs1_data * rs2_data)
// The accumulator input comes from the current value of rd (read before write).
// All arithmetic is signed 32-bit.
//
// Synthesizable RTL — no non-synthesizable constructs.

`timescale 1ns / 1ps

module mac_unit (
    input  wire        clk,
    input  wire        rst_n,       // active-low synchronous reset
    input  wire        mac_en,      // asserted by decoder when opcode = MACC
    input  wire [31:0] rs1_data,    // multiplicand
    input  wire [31:0] rs2_data,    // multiplier
    input  wire [31:0] acc_in,      // accumulator input = current rd value
    output reg  [31:0] mac_result,  // rd = acc_in + (rs1 * rs2), truncated to 32b
    output reg         mac_valid    // high when mac_en is asserted
);

    // -----------------------------------------------------------------------
    // Internal signals
    // -----------------------------------------------------------------------
    wire signed [31:0] op_a;
    wire signed [31:0] op_b;
    wire signed [63:0] product;     // full 64-bit product before truncation
    wire signed [31:0] acc_signed;
    wire signed [31:0] sum;

    assign op_a       = $signed(rs1_data);
    assign op_b       = $signed(rs2_data);
    assign product    = op_a * op_b;             // 32x32 signed multiply -> 64b
    assign acc_signed = $signed(acc_in);
    assign sum        = acc_signed + product[31:0]; // truncate product to 32b then add

    // -----------------------------------------------------------------------
    // Combinational output — result available same cycle as mac_en
    // This matches the single-cycle core timing where ALU results are
    // combinational and registered only at the regfile on posedge clk.
    // mac_valid is a simple pass-through of mac_en for downstream use.
    // -----------------------------------------------------------------------
    always @(*) begin
        if (!rst_n) begin
            mac_result = 32'b0;
            mac_valid  = 1'b0;
        end else begin
            mac_result = mac_en ? sum  : 32'b0;
            mac_valid  = mac_en;
        end
    end

endmodule
