module register #(parameter N = 32)(
    input clk, reg_write, reset,
    input [4:0] read_reg1, read_reg2, write_reg,
    input [4:0]  read_reg3,    // NEW: third read port — reads current rd for MAC accumulator
    input [N-1:0] write_data,
    output [N-1:0] read_data1, read_data2,
    output [N-1:0] read_data3  // NEW: current value of rd, fed to mac_unit as acc_in
);

  reg [N-1:0] regi[0:N-1];

  assign read_data1 = regi[read_reg1];
  assign read_data2 = regi[read_reg2];
  assign read_data3 = regi[read_reg3]; // combinational read — available same cycle

  integer i;

  initial begin
    for(i = 0; i < 32; i = i + 1)
      regi[i] = 0;
  end

  always @ (posedge clk) begin
    if(reset) begin
      for(i = 0; i < 32; i = i + 1)
        regi[i] <= 0;
    end
    else if(reg_write && write_reg != 0) begin
        regi[write_reg] <= write_data;
    end   
  end    

endmodule