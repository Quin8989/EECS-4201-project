`timescale 1ns/1ps

module execute_tb;
  localparam int DWIDTH = 32;
  localparam int AWIDTH = 32;

  logic [DWIDTH-1:0] rs1_i;
  logic [DWIDTH-1:0] rs2_i;
  logic [3:0] alusel_i;
  logic [DWIDTH-1:0] res_o;

  execute #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) dut (
    .rs1_i(rs1_i),
    .rs2_i(rs2_i),
    .alusel_i(alusel_i),
    .res_o(res_o)
  );

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

  task automatic check_alu(
    input string name,
    input logic [DWIDTH-1:0] a,
    input logic [DWIDTH-1:0] b,
    input logic [3:0] sel,
    input logic [DWIDTH-1:0] exp
  );
    rs1_i = a;
    rs2_i = b;
    alusel_i = sel;
    #1;
    if (res_o !== exp) $error("%s: exp=%h got=%h", name, exp, res_o);
    else $display("pass: %s", name);
  endtask

  initial begin
    rs1_i = '0;
    rs2_i = '0;
    alusel_i = ALU_ADD;
    #1;

    check_alu("ADD", 32'h0000_0003, 32'h0000_0004, ALU_ADD, 32'h0000_0007);
    check_alu("SUB", 32'h0000_0003, 32'h0000_0004, ALU_SUB, 32'hFFFF_FFFF);
    check_alu("AND", 32'hF0F0_F0F0, 32'h0F0F_0F0F, ALU_AND, 32'h0000_0000);
    check_alu("OR",  32'hF0F0_F0F0, 32'h0F0F_0F0F, ALU_OR,  32'hFFFF_FFFF);
    check_alu("XOR", 32'hAAAA_5555, 32'hFFFF_0000, ALU_XOR, 32'h5555_5555);

    check_alu("SLL", 32'h0000_0001, 32'h0000_0004, ALU_SLL, 32'h0000_0010);
    check_alu("SRL", 32'h8000_0000, 32'h0000_0004, ALU_SRL, 32'h0800_0000);
    check_alu("SRA", 32'h8000_0000, 32'h0000_0004, ALU_SRA, 32'hF800_0000);
    check_alu("SLL shift 0", 32'h0000_0001, 32'h0000_0000, ALU_SLL, 32'h0000_0001);
    check_alu("SRL shift 31", 32'h8000_0000, 32'h0000_001F, ALU_SRL, 32'h0000_0001);
    check_alu("SRA shift 31", 32'h8000_0000, 32'h0000_001F, ALU_SRA, 32'hFFFF_FFFF);

    check_alu("SLT signed", 32'hFFFF_FFFF, 32'h0000_0001, ALU_SLT, 32'h0000_0001);
    check_alu("SLTU unsigned", 32'hFFFF_FFFF, 32'h0000_0001, ALU_SLTU, 32'h0000_0000);
    check_alu("SLT signed false", 32'h0000_0002, 32'h0000_0001, ALU_SLT, 32'h0000_0000);
    check_alu("SLT signed equal", 32'h0000_0001, 32'h0000_0001, ALU_SLT, 32'h0000_0000);
    check_alu("SLTU unsigned true", 32'h0000_0001, 32'h0000_0002, ALU_SLTU, 32'h0000_0001);
    check_alu("SLTU unsigned equal", 32'h0000_0001, 32'h0000_0001, ALU_SLTU, 32'h0000_0000);

    $display("done. execute looks good.");
    $finish;
  end
endmodule
