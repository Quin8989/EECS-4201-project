/*
 * Module: register_file
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD4 -----------
 *
 */
 
module register_file #(
    parameter int DWIDTH = 32
)(
    input  logic              clk,
    input  logic              rst,
    input  logic [4:0]        rs1_i,
    input  logic [4:0]        rs2_i,
    input  logic [4:0]        rd_i,
    input  logic [DWIDTH-1:0] datawb_i,
    input  logic              regwren_i,
    output logic [DWIDTH-1:0] rs1data_o,
    output logic [DWIDTH-1:0] rs2data_o,
    output logic [31:0]       x15
);

    logic [DWIDTH-1:0] registers [0:31];
    localparam logic [DWIDTH-1:0] STACK_INIT = 32'h0110_0000;

    // Write-first bypass: when WB writes the same register ID is reading
    // on the same clock edge, return the new value instead of the stale one.
    assign rs1data_o = (regwren_i && rd_i != 5'd0 && rd_i == rs1_i) ? datawb_i : registers[rs1_i];
    assign rs2data_o = (regwren_i && rd_i != 5'd0 && rd_i == rs2_i) ? datawb_i : registers[rs2_i];
    assign x15       = registers[15];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                registers[i] <= '0;
            end
            registers[5'd2] <= STACK_INIT;
        end else if (regwren_i && (rd_i != 5'd0)) begin
            registers[rd_i] <= datawb_i;
        end
    end

endmodule : register_file