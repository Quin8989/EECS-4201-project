`timescale 1ns/1ps

module branch_control_tb;
  localparam int DWIDTH = 32;

  logic [2:0] funct3_i;
  logic [DWIDTH-1:0] rs1_i;
  logic [DWIDTH-1:0] rs2_i;
  logic breq_o;
  logic brlt_o;

  branch_control #(.DWIDTH(DWIDTH)) dut (
    .funct3_i(funct3_i),
    .rs1_i(rs1_i),
    .rs2_i(rs2_i),
    .breq_o(breq_o),
    .brlt_o(brlt_o)
  );

  task automatic check_branch(
    input string name,
    input logic [DWIDTH-1:0] rs1,
    input logic [DWIDTH-1:0] rs2,
    input logic [2:0] funct3,
    input logic exp_breq,
    input logic exp_brlt
  );
    rs1_i = rs1;
    rs2_i = rs2;
    funct3_i = funct3;
    #1;

    if (breq_o !== exp_breq) $error("%s: breq exp=%b got=%b", name, exp_breq, breq_o);
    if (brlt_o !== exp_brlt) $error("%s: brlt exp=%b got=%b", name, exp_brlt, brlt_o);
    if (breq_o === exp_breq && brlt_o === exp_brlt) $display("pass: %s", name);
  endtask

  initial begin
    rs1_i = '0;
    rs2_i = '0;
    funct3_i = 3'b000;
    #1;

    check_branch("BEQ equal", 32'h0000_0005, 32'h0000_0005, 3'b000, 1'b1, 1'b0);
    check_branch("BNE not equal", 32'h0000_0005, 32'h0000_0006, 3'b001, 1'b0, 1'b0);
    check_branch("BEQ not equal", 32'h0000_0005, 32'h0000_0006, 3'b000, 1'b0, 1'b0);
    check_branch("BNE equal", 32'h0000_0005, 32'h0000_0005, 3'b001, 1'b1, 1'b0);

    check_branch("BLT signed", 32'hFFFF_FFF0, 32'h0000_0001, 3'b100, 1'b0, 1'b1);
    check_branch("BGE signed", 32'h0000_0002, 32'h0000_0001, 3'b101, 1'b0, 1'b0);
    check_branch("BLT signed false", 32'h0000_0001, 32'hFFFF_FFF0, 3'b100, 1'b0, 1'b0);
    check_branch("BGE signed true", 32'h0000_0001, 32'hFFFF_FFF0, 3'b101, 1'b0, 1'b0);
    check_branch("BLT signed equal", 32'h0000_0001, 32'h0000_0001, 3'b100, 1'b1, 1'b0);
    check_branch("BGE signed equal", 32'h0000_0001, 32'h0000_0001, 3'b101, 1'b1, 1'b0);

    check_branch("BLTU unsigned", 32'h0000_0001, 32'h0000_0002, 3'b110, 1'b0, 1'b1);
    check_branch("BGEU unsigned", 32'h0000_0002, 32'h0000_0001, 3'b111, 1'b0, 1'b0);
    check_branch("BLTU unsigned false", 32'hFFFF_FFFF, 32'h0000_0001, 3'b110, 1'b0, 1'b0);
    check_branch("BGEU unsigned true", 32'hFFFF_FFFF, 32'h0000_0001, 3'b111, 1'b0, 1'b0);
    check_branch("BLTU unsigned equal", 32'h0000_0001, 32'h0000_0001, 3'b110, 1'b1, 1'b0);
    check_branch("BGEU unsigned equal", 32'h0000_0001, 32'h0000_0001, 3'b111, 1'b1, 1'b0);

    $display("done. branch_control looks good.");
    $finish;
  end
endmodule
