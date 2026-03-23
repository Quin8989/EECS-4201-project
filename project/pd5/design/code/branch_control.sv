/*
 * Module: branch_control
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD3 -----------
 */

module branch_control #(
    parameter int DWIDTH=32
)(
    input logic [2:0] funct3_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    output logic breq_o,
    output logic brlt_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    always_comb begin
        breq_o = (rs1_i == rs2_i);
        case (funct3_i[2:1])
            2'b10:   brlt_o = ($signed(rs1_i) < $signed(rs2_i));
            2'b11:   brlt_o = (rs1_i < rs2_i);
            default: brlt_o = 1'b0;
        endcase
    end

endmodule : branch_control