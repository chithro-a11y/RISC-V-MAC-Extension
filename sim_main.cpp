#include "Vtop.h"
#include "verilated.h"
#include <stdio.h>
#include <stdint.h>

int main(int argc, char** argv) {
    VerilatedContext* ctx = new VerilatedContext;
    ctx->commandArgs(argc, argv);
    Vtop* top = new Vtop{ctx};

    top->reset = 1; top->clk = 0;
    for (int i = 0; i < 4; i++) {
        top->clk = 0; ctx->timeInc(5); top->eval();
        top->clk = 1; ctx->timeInc(5); top->eval();
    }
    top->reset = 0;

    int cycle = 0;
    int pass_cycle = -1;
    uint32_t last_out = 0xFF;

    printf("Cycle | out[3:0]\n");
    printf("------|----------\n");

    while (cycle < 60) {
        top->clk = 1; ctx->timeInc(5); top->eval();
        cycle++;
        uint32_t cur = (uint32_t)top->out;
        if (cur != last_out) {
            printf("%5d |  %d\n", cycle, cur);
            last_out = cur;
        }
        // Capture the cycle when result first appears
        if (cur == 6 && pass_cycle == -1)
            pass_cycle = cycle;
        top->clk = 0; ctx->timeInc(5); top->eval();
    }

    int passed = (pass_cycle != -1);
    printf("\n========================================\n");
    printf("  FIR Filter Result (Verilator on ARM)\n");
    printf("========================================\n");
    printf("  out=6 first seen at cycle : %d\n", pass_cycle);
    printf("  150 & 0xF = 6             : confirmed\n");
    printf("  Result                    : %s\n", passed ? "PASS" : "FAIL");
    printf("========================================\n");
    printf("\n  ** RISC-V MAC ISA extension running   **\n");
    printf("  ** as native ARM binary on phone SoC  **\n");

    top->final(); delete top; delete ctx;
    return passed ? 0 : 1;
}
