`include "probes.svh"
`include "clockgen.sv"

// Simple memory smoke test: write then read back to confirm BASE_ADDR offsetting and byte indexing.
module selftest_mem;
  logic clk;
  logic rst;

  // Simple reset tracking to wait a few cycles after deassert.
  logic reset_reg;
  logic reset_neg;
  logic reset_done;
  integer reset_counter;

  clockgen cg (
      .clk(clk),
      .rst(rst)
  );

  design_wrapper dut (
      .clk(clk),
      .reset(rst)
  );

  // Track reset release and wait a few cycles for stability.
  always_ff @(posedge clk) begin
    reset_reg <= rst;
    if (rst) begin
      reset_counter <= 0;
      reset_neg <= 0;
      reset_done <= 0;
    end else begin
      if (reset_reg && !rst) reset_neg <= 1;
      if (reset_neg) reset_counter <= reset_counter + 1;
      if (reset_neg && reset_counter >= 2) reset_done <= 1;  // wait a couple cycles after deassert
    end
  end

  // Drive probes directly (same as pattern checker style).
  task automatic do_write(input logic [31:0] addr, input logic [31:0] data);
    begin
      @(negedge clk);
      dut.core.`PROBE_ADDR = addr;
      dut.core.`PROBE_DATA_IN = data;
      dut.core.`PROBE_READ_EN = 1'b0;
      dut.core.`PROBE_WRITE_EN = 1'b1;
      @(negedge clk);
      dut.core.`PROBE_WRITE_EN = 1'b0;
      dut.core.`PROBE_READ_EN = 1'b0;
    end
  endtask

  task automatic do_read(input logic [31:0] addr, input logic [31:0] expected);
    begin
      @(negedge clk);
      dut.core.`PROBE_ADDR = addr;
      dut.core.`PROBE_READ_EN = 1'b1;
      dut.core.`PROBE_WRITE_EN = 1'b0;
      @(negedge clk);
      if (dut.core.`PROBE_DATA_OUT !== expected) begin
        $fatal(1, "Read @%h got %h (expected %h)", addr, dut.core.`PROBE_DATA_OUT, expected);
      end
      dut.core.`PROBE_READ_EN = 1'b0;
    end
  endtask

  initial begin
    // Wait until reset completes and a few stable cycles pass.
    @(negedge clk);
    wait (reset_done);

    // Write and read back at aligned addresses within the BASE_ADDR region.
    do_write(32'h01000020, 32'hdeadbeef);
    do_write(32'h01000024, 32'hcafebabe);

    do_read (32'h01000020, 32'hdeadbeef);
    do_read (32'h01000024, 32'hcafebabe);

    $display("[selftest_mem] PASS");
    $finish;
  end
endmodule
