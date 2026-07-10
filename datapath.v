`timescale 1ns/1ps

// datapath.v — Single-cycle RISC-V RV32I + custom MACC extension
//
// Changes from original:
//   1. control.v now outputs mac_en
//   2. register file has a third read port (read_reg3 = rd) for acc_in
//   3. mac_unit instance added; its output joins the write_data mux
//   4. write_data mux extended: mac_en ? mac_result : (memtoreg ? mem_read_data : alu_result)
//
// Everything else is identical to the original single-cycle core.

module datapath(
    input  clk, reset,
    output [3:0] out
);

    // ------------------------------------------------------------------
    // Internal wires — original
    // ------------------------------------------------------------------
    wire [31:0] pc_current, pc_next, instruction;
    wire [31:0] read_data1, read_data2;
    wire [31:0] alu_result, mem_read_data;
    wire [31:0] immediate, alu_input2;
    wire [31:0] write_data;
    wire [3:0]  alu_ctr;
    wire [1:0]  alu_op;
    wire        memtoreg, memread, memwrite, branch, alusrc, reg_write;
    wire        zero;

    // ------------------------------------------------------------------
    // NEW wires for MAC extension
    // ------------------------------------------------------------------
    wire        mac_en;         // from control — asserted on MACC opcode
    wire [31:0] acc_in;         // current value of rd, read from regfile port 3
    wire [31:0] mac_result;     // output of mac_unit
    wire        mac_valid;      // mac_unit result ready flag (unused in single-cycle; for future pipeline use)

    // ------------------------------------------------------------------
    // PC
    // ------------------------------------------------------------------
    pc pc_inst (
        .clk(clk), .reset(reset),
        .next(pc_next),
        .pc(pc_current)
    );

    // ------------------------------------------------------------------
    // Instruction memory
    // ------------------------------------------------------------------
    instruction instruct_inst (
        .pc(pc_current), .reset(reset),
        .instruction(instruction)
    );

    // ------------------------------------------------------------------
    // Control unit — now also outputs mac_en
    // ------------------------------------------------------------------
    control c_inst1 (
        .opcode(instruction[6:0]),
        .memtoreg(memtoreg), .memread(memread), .memwrite(memwrite),
        .branch(branch), .alusrc(alusrc), .regwrite(reg_write),
        .alu_op(alu_op),
        .mac_en(mac_en)         // NEW
    );

    // ------------------------------------------------------------------
    // Register file — now has third read port for rd (accumulator)
    // read_reg3 = instruction[11:7] = rd field
    // ------------------------------------------------------------------
    register #(32) r1 (
        .clk(clk), .reset(reset), .reg_write(reg_write),
        .read_reg1(instruction[19:15]),   // rs1
        .read_reg2(instruction[24:20]),   // rs2
        .read_reg3(instruction[11:7]),    // NEW: rd — for acc_in
        .write_reg(instruction[11:7]),    // rd (write)
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2),
        .read_data3(acc_in)               // NEW: current rd value → mac_unit
    );

    // ------------------------------------------------------------------
    // Immediate generator (unchanged)
    // ------------------------------------------------------------------
    immediate_gen imm_gen_inst (
        .instruction(instruction),
        .out(immediate)
    );

    // ------------------------------------------------------------------
    // ALU control + ALU (unchanged)
    // ------------------------------------------------------------------
    alu_control alu_ctrl_inst (
        .alu_op(alu_op),
        .func({instruction[25], instruction[30], instruction[14:12]}), // 5 bits: M-ext, funct7[5], funct3
        .alu_cntrl(alu_ctr)
    );

    assign alu_input2 = alusrc ? immediate : read_data2;

    alu #(32) alu_inst (
        .I1(read_data1), .I2(alu_input2),
        .alu_ctr(alu_ctr),
        .out(alu_result),
        .Z_flag(zero)
    );

    // ------------------------------------------------------------------
    // Data memory (unchanged)
    // ------------------------------------------------------------------
    data_memory data_mem_inst (
        .clk(clk), .memread(memread), .memwrite(memwrite),
        .address(alu_result), .write_data(read_data2),
        .read_data(mem_read_data)
    );

    // ------------------------------------------------------------------
    // NEW: MAC unit instance
    // rs1_data = multiplicand (read_data1)
    // rs2_data = multiplier   (read_data2)
    // acc_in   = current rd value from regfile port 3
    // ------------------------------------------------------------------
    mac_unit mac_inst (
        .clk(clk), .rst_n(~reset),     // your core uses active-high reset; mac_unit uses active-low
        .mac_en(mac_en),
        .rs1_data(read_data1),
        .rs2_data(read_data2),
        .acc_in(acc_in),
        .mac_result(mac_result),
        .mac_valid(mac_valid)
    );

    // ------------------------------------------------------------------
    // Write-data mux — EXTENDED from 2-way to 3-way
    //
    // Priority: mac_en > memtoreg > alu_result
    //   mac_en=1  → write mac_result (MACC instruction)
    //   mac_en=0, memtoreg=1 → write mem_read_data (load)
    //   mac_en=0, memtoreg=0 → write alu_result (R-type / I-type)
    //
    // NOTE: mac_unit registers its output — result is ready on the cycle
    // AFTER mac_en is asserted. In a single-cycle core this means MACC
    // takes an extra clock. This is the correct and safe behaviour;
    // the accumulator value is stable before the next instruction reads rd.
    // ------------------------------------------------------------------
    assign write_data = mac_en    ? mac_result    :
                        memtoreg  ? mem_read_data :
                                    alu_result;

    // ------------------------------------------------------------------
    // PC update (unchanged)
    // ------------------------------------------------------------------
    wire [31:0] pc_4, bt;
    assign bt      = immediate + pc_current;
    assign pc_4    = pc_current + 4;
    assign pc_next = (branch & zero) ? bt : pc_4;

    // ------------------------------------------------------------------
    // Output (for testbench probing — unchanged)
    // ------------------------------------------------------------------
    assign out = write_data[3:0];

endmodule
