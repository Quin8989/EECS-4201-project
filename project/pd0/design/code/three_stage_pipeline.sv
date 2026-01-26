/*
 * Module: three_stage_pipeline
 *
 * A 3-stage pipeline (TSP) where the first stage performs an addition of two
 * operands (op1_i, op2_i) and registers the output, and the second stage computes
 * the difference between the output from the first stage and op1_i and registers the
 * output. This means that the output (res_o) must be available two cycles after the
 * corresponding inputs have been observed on the rising clock edge
 *
 * Visually, the circuit should look like this:
 *               <---         Stage 1           --->
 *                                                        <---         Stage 2           --->
 *                                                                                               <--    Stage 3    -->
 *                                    |------------------>|                    |
 * -- op1_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *             | pipeline registers |     | ALU add | --> | pipeline registers |   | ALU sub |-->| pipeline register  | -- res_o -->
 * -- op2_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *
 * Inputs:
 * 1) 1-bit clock signal
 * 2) 1-bit wide synchronous reset
 * 3) DWIDTH-wide input op1_i
 * 4) DWIDTH-wide input op2_i
 *
 * Outputs:
 * 1) DWIDTH-wide result res_o
 */
import constants_pkg::*;
module three_stage_pipeline #(
parameter int DWIDTH = 8)(
        input logic clk,
        input logic rst,
        input logic [DWIDTH-1:0] op1_i,
        input logic [DWIDTH-1:0] op2_i,
        output logic [DWIDTH-1:0] res_o
    );

// Stage 1: Pipeline registers for inputs
logic [DWIDTH-1:0] stage1_op1_reg, stage1_op2_reg;

reg_rst #(.DWIDTH(DWIDTH)) reg1_op1 (
    .clk(clk),
    .rst(rst),
    .in_i(op1_i),
    .out_o(stage1_op1_reg)
);

reg_rst #(.DWIDTH(DWIDTH)) reg1_op2 (
    .clk(clk),
    .rst(rst),
    .in_i(op2_i),
    .out_o(stage1_op2_reg)
);

// ALU Stage 1: Addition
logic [DWIDTH-1:0] stage1_alu_res;

alu #(.DWIDTH(DWIDTH)) alu_add (
    .sel_i(ADD),
    .op1_i(stage1_op1_reg),
    .op2_i(stage1_op2_reg),
    .res_o(stage1_alu_res),
    .zero_o(),
    .neg_o()
);

// Stage 2: Pipeline registers for ADD result and op1_i (needed for subtraction)
logic [DWIDTH-1:0] stage2_add_res_reg, stage2_op1_reg;

reg_rst #(.DWIDTH(DWIDTH)) reg2_add_res (
    .clk(clk),
    .rst(rst),
    .in_i(stage1_alu_res),
    .out_o(stage2_add_res_reg)
);

reg_rst #(.DWIDTH(DWIDTH)) reg2_op1 (
    .clk(clk),
    .rst(rst),
    .in_i(stage1_op1_reg),
    .out_o(stage2_op1_reg)
);

// ALU Stage 2: Subtraction
logic [DWIDTH-1:0] stage2_alu_res;

alu #(.DWIDTH(DWIDTH)) alu_sub (
    .sel_i(SUB),
    .op1_i(stage2_add_res_reg),
    .op2_i(stage2_op1_reg),
    .res_o(stage2_alu_res),
    .zero_o(),
    .neg_o()
);

// Stage 3: Pipeline register for final result
reg_rst #(.DWIDTH(DWIDTH)) reg3_res (
    .clk(clk),
    .rst(rst),
    .in_i(stage2_alu_res),
    .out_o(res_o)
);

endmodule: three_stage_pipeline
