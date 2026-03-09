/*
 * Module: control
 *
 * Description: Sets control bits based on the decoded instruction.
 * Part of the decode stage but in its own module.
 *
 * Inputs:
 * 1) 7-bit opcode opcode_i
 * 2) 7-bit funct7 funct7_i
 * 3) 3-bit funct3 funct3_i
 *
 * Outputs:
 * 1) 1-bit PC select pcsel_o
 * 2) 1-bit Immediate select immsel_o
 * 3) 1-bit register write en regwren_o
 * 4) 1-bit rs1 select rs1sel_o
 * 5) 1-bit rs2 select rs2sel_o
 * 6) k-bit ALU select alusel_o
 * 7) 1-bit memory read en memren_o
 * 8) 1-bit memory write en memwren_o
 * 9) 2-bit writeback sel wbsel_o
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
                    default:     alusel_o = 'x;
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
                    default:     alusel_o = 'x;
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
                pcsel_o   = 'x;
                immsel_o  = 'x;
                regwren_o = 'x;
                rs1sel_o  = 'x;
                rs2sel_o  = 'x;
                memren_o  = 'x;
                memwren_o = 'x;
                wbsel_o   = 'x;
                alusel_o  = 'x;
            end
        endcase
    end

endmodule : control
