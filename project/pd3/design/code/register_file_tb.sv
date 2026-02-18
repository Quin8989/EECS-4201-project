`timescale 1ns/1ps

module register_file_tb;
  localparam int DWIDTH = 32;

  logic clk;
  logic rst;
  logic [4:0] rs1_i;
  logic [4:0] rs2_i;
  logic [4:0] rd_i;
  logic [DWIDTH-1:0] datawb_i;
  logic regwren_i;
  logic [DWIDTH-1:0] rs1data_o;
  logic [DWIDTH-1:0] rs2data_o;

  register_file #(.DWIDTH(DWIDTH)) dut (
    .clk(clk),
    .rst(rst),
    .rs1_i(rs1_i),
    .rs2_i(rs2_i),
    .rd_i(rd_i),
    .datawb_i(datawb_i),
    .regwren_i(regwren_i),
    .rs1data_o(rs1data_o),
    .rs2data_o(rs2data_o)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  task automatic do_reset;
    rst = 1;
    rs1_i = 0;
    rs2_i = 0;
    rd_i = 0;
    datawb_i = '0;
    regwren_i = 0;
    repeat (2) @(posedge clk);
    rst = 0;
    @(posedge clk);
  endtask

  task automatic write_reg(input [4:0] rd, input [DWIDTH-1:0] data);
    @(posedge clk);
    rd_i = rd;
    datawb_i = data;
    regwren_i = 1;
    @(posedge clk);
    regwren_i = 0;
  endtask

  task automatic check_read(
    input string name,
    input [4:0] rs1,
    input [4:0] rs2,
    input [DWIDTH-1:0] exp1,
    input [DWIDTH-1:0] exp2
  );
    rs1_i = rs1;
    rs2_i = rs2;
    #1;
    if (rs1data_o !== exp1) $error("%s: rs1 exp=%h got=%h", name, exp1, rs1data_o);
    if (rs2data_o !== exp2) $error("%s: rs2 exp=%h got=%h", name, exp2, rs2data_o);
    if (rs1data_o === exp1 && rs2data_o === exp2) $display("pass: %s", name);
  endtask

  initial begin
    do_reset();

    check_read("x0 hardwired", 5'd0, 5'd0, 32'h0, 32'h0);

    check_read("x2 init", 5'd2, 5'd0, 32'h0110_0000, 32'h0);

    write_reg(5'd5, 32'hDEAD_BEEF);
    check_read("write/read x5", 5'd5, 5'd0, 32'hDEAD_BEEF, 32'h0);

    write_reg(5'd6, 32'h1234_5678);
    check_read("write/read x6", 5'd6, 5'd5, 32'h1234_5678, 32'hDEAD_BEEF);

    write_reg(5'd0, 32'hFFFF_FFFF);
    check_read("write ignored x0", 5'd0, 5'd5, 32'h0, 32'hDEAD_BEEF);

    write_reg(5'd5, 32'hAAAA_AAAA);
    check_read("overwrite x5", 5'd5, 5'd6, 32'hAAAA_AAAA, 32'h1234_5678);

    do_reset();
    check_read("reset clears x5", 5'd5, 5'd0, 32'h0, 32'h0);
    check_read("reset preserves x2", 5'd2, 5'd0, 32'h0110_0000, 32'h0);

    $display("done. register_file looks good.");
    $finish;
  end
endmodule
