/*
 * Module: pd4
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

`include "constants.svh"

module pd4 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
)(
    input logic clk,
    input logic reset
);

    // Fetch signals
    logic [AWIDTH-1:0] f_pc;
    logic [DWIDTH-1:0] f_insn;

    // Decode signals
    logic [AWIDTH-1:0] d_pc;
    logic [DWIDTH-1:0] d_insn;
    logic [6:0]        d_opcode;
    logic [4:0]        d_rd;
    logic [4:0]        d_rs1;
    logic [4:0]        d_rs2;
    logic [6:0]        d_funct7;
    logic [2:0]        d_funct3;
    logic [4:0]        d_shamt;

    // Immediate
    logic [DWIDTH-1:0] imm;

    // Control
    logic              pcsel;
    logic              regwren;
    logic              rs1sel;
    logic              rs2sel;
    logic              memren;
    logic              memwren;
    logic [1:0]        wbsel;
    logic [3:0]        alusel;

    // Register file
    logic              r_wen;
    logic [4:0]        r_wdst;
    logic [DWIDTH-1:0] r_wdata;
    logic [4:0]        r_rs1;
    logic [4:0]        r_rs2;
    logic [DWIDTH-1:0] r_rs1_data;
    logic [DWIDTH-1:0] r_rs2_data;

    // Execute / branch
    logic [AWIDTH-1:0] e_pc;
    logic [DWIDTH-1:0] e_alu_res;
    logic               e_br_taken;
    logic               e_breq;
    logic               e_brlt;

    // Memory stage
    logic [AWIDTH-1:0] m_pc;
    logic [DWIDTH-1:0] m_addr;
    logic [1:0]        m_size;
    logic [DWIDTH-1:0] m_data;

    // Writeback
    logic [AWIDTH-1:0] w_pc;
    logic               w_en;
    logic [4:0]        w_dst;
    logic [DWIDTH-1:0] w_data;

    // Datapath wires
    logic [DWIDTH-1:0] alu_op1;
    logic [DWIDTH-1:0] alu_op2;
    logic [DWIDTH-1:0] mem_read_data;
    logic [DWIDTH-1:0] mem_raw_data;
    logic [DWIDTH-1:0] wb_data;
    logic               brtaken;

    // Fetch
    fetch #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) u_fetch (
        .clk       (clk),
        .rst       (reset),
        .next_pc_i (e_alu_res),
        .brtaken_i (brtaken),
        .pc_o      (f_pc),
        .insn_o    (f_insn)
    );

    // Decode
    decode #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) u_decode (
        .clk      (clk),
        .rst      (reset),
        .insn_i   (f_insn),
        .pc_i     (f_pc),
        .pc_o     (d_pc),
        .insn_o   (d_insn),
        .opcode_o (d_opcode),
        .rd_o     (d_rd),
        .rs1_o    (d_rs1),
        .rs2_o    (d_rs2),
        .funct7_o (d_funct7),
        .funct3_o (d_funct3),
        .shamt_o  (d_shamt),
        .imm_o    ()
    );

    // Immediate gen
    igen #(
        .DWIDTH(DWIDTH)
    ) u_igen (
        .opcode_i (d_opcode),
        .insn_i   (d_insn),
        .imm_o    (imm)
    );

    // Control
    control u_control (
        .opcode_i  (d_opcode),
        .funct7_i  (d_funct7),
        .funct3_i  (d_funct3),
        .pcsel_o   (pcsel),
        .immsel_o  (),
        .regwren_o (regwren),
        .rs1sel_o  (rs1sel),
        .rs2sel_o  (rs2sel),
        .memren_o  (memren),
        .memwren_o (memwren),
        .wbsel_o   (wbsel),
        .alusel_o  (alusel)
    );

    // Regfile
    register_file #(
        .DWIDTH(DWIDTH)
    ) u_regfile (
        .clk       (clk),
        .rst       (reset),
        .rs1_i     (d_rs1),
        .rs2_i     (d_rs2),
        .rd_i      (w_dst),
        .datawb_i  (w_data),
        .regwren_i (w_en),
        .rs1data_o (r_rs1_data),
        .rs2data_o (r_rs2_data)
    );

    // Register file probe aliases
    assign r_rs1   = d_rs1;
    assign r_rs2   = d_rs2;
    assign r_wdst  = d_rd;
    assign r_wen   = regwren;
    assign r_wdata = w_data;

    // Op select muxes
    // LUI needs 0 + imm, but insn[19:15] is part of the immediate (not a real rs1)
    assign alu_op1 = (d_opcode == `OPC_LUI) ? '0 : (rs1sel ? d_pc : r_rs1_data);
    assign alu_op2 = rs2sel ? imm        : r_rs2_data;

    // Branch control
    branch_control #(
        .DWIDTH(DWIDTH)
    ) u_branch_control (
        .funct3_i (d_funct3),
        .rs1_i    (r_rs1_data),
        .rs2_i    (r_rs2_data),
        .breq_o   (e_breq),
        .brlt_o   (e_brlt)
    );

    // ALU
    execute #(
        .DWIDTH(DWIDTH)
    ) u_execute (
        .rs1_i    (alu_op1),
        .rs2_i    (alu_op2),
        .alusel_i (alusel),
        .res_o    (e_alu_res)
    );

    assign e_pc = d_pc;

    // Branch resolution
    // e_br_taken: conditional branch resolution only
    always_comb begin
        e_br_taken = 1'b0;
        if (d_opcode == `OPC_BRANCH) begin
            unique case (d_funct3)
                `F3_BEQ:  e_br_taken =  e_breq;
                `F3_BNE:  e_br_taken = ~e_breq;
                `F3_BLT:  e_br_taken =  e_brlt;
                `F3_BGE:  e_br_taken = ~e_brlt;
                `F3_BLTU: e_br_taken =  e_brlt;
                `F3_BGEU: e_br_taken = ~e_brlt;
                default:  e_br_taken = 1'b0;
            endcase
        end
    end

    // brtaken: conditional branches + JAL/JALR
    assign brtaken = e_br_taken | pcsel;

    // Data memory
    memory #(
        .AWIDTH   (AWIDTH),
        .DWIDTH   (DWIDTH),
        .BASE_ADDR(32'h01000000)
    ) u_data_mem (
        .clk        (clk),
        .rst        (reset),
        .addr_i     (e_alu_res),
        .data_i     (r_rs2_data),
        .read_en_i  (memren),
        .write_en_i (memwren),
        .funct3_i   (d_funct3),
        .data_o     (mem_read_data),
        .raw_data_o (mem_raw_data),
        .data_vld_o ()
    );

    // Memory stage probe aliases
    assign m_pc   = d_pc;
    assign m_addr = e_alu_res;
    assign m_size = d_funct3[1:0];
    assign m_data = mem_raw_data;

    // Writeback
    writeback #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) u_writeback (
        .pc_i            (d_pc),
        .alu_res_i       (e_alu_res),
        .memory_data_i   (mem_read_data),
        .wbsel_i         (wbsel),
        .writeback_data_o(wb_data)
    );

    // Writeback probe aliases
    assign w_pc  = d_pc;
    assign w_en  = regwren;
    assign w_dst = d_rd;
    assign w_data = wb_data;

    // Probes
    `include "probes.svh"

    // Program termination logic
    reg is_program = 0;
    always_ff @(posedge clk) begin
        if (f_insn == 32'h00000073) $finish;            // ECALL
        if (f_insn == 32'h00008067) is_program = 1;     // RET (jalr x0, x1, 0)
        if (is_program && (u_regfile.registers[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
    end

endmodule : pd4
