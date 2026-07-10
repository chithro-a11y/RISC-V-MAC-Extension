module data_memory #(parameter N=32)(
  input clk, memwrite, memread,
  input [N-1:0] address, write_data,
  output reg [N-1:0] read_data
);

reg [N-1:0] mem[0:N-1];

integer i;
initial begin
    for(i = 0; i < 32; i = i + 1) 
      mem[i] = {N{1'b0}};
end

// Write: synchronous
always @ (posedge clk)
begin
    if (memwrite)
        mem[address] <= write_data;
end

// Read: combinational
always @ (*)
begin
    if (memread)
        read_data = mem[address];
    else
        read_data = {N{1'b0}};
end
    
endmodule