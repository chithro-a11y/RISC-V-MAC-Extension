`timescale 1ns/1ps

module pc(input clk, reset, input [31:0] next, output reg [31:0] pc);

always @ (posedge clk or posedge reset)
 begin
    if(reset)
    begin 
        pc <= 0;
    end
    else begin 
        pc <= next;
    end

 end

endmodule
