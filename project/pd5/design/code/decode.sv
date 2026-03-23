/*
 * Module: decode
 *
 * Description: Decode stage
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD2 -----------
 */

`include "constants.svh"

module decode #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    input logic clk,
    input logic rst,
    input logic [DWIDTH - 1:0] insn_i,
    input logic [DWIDTH - 1:0] pc_i,
    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o,
    output logic [6:0] opcode_o,
    output logic [4:0] rd_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [6:0] funct7_o,
    output logic [2:0] funct3_o,
    output logic [4:0] shamt_o,
    output logic [DWIDTH-1:0] imm_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    // Pass-through
    assign insn_o   = insn_i;
    assign pc_o     = pc_i;
    assign imm_o    = '0;

    // Extract fields directly from standard bit positions
    assign opcode_o = insn_i[6:0];
    assign rd_o     = insn_i[11:7];
    assign funct3_o = insn_i[14:12];
    assign rs1_o    = insn_i[19:15];
    assign rs2_o    = insn_i[24:20];
    assign funct7_o = insn_i[31:25];

    // assign shamt_o  = (insn_i[6:0] == `OPC_ITYPE && (insn_i[14:12] == `F3_SLL || insn_i[14:12] == `F3_SRL_SRA))
    //                   ? insn_i[24:20] : 'x;
    
    assign shamt_o = (insn_i[6:0] == `OPC_ITYPE && (insn_i[14:12] == `F3_SLL || insn_i[14:12] == `F3_SRL_SRA))
                 ? insn_i[24:20] : 5'd0;

endmodule : decode