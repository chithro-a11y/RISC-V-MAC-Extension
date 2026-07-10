`timescale 1ns/1ps

module top(
    input clk, reset,
    output [3:0] out
);

 datapath m1(.clk(clk), .reset(reset), .out(out));   

endmodule