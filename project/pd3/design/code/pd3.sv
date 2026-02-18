/*
 * Module: pd3
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd3 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32)(
    input logic clk,
    input logic reset
);

/*
* Instantiate other submodules and
* probes. To be filled by student...
*
*/

// fetch probes
logic [AWIDTH-1:0] probe_f_pc;
logic [DWIDTH-1:0] probe_f_insn;

// decode probes
logic [AWIDTH-1:0] probe_d_pc;
logic [DWIDTH-1:0] probe_d_insn;
logic [6:0] probe_d_opcode;
logic [4:0] probe_d_rd;
logic [4:0] probe_d_rs1;
logic [4:0] probe_d_rs2;
logic [6:0] probe_d_funct7;
logic [2:0] probe_d_funct3;
logic [4:0] probe_d_shamt;

// immediate generator probe
logic [DWIDTH-1:0] probe_imm;

// control probes
logic probe_pcsel;
logic probe_immsel;
logic probe_regwren;
logic probe_rs1sel;
logic probe_rs2sel;
logic probe_memren;
logic probe_memwren;
logic [1:0] probe_wbsel;
logic [3:0] probe_alusel;

// register file probes
logic probe_r_write_enable;
logic [4:0] probe_r_write_destination;
logic [DWIDTH-1:0] probe_r_write_data;
logic [4:0] probe_r_read_rs1;
logic [4:0] probe_r_read_rs2;
logic [DWIDTH-1:0] probe_r_read_rs1_data;
logic [DWIDTH-1:0] probe_r_read_rs2_data;

// execute/branch probes
logic [AWIDTH-1:0] probe_e_pc;
logic [DWIDTH-1:0] probe_e_alu_res;
logic probe_e_br_taken;
logic probe_e_breq;
logic probe_e_brlt;

// Internal datapath wires
logic [DWIDTH-1:0] alu_op1;
logic [DWIDTH-1:0] alu_op2;

// Fetch
fetch #(
  .DWIDTH(DWIDTH),
  .AWIDTH(AWIDTH)
) u_fetch (
  .clk(clk),
  .rst(reset),
  .pc_o(probe_f_pc),
  .insn_o(probe_f_insn)
);

// Decode
decode #(
  .DWIDTH(DWIDTH),
  .AWIDTH(AWIDTH)
) u_decode (
  .clk(clk),
  .rst(reset),
  .insn_i(probe_f_insn),
  .pc_i(probe_f_pc),

  .pc_o(probe_d_pc),
  .insn_o(probe_d_insn),
  .opcode_o(probe_d_opcode),
  .rd_o(probe_d_rd),
  .rs1_o(probe_d_rs1),
  .rs2_o(probe_d_rs2),
  .funct7_o(probe_d_funct7),
  .funct3_o(probe_d_funct3),
  .shamt_o(probe_d_shamt),
  .imm_o()
);

// Immediate generator
igen #(
  .DWIDTH(DWIDTH)
) u_igen (
  .opcode_i(probe_d_opcode),
  .insn_i(probe_d_insn),
  .imm_o(probe_imm)
);

// Control
control #(
  .DWIDTH(DWIDTH)
) u_control (
  .opcode_i(probe_d_opcode),
  .funct7_i(probe_d_funct7),
  .funct3_i(probe_d_funct3),

  .pcsel_o(probe_pcsel),
  .immsel_o(probe_immsel),
  .regwren_o(probe_regwren),
  .rs1sel_o(probe_rs1sel),
  .rs2sel_o(probe_rs2sel),
  .memren_o(probe_memren),
  .memwren_o(probe_memwren),
  .wbsel_o(probe_wbsel),
  .alusel_o(probe_alusel)
);

// Register file
register_file #(
  .DWIDTH(DWIDTH)
) u_regfile (
  .clk(clk),
  .rst(reset),
  .rs1_i(probe_d_rs1),
  .rs2_i(probe_d_rs2),
  .rd_i(probe_r_write_destination),
  .datawb_i(probe_r_write_data),
  .regwren_i(probe_r_write_enable),
  .rs1data_o(probe_r_read_rs1_data),
  .rs2data_o(probe_r_read_rs2_data)
);

// register file probe aliases
assign probe_r_read_rs1 = probe_d_rs1;
assign probe_r_read_rs2 = probe_d_rs2;
assign probe_r_write_destination = probe_d_rd;
assign probe_r_write_enable = probe_regwren;

// Operand select muxes
assign alu_op1 = (probe_rs1sel) ? probe_d_pc : probe_r_read_rs1_data;
assign alu_op2 = (probe_rs2sel) ? probe_imm : probe_r_read_rs2_data;

// Branch control
branch_control #(
  .DWIDTH(DWIDTH)
) u_branch_control (
  .funct3_i(probe_d_funct3),
  .rs1_i(probe_r_read_rs1_data),
  .rs2_i(probe_r_read_rs2_data),
  .breq_o(probe_e_breq),
  .brlt_o(probe_e_brlt)
);

// Execute / ALU
execute #(
  .DWIDTH(DWIDTH),
  .AWIDTH(AWIDTH)
) u_execute (
  .rs1_i(alu_op1),
  .rs2_i(alu_op2),
  .alusel_i(probe_alusel),
  .res_o(probe_e_alu_res)
);

assign probe_e_pc = probe_d_pc;

// branch taken (from branch_control results)
always_comb begin
  probe_e_br_taken = 1'b0;
  if (probe_d_opcode == 7'b110_0011) begin
    unique case (probe_d_funct3)
      3'b000: probe_e_br_taken = probe_e_breq;        // BEQ
      3'b001: probe_e_br_taken = ~probe_e_breq;       // BNE
      3'b100: probe_e_br_taken = probe_e_brlt;        // BLT
      3'b101: probe_e_br_taken = ~probe_e_brlt;       // BGE
      3'b110: probe_e_br_taken = probe_e_brlt;        // BLTU
      3'b111: probe_e_br_taken = ~probe_e_brlt;       // BGEU
      default: probe_e_br_taken = 1'b0;
    endcase
  end
end

// Writeback (stub for PD3)
assign probe_r_write_data = '0;

endmodule : pd3
