/*
 * Module: control
 *
 * Description: This module sets the control bits (control path) based on the decoded
 * instruction. Note that this is part of the decode stage but housed in a separate
 * module for better readability, debug and design purposes.
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD2 -----------
 */

`include "constants.svh"

module control (
    input logic [6:0] opcode_i,
    input logic [6:0] funct7_i,
    input logic [2:0] funct3_i,
    output logic pcsel_o,
    output logic immsel_o,
    output logic regwren_o,
    output logic rs1sel_o,
    output logic rs2sel_o,
    output logic memren_o,
    output logic memwren_o,
    output logic [1:0] wbsel_o,
    output logic [3:0] alusel_o
);

    always_comb begin : control_comb
        pcsel_o   = 1'b0;
        immsel_o  = 1'b0;
        regwren_o = 1'b0;
        rs1sel_o  = 1'b0;
        rs2sel_o  = 1'b0;
        memren_o  = 1'b0;
        memwren_o = 1'b0;
        wbsel_o   = `WB_OFF;
        alusel_o  = `ALU_ADD;

        unique case (opcode_i)
            `OPC_RTYPE: begin
                regwren_o = 1'b1;
                wbsel_o   = `WB_ALU;
                unique case (funct3_i)
                    `F3_ADD_SUB: alusel_o = (funct7_i == `FUNCT7_ALT) ? `ALU_SUB : `ALU_ADD;
                    `F3_SLL:     alusel_o = `ALU_SLL;
                    `F3_SLT:     alusel_o = `ALU_SLT;
                    `F3_SLTU:    alusel_o = `ALU_SLTU;
                    `F3_XOR:     alusel_o = `ALU_XOR;
                    `F3_SRL_SRA: alusel_o = (funct7_i == `FUNCT7_ALT) ? `ALU_SRA : `ALU_SRL;
                    `F3_OR:      alusel_o = `ALU_OR;
                    `F3_AND:     alusel_o = `ALU_AND;
                    default:     alusel_o = `ALU_ADD;
                endcase
            end
            `OPC_ITYPE: begin
                regwren_o = 1'b1;
                wbsel_o   = `WB_ALU;
                immsel_o  = 1'b1;
                rs2sel_o  = 1'b1;
                unique case (funct3_i)
                    `F3_ADD_SUB: alusel_o = `ALU_ADD;
                    `F3_SLT:     alusel_o = `ALU_SLT;
                    `F3_SLTU:    alusel_o = `ALU_SLTU;
                    `F3_XOR:     alusel_o = `ALU_XOR;
                    `F3_OR:      alusel_o = `ALU_OR;
                    `F3_AND:     alusel_o = `ALU_AND;
                    `F3_SLL:     alusel_o = `ALU_SLL;
                    `F3_SRL_SRA: alusel_o = (funct7_i == `FUNCT7_ALT) ? `ALU_SRA : `ALU_SRL;
                    default:     alusel_o = `ALU_ADD;
                endcase
            end
            `OPC_LOAD: begin
                regwren_o = 1'b1;
                wbsel_o   = `WB_MEM;
                immsel_o  = 1'b1;
                rs2sel_o  = 1'b1;
                memren_o  = 1'b1;
            end
            `OPC_STORE: begin
                immsel_o  = 1'b1;
                rs2sel_o  = 1'b1;
                memwren_o = 1'b1;
            end
            `OPC_BRANCH: begin
                immsel_o  = 1'b1;
                rs1sel_o  = 1'b1;
                rs2sel_o  = 1'b1;
            end
            `OPC_JAL: begin
                regwren_o = 1'b1;
                wbsel_o   = `WB_PC4;
                immsel_o  = 1'b1;
                rs1sel_o  = 1'b1;
                rs2sel_o  = 1'b1;
                pcsel_o   = 1'b1;
            end
            `OPC_JALR: begin
                regwren_o = 1'b1;
                wbsel_o   = `WB_PC4;
                immsel_o  = 1'b1;
                rs2sel_o  = 1'b1;
                pcsel_o   = 1'b1;
            end
            `OPC_LUI: begin
                regwren_o = 1'b1;
                wbsel_o   = `WB_ALU;
                immsel_o  = 1'b1;
                rs2sel_o  = 1'b1;
            end
            `OPC_AUIPC: begin
                regwren_o = 1'b1;
                wbsel_o   = `WB_ALU;
                immsel_o  = 1'b1;
                rs1sel_o  = 1'b1;
                rs2sel_o  = 1'b1;
            end
            default: begin
                pcsel_o   = 1'b0;
                immsel_o  = 1'b0;
                regwren_o = 1'b0;
                rs1sel_o  = 1'b0;
                rs2sel_o  = 1'b0;
                memren_o  = 1'b0;
                memwren_o = 1'b0;
                wbsel_o   = `WB_OFF;
                alusel_o  = `ALU_ADD;
            end
        endcase
    end

endmodule : control