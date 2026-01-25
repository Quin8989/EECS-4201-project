/*
 * Module: pd1
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd1 #(
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

  // Test interface probes (controlled by pattern checker during testing)
  logic [31:0] addr;
  logic [31:0] data_in;
  logic [31:0] data_out;
  logic        read_en;
  logic        write_en;

  // Fetch stage probes (for future testing)
  logic [31:0] fetch_pc;
  logic [31:0] fetch_insn;

  // Memory module instantiation
  memory #(
      .AWIDTH(32),
      .DWIDTH(32)
  ) mem (
      .clk(clk),
      .rst(reset),
      .addr_i(addr),
      .data_i(data_in),
      .read_en_i(read_en),
      .write_en_i(write_en),
      .data_o(data_out)
  );

  // Fetch stage instantiation
  fetch #(
      .AWIDTH(32),
      .DWIDTH(32)
  ) fetchStage (
      .clk(clk),
      .rst(reset),
      .pc_o(fetch_pc),
      .insn_o(fetch_insn)
  );

endmodule : pd1
