/*
 * Module: top
 *
 * Description: Testbench with minimal hardcoded tests to verify design
 */
`include "probes.svh"

module top;
 logic clock;
 logic reset;

 clockgen clkg(
     .clk(clock),
     .rst(reset)
 );

 design_wrapper dut(
     .clk(clock),
     .reset(reset)
 );

 integer counter = 0;
 integer errors = 0;

 always_ff @(posedge clock) begin
    counter <= counter + 1;
    if(counter == 50) begin
        if(errors == 0) begin
            $display("[PD0] All tests PASSED - No errors encountered");
        end else begin
            $display("[PD0] Tests FAILED - %d errors found", errors);
        end
        $finish;
    end
 end

 logic       reset_done;
 logic       reset_neg;
 logic       reset_reg;
 integer     reset_counter;
 always_ff @(posedge clock) begin
   if(reset) reset_counter <= 0;
   else      reset_counter <= reset_counter + 1;
   // detect negedge
   reset_reg <= reset;
   if(reset_reg && !reset) reset_neg <= 1;
   // Delay for some cycles
   if(reset_neg && reset_counter >= 3) begin
     reset_done <= 1;
   end
 end

`ifdef PROBE_ALU_OP1 `ifdef PROBE_ALU_OP2 `ifdef PROBE_ALU_SEL `ifdef PROBE_ALU_RES
    `define PROBE_ALU_OK
`endif  `endif `endif `endif
`ifdef PROBE_ALU_OK

 logic [1:0] alu_sel;
 logic [31:0] alu_op1;
 logic [31:0] alu_op2;
 logic [31:0] alu_res;
 always_comb begin: alu_input
      // Test ADD at cycle 10
      if(counter == 10) begin
          dut.core.`PROBE_ALU_SEL  = 2'b00;
          dut.core.`PROBE_ALU_OP1  = 32'd5;
          dut.core.`PROBE_ALU_OP2  = 32'd3;
      // Test SUB at cycle 15
      end else if(counter == 15) begin
          dut.core.`PROBE_ALU_SEL  = 2'b01;
          dut.core.`PROBE_ALU_OP1  = 32'd10;
          dut.core.`PROBE_ALU_OP2  = 32'd4;
      end else begin
          dut.core.`PROBE_ALU_SEL  = counter[1:0];
          dut.core.`PROBE_ALU_OP1  = counter[31:0];
          dut.core.`PROBE_ALU_OP2  = {counter[2], counter[3], counter[0], counter[1], counter[31:4]};
      end
  end
  always_ff @(posedge clock) begin: alu_test
      if (reset_done) begin
          $display("[ALU] inp1=%d, inp2=%d, alusel=%b, res=%d", alu_op1, alu_op2, alu_sel, alu_res);
          // Verify ADD: 5 + 3 = 8
          if(counter == 11 && alu_res != 32'd8) begin
              $error("[ALU] ADD test failed: %d + %d = %d (expected 8)", alu_op1, alu_op2, alu_res);
              errors++;
          end
          // Verify SUB: 10 - 4 = 6
          if(counter == 16 && alu_res != 32'd6) begin
              $error("[ALU] SUB test failed: %d - %d = %d (expected 6)", alu_op1, alu_op2, alu_res);
              errors++;
          end
      end
      alu_sel  <= dut.core.`PROBE_ALU_SEL;
      alu_op1 <= dut.core.`PROBE_ALU_OP1;
      alu_op2 <= dut.core.`PROBE_ALU_OP2;
      alu_res  <= dut.core.`PROBE_ALU_RES;
  end
 `else
    always_ff @(posedge clock) begin: alu_test
        $fatal(1, "[ALU] Probe signals not defined");
    end
`endif


`ifdef PROBE_REG_IN `ifdef PROBE_REG_OUT
`define PROBE_REG_OK
`endif `endif
`ifdef PROBE_REG_OK
  logic [31:0] reg_rst_inp;
  logic [31:0] reg_rst_out;

  always_comb begin: reg_rst_input
      // Test specific value at cycle 20
      if(counter == 20) begin
          dut.core.`PROBE_REG_IN = 32'h12345678;
      end else begin
          dut.core.`PROBE_REG_IN = counter[31:0];
      end
  end
  always_ff @(posedge clock) begin: reg_rst_test
      if (reset_done) begin
        $display("[REG] inp=%h, out=%h", reg_rst_inp, reg_rst_out);
        // Verify register: 1-cycle delay (check at cycle 22 for input at cycle 20)
        if(counter == 22 && reg_rst_out != 32'h12345678) begin
            $error("[REG] Register test failed: out = %h (expected 12345678)", reg_rst_out);
            errors++;
        end
      end
      reg_rst_inp <= dut.core.`PROBE_REG_IN;
      reg_rst_out <= dut.core.`PROBE_REG_OUT;
  end
  `else
    always_ff @(posedge clock) begin: reg_rst_test
        $fatal(1, "[REG] Probe signals not defined");
    end
`endif

`ifdef PROBE_TSP_OP1 `ifdef PROBE_TSP_OP2 `ifdef PROBE_TSP_RES
`define PROBE_TSP_OK
`endif `endif `endif
`ifdef PROBE_TSP_OK

  logic [31:0] tsp_op1;
  logic [31:0] tsp_op2;
  logic [31:0] tsp_out;
  always_comb begin: tsp_input
      // Test at cycle 30: (10 + 5) - 10 = 5
      if(counter == 30) begin
          dut.core.`PROBE_TSP_OP1 = 32'd10;
          dut.core.`PROBE_TSP_OP2 = 32'd5;
      end else begin
          dut.core.`PROBE_TSP_OP1 = counter[31:0];
          dut.core.`PROBE_TSP_OP2 = {counter[1], counter[2], counter[0], counter[31:3]};
      end
  end
  always_ff @(posedge clock) begin: tsp_test
      if (reset_done) begin
        $display("[TSP] op1=%d, op2=%d, out=%d", tsp_op1, tsp_op2, tsp_out);
        // Verify 3-cycle latency (check at cycle 34 for input at cycle 30)
        if(counter == 34 && tsp_out != 32'd5) begin
            $error("[TSP] Pipeline test failed: result = %d (expected 5)", tsp_out);
            errors++;
        end
      end
      tsp_op1 <= dut.core.`PROBE_TSP_OP1;
      tsp_op2 <= dut.core.`PROBE_TSP_OP2;
      tsp_out <= dut.core.`PROBE_TSP_RES;
  end
    `else
    always_ff @(posedge clock) begin: tsp_test
        $fatal(1, "[TSP] Probe signals not defined");
    end
`endif


 `ifdef VCD
  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;
  end
  `endif
endmodule
