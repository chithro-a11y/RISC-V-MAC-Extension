// sim_main.cpp — Verilator C++ testbench for RISC-V MAC core
// Uses only top-level ports — no internal hierarchy access

#include "Vtop.h"
#include "verilated.h"
#include <stdio.h>
#include <stdint.h>

int main(int argc, char** argv) {
    VerilatedContext* ctx = new VerilatedContext;
    ctx->commandArgs(argc, argv);

    Vtop* top = new Vtop{ctx};

    // -----------------------------------------------------------------------
    // Reset sequence
    // -----------------------------------------------------------------------
    top->reset = 1;
    top->clk   = 0;
    for (int i = 0; i < 4; i++) {
        top->clk = 0; ctx->timeInc(5); top->eval();
        top->clk = 1; ctx->timeInc(5); top->eval();
    }
    top->reset = 0;

    // -----------------------------------------------------------------------
    // Run — track output changes
    // -----------------------------------------------------------------------
    int cycle       = 0;
    int done        = 0;
    int stable      = 0;   // counts cycles where output hasn't changed
    uint32_t last_out = 0xFFFFFFFF;

    printf("Cycle |  out[3:0]\n");
    printf("------|----------\n");

    while (!done && cycle < 60) {
        top->clk = 1; ctx->timeInc(5); top->eval();
        cycle++;

        uint32_t cur_out = (uint32_t)top->out;

        if (cur_out != last_out) {
            printf("%5d |  %1X  (%d)\n", cycle, cur_out, cur_out);
            last_out = cur_out;
            stable = 0;
        } else {
            stable++;
        }

        // Stop after output stable for 5 cycles (computation done)
        if (stable >= 5 && cycle > 10) done = 1;

        top->clk = 0; ctx->timeInc(5); top->eval();
    }

    printf("\n========================================\n");
    printf("  FIR Filter Result (Verilator on ARM)\n");
    printf("========================================\n");
    printf("  Final out[3:0] = %d\n", (uint32_t)top->out);
    printf("  Total cycles   = %d\n", cycle);
    printf("  (Expected final out = 6, since 150 & 0xF = 6)\n");
    printf("  %s\n", ((uint32_t)top->out == 6) ? "PASS" : "CHECK WAVEFORM");
    printf("========================================\n");

    top->final();
    delete top;
    delete ctx;
    return 0;
}
