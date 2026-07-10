`timescale 1ns/1ps

// top_tb.v — Testbench for RISC-V core with MACC extension
//
// Expected execution:
//   Cycle 1: NOP
//   Cycle 2: ADDI x1 = 3
//   Cycle 3: ADDI x2 = 4
//   Cycle 4: ADDI x3 = 10
//   Cycle 5: MACC x3 = 10 + 3*4 = 22   (mac_unit registers output; x3 updated next cycle)
//   Cycle 6: MACC x3 = 22 + 3*4 = 34

module top_tb;
    reg  clk, reset;
    wire [3:0] out;

    top uut (.reset(reset), .clk(clk), .out(out));

    initial clk = 0;
    always #5 clk = ~clk;

    // Helper: read a register value directly from the register file
    // This is safe for simulation probing only
    `define RF uut.m1.r1.regi

    integer cycle;
    integer pass, fail;

    initial begin
        $dumpfile("mac_wave.vcd");
        $dumpvars(0, top_tb);

        pass = 0; fail = 0; cycle = 0;

        reset = 1;
        #20;
        reset = 0;

        // ----------------------------------------------------------------
        // Run and display each cycle
        // ----------------------------------------------------------------
        repeat(10) begin
            @(posedge clk); #1;
            cycle = cycle + 1;
            $display("Cycle %0d | PC=%02h | INSTR=%08h | mac_en=%b | x1=%0d x2=%0d x3=%0d | write_data=%0d",
                cycle,
                uut.m1.pc_current,
                uut.m1.instruction,
                uut.m1.mac_en,
                `RF[1], `RF[2], `RF[3],
                uut.m1.write_data
            );
        end

        $display("\n--- Register file after execution ---");
        $display("x1 = %0d  (expected 3)",  `RF[1]);
        $display("x2 = %0d  (expected 4)",  `RF[2]);
        $display("x3 = %0d  (expected 34)", `RF[3]);

        // Checks
        if (`RF[1] === 32'd3)  begin $display("PASS: x1=3");  pass=pass+1; end
        else                   begin $display("FAIL: x1=%0d (expected 3)",  `RF[1]); fail=fail+1; end

        if (`RF[2] === 32'd4)  begin $display("PASS: x2=4");  pass=pass+1; end
        else                   begin $display("FAIL: x2=%0d (expected 4)",  `RF[2]); fail=fail+1; end

        if (`RF[3] === 32'd34) begin $display("PASS: x3=34 — MACC accumulated correctly"); pass=pass+1; end
        else                   begin $display("FAIL: x3=%0d (expected 34)", `RF[3]); fail=fail+1; end

        $display("\n--- Results: %0d passed, %0d failed ---", pass, fail);
        $finish;
    end

endmodule
