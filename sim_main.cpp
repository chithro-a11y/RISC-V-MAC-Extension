// sim_main.cpp — Verilator C++ testbench for RISC-V MAC core
// Replaces the Verilog testbench for native ARM deployment
// Compile with: verilator --cc --exe --build sim_main.cpp [verilog files]

#include "Vtop.h"
#include "verilated.h"
#include <stdio.h>
#include <stdint.h>

// Simulated register file access macro
// Verilator exposes hierarchy as nested structs
#define RF(n) top->m1->r1->regi[n]

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
        top->clk = !top->clk; ctx->timeInc(5); top->eval();
        top->clk = !top->clk; ctx->timeInc(5); top->eval();
    }
    top->reset = 0;

    // -----------------------------------------------------------------------
    // Run simulation — stop when x9 = 150 or after 50 cycles
    // -----------------------------------------------------------------------
    int cycle = 0;
    int done  = 0;

    printf("Cycle | PC       | INSTR    | mac_en | x9(acc) | x10(tmp)\n");
    printf("------|----------|----------|--------|---------|----------\n");

    while (!done && cycle < 50) {
        // Rising edge
        top->clk = 1; ctx->timeInc(5); top->eval();
        cycle++;

        uint32_t x9  = (uint32_t)RF(9);
        uint32_t x10 = (uint32_t)RF(10);

        printf("%5d | %08X | %08X |   %d    | %7d | %8d\n",
            cycle,
            (uint32_t)top->m1->pc_current,
            (uint32_t)top->m1->instruction,
            (uint32_t)top->m1->mac_en,
            x9, x10
        );

        if (x9 == 150) done = 1;

        // Falling edge
        top->clk = 0; ctx->timeInc(5); top->eval();
    }

    // -----------------------------------------------------------------------
    // Results
    // -----------------------------------------------------------------------
    printf("\n========================================\n");
    printf("  FIR Filter Result (Verilator/ARM)\n");
    printf("========================================\n");
    printf("  Final x9 = %d  (expected 150)\n", (uint32_t)RF(9));
    printf("  %s\n", (RF(9) == 150) ? "PASS" : "FAIL");
    printf("  Cycles: %d\n", cycle);
    printf("========================================\n");

    top->final();
    delete top;
    delete ctx;
    return (RF(9) == 150) ? 0 : 1;
}
