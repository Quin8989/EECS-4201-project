`include "probes.svh"
`include "clockgen.sv"

// Simple fetch PC smoke test: verifies reset loads BASEADDR and PC increments by 4 bytes per cycle.
module selftest_pc;
  logic clk;
  logic rst;

  // Simple reset tracking to detect deassert.
  logic reset_reg;
  logic reset_neg;

  clockgen cg (
      .clk(clk),
      .rst(rst)
  );

  design_wrapper dut (
      .clk(clk),
      .reset(rst)
  );

  logic [31:0] start_pc;

  // Track reset deassert only.
  always_ff @(posedge clk) begin
    reset_reg <= rst;
    if (rst) begin
      reset_neg <= 0;
    end else if (reset_reg && !rst) begin
      reset_neg <= 1; // one-shot
    end else begin
      reset_neg <= 0;
    end
  end

  // Wait for reset to clear, then check PC start and first increments.
  initial begin
    @(negedge clk);
    wait (reset_neg);

    // First visible PC right after reset is low; allow either BASEADDR or BASEADDR+4
    // because ModelSim may advance once on the deassert edge.
    @(negedge clk);
    start_pc = dut.core.`PROBE_F_PC;

    if (!(start_pc === 32'h01000000 || start_pc === 32'h01000004)) begin
      $fatal(1, "PC after reset deassert is %h (expected 01000000 or 01000004)", dut.core.`PROBE_F_PC);
    end
    start_pc = (start_pc === 32'h01000004) ? 32'h01000004 : 32'h01000000;

    // After 5 more cycles, PC should have advanced by 5 * 4 bytes.
    repeat (5) @(negedge clk);
    if (dut.core.`PROBE_F_PC !== start_pc + 32'd20) begin
      $fatal(1, "PC after 5 cycles is %h (expected %h)", dut.core.`PROBE_F_PC, start_pc + 32'd20);
    end

    $display("[selftest_pc] PASS");
    $finish;
  end
endmodule
