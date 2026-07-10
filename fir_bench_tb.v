`timescale 1ns/1ps

// fir_bench_tb.v — FIR benchmark testbench
// Measures cycle count for MACC version vs MUL+ADD baseline
// Both should produce y[n] = 150
// Run MACC version first (instruction.v = instruction_macc.v),
// then baseline (instruction.v = instruction_baseline.v)

module fir_bench_tb;

    reg  clk, reset;
    wire [3:0] out;

    top uut (.clk(clk), .reset(reset), .out(out));

    initial clk = 0;
    always #5 clk = ~clk;

    `define RF uut.m1.r1.regi

    integer cycle_count;
    integer done;

    initial begin
        $dumpfile("sim/fir_bench.vcd");
        $dumpvars(0, fir_bench_tb);

        cycle_count = 0;
        done = 0;

        reset = 1; #20; reset = 0;

        // Run until x9 holds 150 (filter output complete) or timeout
        while (!done && cycle_count < 50) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;

            $display("Cycle %2d | PC=%02h | INSTR=%08h | mac_en=%b | x9(acc)=%3d | x10(tmp)=%3d",
                cycle_count,
                uut.m1.pc_current,
                uut.m1.instruction,
                uut.m1.mac_en,
                `RF[9],
                `RF[10]
            );

            // Done when accumulator reaches 150
            if (`RF[9] === 32'd150) begin
                done = 1;
            end
        end

        $display("\n========================================");
        $display("  FIR Filter Benchmark Result");
        $display("========================================");
        $display("  Final x9 (y[n]) = %0d  (expected 150)", `RF[9]);

        if (`RF[9] === 32'd150)
            $display("  PASS: correct filter output");
        else
            $display("  FAIL: incorrect output");

        $display("  Cycles to complete: %0d", cycle_count);
        $display("  (MACC expected: 13 | Baseline expected: 17)");
        $display("========================================\n");

        $finish;
    end

endmodule
