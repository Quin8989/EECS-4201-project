/*
 * Module: alu
 *
 * Description: A simple ALU module that does addition, subtraction,
 * logical OR, and logical AND operation. The operations are
 * combinational circuits.
 *
 * Inputs:
 * 1) DWIDTH-wide input op1_i
 * 2) DWIDTH-wide input op2_i
 * 3) 2-bit selection signal sel_i
 * (refer constants_pkg.sv for the selection signals)
 *
 * Outputs:
 * 1) DWIDTH-wide result res_o
 * 2) 1-bit signal that is asserted if result is zero (zero_o)
 * 3) 1-bit signal that is asserted if result is negative (neg_o)
 */
 
// Declare the enumerations in a package
import constants_pkg::*;

module alu #(
    parameter int DWIDTH = 8
)(
    input  logic [1:0]        sel_i,   // 2-bit control: 00=ADD,01=SUB,10=AND,11=OR
    input  logic [DWIDTH-1:0] op1_i,
    input  logic [DWIDTH-1:0] op2_i,
    output logic [DWIDTH-1:0] res_o,   // result of the selected operation
    output logic              zero_o,  // high when result is zero
    output logic              neg_o    // high when result is negative
);

    always_comb begin
        // Default assignments
        res_o  = '0;
        zero_o = 1'b0;
        neg_o  = 1'b0;

        // Perform operation based on sel_i
        unique case (sel_i)
            ADD:     res_o = op1_i + op2_i;
            SUB:     res_o = op1_i - op2_i;
            AND:     res_o = op1_i & op2_i;
            OR:      res_o = op1_i | op2_i;
            default: res_o = '0;
        endcase

        // Set flags based on result
        zero_o = (res_o == '0);
        neg_o  = res_o[DWIDTH-1];
    end

endmodule : alu
