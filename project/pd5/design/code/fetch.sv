/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD1 -----------
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 *
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide instruction output insn_o
 */

`include "constants.svh"

module fetch #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32,
    parameter int BASEADDR=32'h01000000
)(
    input logic clk,
    input logic rst,
    input logic [AWIDTH-1:0] next_pc_i,
    input logic brtaken_i,
    input logic stall_i,

    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    // Program counter register
    logic [AWIDTH-1:0] pc_q = BASEADDR;

    assign pc_o = pc_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            pc_q <= BASEADDR;
        end else if (stall_i) begin
            // hold pc when we need a stall
            pc_q <= pc_q;
        end else if (brtaken_i) begin
            // branch or jump wins when we are not stalling
            pc_q <= next_pc_i;
        end else begin
            pc_q <= pc_q + 32'd4;
        end
    end

    // Instruction memory
    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(BASEADDR)
    ) insn_mem (
        .clk       (clk),
        .rst       (rst),
        .addr_i    (pc_q),
        .data_i    ('0),
        .read_en_i (1'b1),
        .write_en_i(1'b0),
        .funct3_i  (`F3_WORD),
        .data_o    (insn_o),
        .raw_data_o(),
        .data_vld_o()
    );

endmodule : fetch