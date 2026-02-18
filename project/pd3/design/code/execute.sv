/*
 * Module: alu
 *
 * Description: ALU implementation for execute stage.
 *
 * Inputs:
 * 1) 32-bit PC pc_i
 * 2) 32-bit rs1 data rs1_i
 * 3) 32-bit rs2 data rs2_i
 * 4) 3-bit funct3 funct3_i
 * 5) 7-bit funct7 funct7_i
 *
 * Outputs:
 * 1) 32-bit result of ALU res_o
 * 2) 1-bit branch taken signal brtaken_o
 */

module execute #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    input logic [3:0] alusel_i,
    output logic [DWIDTH-1:0] res_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    // ALU select encoding (must match control.sv)
    localparam logic [3:0] ALU_ADD  = 4'h0;
    localparam logic [3:0] ALU_SUB  = 4'h1;
    localparam logic [3:0] ALU_AND  = 4'h2;
    localparam logic [3:0] ALU_OR   = 4'h3;
    localparam logic [3:0] ALU_XOR  = 4'h4;
    localparam logic [3:0] ALU_SLL  = 4'h5;
    localparam logic [3:0] ALU_SRL  = 4'h6;
    localparam logic [3:0] ALU_SRA  = 4'h7;
    localparam logic [3:0] ALU_SLT  = 4'h8;
    localparam logic [3:0] ALU_SLTU = 4'h9;

    always_comb begin
        res_o = '0;

        unique case (alusel_i)
            ALU_ADD:  res_o = rs1_i + rs2_i;
            ALU_SUB:  res_o = rs1_i - rs2_i;
            ALU_AND:  res_o = rs1_i & rs2_i;
            ALU_OR:   res_o = rs1_i | rs2_i;
            ALU_XOR:  res_o = rs1_i ^ rs2_i;
            ALU_SLL:  res_o = rs1_i << rs2_i[4:0];
            ALU_SRL:  res_o = rs1_i >> rs2_i[4:0];
            ALU_SRA:  res_o = $signed(rs1_i) >>> rs2_i[4:0];
            ALU_SLT:  res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'd1 : 32'd0;
            ALU_SLTU: res_o = (rs1_i < rs2_i) ? 32'd1 : 32'd0;
            default:  res_o = rs1_i + rs2_i;
        endcase
    end

endmodule : execute
