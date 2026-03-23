/*
 * Module: pd5
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

`include "constants.svh"

module pd5 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
)(
    input logic clk,
    input logic reset
);

    logic [31:0] nop_insn;
    assign nop_insn = 32'h00000013;

    logic [AWIDTH-1:0] data_out;

    logic [AWIDTH-1:0] f_pc;
    logic [DWIDTH-1:0] f_insn;

    logic [AWIDTH-1:0] next_pc;
    logic branch_taken_ex;
    logic load_use_stall;

    logic [AWIDTH-1:0] ifid_pc;
    logic [DWIDTH-1:0] ifid_insn;

    logic [AWIDTH-1:0] d_pc;
    logic [DWIDTH-1:0] d_insn;
    logic [6:0] d_opcode;
    logic [4:0] d_rd;
    logic [4:0] d_rs1;
    logic [4:0] d_rs2;
    logic [6:0] d_funct7;
    logic [2:0] d_funct3;
    logic [4:0] d_shamt;
    logic [DWIDTH-1:0] d_imm;

    logic d_pcsel;
    logic d_immsel;
    logic d_regwren;
    logic d_rs1sel;
    logic d_rs2sel;
    logic d_memren;
    logic d_memwren;
    logic [1:0] d_wbsel;
    logic [3:0] d_alusel;

    logic [DWIDTH-1:0] d_rs1_data;
    logic [DWIDTH-1:0] d_rs2_data;

    logic [AWIDTH-1:0] idex_pc;
    logic [DWIDTH-1:0] idex_insn;
    logic [6:0] idex_opcode;
    logic [4:0] idex_rd;
    logic [4:0] idex_rs1;
    logic [4:0] idex_rs2;
    logic [6:0] idex_funct7;
    logic [2:0] idex_funct3;
    logic [4:0] idex_shamt;
    logic [DWIDTH-1:0] idex_imm;
    logic [DWIDTH-1:0] idex_rs1_data;
    logic [DWIDTH-1:0] idex_rs2_data;

    logic idex_pcsel;
    logic idex_immsel;
    logic idex_regwren;
    logic idex_rs1sel;
    logic idex_rs2sel;
    logic idex_memren;
    logic idex_memwren;
    logic [1:0] idex_wbsel;
    logic [3:0] idex_alusel;

    logic [DWIDTH-1:0] ex_fwd_rs1_data;
    logic [DWIDTH-1:0] ex_fwd_rs2_data;
    logic [DWIDTH-1:0] ex_operand_a;
    logic [DWIDTH-1:0] ex_operand_b;
    logic [DWIDTH-1:0] e_alu_res;
    logic ex_breq;
    logic ex_brlt;
    logic e_br_taken;
    logic [AWIDTH-1:0] ex_branch_target;

    logic [AWIDTH-1:0] exmem_pc;
    logic [DWIDTH-1:0] exmem_insn;
    logic [6:0] exmem_opcode;
    logic [4:0] exmem_rd;
    logic [4:0] exmem_rs2;
    logic [2:0] exmem_funct3;
    logic [DWIDTH-1:0] exmem_alu_res;
    logic [DWIDTH-1:0] exmem_rs2_data;
    logic exmem_regwren;
    logic exmem_memren;
    logic exmem_memwren;
    logic [1:0] exmem_wbsel;

    logic [DWIDTH-1:0] m_data;
    logic [DWIDTH-1:0] mem_store_data;
    logic m_data_vld;

    logic [AWIDTH-1:0] memwb_pc;
    logic [DWIDTH-1:0] memwb_insn;
    logic [4:0] memwb_rd;
    logic [DWIDTH-1:0] memwb_alu_res;
    logic [DWIDTH-1:0] memwb_mem_data;
    logic memwb_regwren;
    logic [1:0] memwb_wbsel;

    logic [DWIDTH-1:0] wb_data;

    logic r_write_enable;
    logic [4:0] r_write_destination;
    logic [DWIDTH-1:0] r_write_data;
    logic [4:0] r_read_rs1;
    logic [4:0] r_read_rs2;
    logic [DWIDTH-1:0] r_read_rs1_data;
    logic [DWIDTH-1:0] r_read_rs2_data;

    logic [AWIDTH-1:0] e_pc;
    logic [AWIDTH-1:0] m_pc;
    logic [AWIDTH-1:0] m_pc_probe;
    logic [AWIDTH-1:0] e_pc_probe;
    logic [DWIDTH-1:0] e_alu_res_probe;
    logic e_br_taken_probe;
    logic [AWIDTH-1:0] m_address;
    logic [AWIDTH-1:0] m_address_probe;
    logic [2:0] m_size_encoded;

    logic [AWIDTH-1:0] w_pc;
    logic w_enable;
    logic [4:0] w_destination;
    logic [DWIDTH-1:0] w_data;

    logic [AWIDTH-1:0] w_pc_probe;
    logic w_enable_probe;
    logic [4:0] w_destination_probe;
    logic [DWIDTH-1:0] w_data_probe;

    logic [31:0] rf_x15;

    logic [AWIDTH-1:0] d_pc_probe;
    logic [6:0] d_opcode_probe;
    logic [4:0] d_rd_probe;
    logic [2:0] d_funct3_probe;
    logic [4:0] d_rs1_probe;
    logic [4:0] d_rs2_probe;
    logic [6:0] d_funct7_probe;
    logic [DWIDTH-1:0] d_imm_probe;
    logic [4:0] d_shamt_probe;
    logic d_uses_rs2;
    logic d_uses_rs1;
    logic [DWIDTH-1:0] m_data_probe;

    assign data_out = f_insn;

    assign r_write_enable      = memwb_regwren;
    assign r_write_destination = memwb_rd;
    assign r_write_data        = wb_data;
    assign r_read_rs1          = d_rs1;
    assign r_read_rs2          = d_rs2;
    assign r_read_rs1_data     = d_rs1_data;
    assign r_read_rs2_data     = d_rs2_data;

    assign e_pc           = idex_pc;
    assign m_pc           = exmem_pc;
    assign m_address      = exmem_alu_res;
    assign m_size_encoded = exmem_funct3;
    assign w_pc           = memwb_pc;
    assign w_enable       = memwb_regwren;
    assign w_destination  = memwb_rd;
    assign w_data         = wb_data;

    // checker-facing probe masking
    always_comb begin
        if (ifid_insn == '0) begin
            d_pc_probe     = '0;
            d_opcode_probe = '0;
            d_rd_probe     = '0;
            d_funct3_probe = '0;
            d_rs1_probe    = '0;
            d_rs2_probe    = '0;
            d_funct7_probe = '0;
            d_imm_probe    = '0;
            d_shamt_probe  = '0;
        end else begin
            d_pc_probe     = d_pc;
            d_opcode_probe = d_opcode;
            d_rd_probe     = d_rd;
            d_funct3_probe = d_funct3;
            d_rs1_probe    = d_rs1;
            d_rs2_probe    = d_rs2;
            d_funct7_probe = d_funct7;
            d_imm_probe    = d_imm;
            d_shamt_probe  = d_shamt;
        end
    end

    always_comb begin
        if (idex_insn == '0) begin
            e_pc_probe       = '0;
            e_alu_res_probe  = '0;
            e_br_taken_probe = 1'b0;
        end else begin
            e_pc_probe       = e_pc;
            e_alu_res_probe  = e_alu_res;
            e_br_taken_probe = e_br_taken;
        end
    end

    always_comb begin
        if (exmem_insn == '0)
            m_data_probe = '0;
        else
            m_data_probe = mem_store_data;
    end

    always_comb begin
        if (memwb_insn == '0) begin
            w_pc_probe          = '0;
            w_enable_probe      = 1'b0;
            w_destination_probe = '0;
            w_data_probe        = '0;
        end else begin
            w_pc_probe          = w_pc;
            w_enable_probe      = w_enable;
            w_destination_probe = w_destination;
            w_data_probe        = w_data;
        end
    end

    always_comb begin
        if (exmem_insn == '0) begin
            m_pc_probe      = '0;
            m_address_probe = '0;
        end else begin
            m_pc_probe      = m_pc;
            m_address_probe = m_address;
        end
    end

    // fetch
    fetch #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) fetch_0 (
        .clk       (clk),
        .rst       (reset),
        .next_pc_i (next_pc),
        .brtaken_i (branch_taken_ex),
        .stall_i   (load_use_stall),
        .pc_o      (f_pc),
        .insn_o    (f_insn)
    );

    // IF/ID
    always_ff @(posedge clk) begin
        if (reset) begin
            ifid_pc   <= '0;
            ifid_insn <= '0;
        end else if (branch_taken_ex) begin
            // keep the same decode pc, but squash the instruction into a real nop
            ifid_pc   <= ifid_pc;
            ifid_insn <= nop_insn;
        end else if (!load_use_stall) begin
            ifid_pc   <= f_pc;
            ifid_insn <= f_insn;
        end
    end

    // decode
    decode #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) decode_0 (
        .clk      (clk),
        .rst      (reset),
        .insn_i   (ifid_insn),
        .pc_i     (ifid_pc),
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

    igen #(
        .DWIDTH(DWIDTH)
    ) igen_0 (
        .opcode_i (d_opcode),
        .insn_i   (d_insn),
        .imm_o    (d_imm)
    );

    control control_0 (
        .opcode_i  (d_opcode),
        .funct7_i  (d_funct7),
        .funct3_i  (d_funct3),
        .pcsel_o   (d_pcsel),
        .immsel_o  (d_immsel),
        .regwren_o (d_regwren),
        .rs1sel_o  (d_rs1sel),
        .rs2sel_o  (d_rs2sel),
        .memren_o  (d_memren),
        .memwren_o (d_memwren),
        .wbsel_o   (d_wbsel),
        .alusel_o  (d_alusel)
    );

    register_file #(
        .DWIDTH(DWIDTH)
    ) register_file_0 (
        .clk       (clk),
        .rst       (reset),
        .rs1_i     (d_rs1),
        .rs2_i     (d_rs2),
        .rd_i      (memwb_rd),
        .datawb_i  (wb_data),
        .regwren_i (memwb_regwren),
        .rs1data_o (d_rs1_data),
        .rs2data_o (d_rs2_data),
        .x15       (rf_x15)
    );

    always_comb begin
        case (d_opcode)
            `OPC_RTYPE,
            `OPC_STORE,
            `OPC_BRANCH: d_uses_rs2 = 1'b1;
            default:     d_uses_rs2 = 1'b0;
        endcase
    end

    always_comb begin
        case (d_opcode)
            `OPC_LUI,
            `OPC_AUIPC,
            `OPC_JAL: d_uses_rs1 = 1'b0;
            default:  d_uses_rs1 = 1'b1;
        endcase
    end

    assign load_use_stall =
        idex_memren &&
        (idex_rd != 5'd0) &&
        (
            ((d_uses_rs1 && (d_rs1 == idex_rd) && (d_rs1 != 5'd0))) ||
            ((d_uses_rs2 && (d_rs2 == idex_rd) && (d_rs2 != 5'd0)) && (d_opcode != `OPC_STORE))
        );


    // ID/EX
    always_ff @(posedge clk) begin
        if (reset) begin
            idex_pc       <= '0;
            idex_insn     <= '0;
            idex_opcode   <= '0;
            idex_rd       <= '0;
            idex_rs1      <= '0;
            idex_rs2      <= '0;
            idex_funct7   <= '0;
            idex_funct3   <= '0;
            idex_shamt    <= '0;
            idex_imm      <= '0;
            idex_rs1_data <= '0;
            idex_rs2_data <= '0;
            idex_pcsel    <= 1'b0;
            idex_immsel   <= 1'b0;
            idex_regwren  <= 1'b0;
            idex_rs1sel   <= 1'b0;
            idex_rs2sel   <= 1'b0;
            idex_memren   <= 1'b0;
            idex_memwren  <= 1'b0;
            idex_wbsel    <= `WB_OFF;
            idex_alusel   <= `ALU_ADD;
        end else if (load_use_stall) begin
            idex_pc       <= '0;
            idex_insn     <= '0;
            idex_opcode   <= '0;
            idex_rd       <= '0;
            idex_rs1      <= '0;
            idex_rs2      <= '0;
            idex_funct7   <= '0;
            idex_funct3   <= '0;
            idex_shamt    <= '0;
            idex_imm      <= '0;
            idex_rs1_data <= '0;
            idex_rs2_data <= '0;
            idex_pcsel    <= 1'b0;
            idex_immsel   <= 1'b0;
            idex_regwren  <= 1'b0;
            idex_rs1sel   <= 1'b0;
            idex_rs2sel   <= 1'b0;
            idex_memren   <= 1'b0;
            idex_memwren  <= 1'b0;
            idex_wbsel    <= `WB_OFF;
            idex_alusel   <= `ALU_ADD;
        end else if (branch_taken_ex) begin
            // send a nop-looking instruction into execute at the same pc
            idex_pc       <= ifid_pc;
            idex_insn     <= nop_insn;
            idex_opcode   <= `OPC_ITYPE;
            idex_rd       <= 5'd0;
            idex_rs1      <= 5'd0;
            idex_rs2      <= 5'd0;
            idex_funct7   <= 7'd0;
            idex_funct3   <= 3'd0;
            idex_shamt    <= 5'd0;
            idex_imm      <= 32'd0;
            idex_rs1_data <= 32'd0;
            idex_rs2_data <= 32'd0;

            // control for addi x0, x0, 0
            idex_pcsel    <= 1'b0;
            idex_immsel   <= 1'b1;
            idex_regwren  <= 1'b1;
            idex_rs1sel   <= 1'b0;
            idex_rs2sel   <= 1'b0;
            idex_memren   <= 1'b0;
            idex_memwren  <= 1'b0;
            idex_wbsel    <= `WB_ALU;
            idex_alusel   <= `ALU_ADD;
        end else begin
            idex_pc       <= d_pc;
            idex_insn     <= d_insn;
            idex_opcode   <= d_opcode;
            idex_rd       <= d_rd;
            idex_rs1      <= d_rs1;
            idex_rs2      <= d_rs2;
            idex_funct7   <= d_funct7;
            idex_funct3   <= d_funct3;
            idex_shamt    <= d_shamt;
            idex_imm      <= d_imm;
            idex_rs1_data <= d_rs1_data;
            idex_rs2_data <= d_rs2_data;
            idex_pcsel    <= d_pcsel;
            idex_immsel   <= d_immsel;
            idex_regwren  <= d_regwren;
            idex_rs1sel   <= d_rs1sel;
            idex_rs2sel   <= d_rs2sel;
            idex_memren   <= d_memren;
            idex_memwren  <= d_memwren;
            idex_wbsel    <= d_wbsel;
            idex_alusel   <= d_alusel;
        end
    end

    // proper EX forwarding
    always_comb begin
        ex_fwd_rs1_data = idex_rs1_data;
        ex_fwd_rs2_data = idex_rs2_data;

        if (exmem_regwren && (exmem_rd != 5'd0) && (exmem_rd == idex_rs1) && !exmem_memren)
            ex_fwd_rs1_data = exmem_alu_res;
        else if (memwb_regwren && (memwb_rd != 5'd0) && (memwb_rd == idex_rs1))
            ex_fwd_rs1_data = wb_data;

        if (exmem_regwren && (exmem_rd != 5'd0) && (exmem_rd == idex_rs2) && !exmem_memren)
            ex_fwd_rs2_data = exmem_alu_res;
        else if (memwb_regwren && (memwb_rd != 5'd0) && (memwb_rd == idex_rs2))
            ex_fwd_rs2_data = wb_data;
    end

    // execute operand selection
    always_comb begin
        ex_operand_a = ex_fwd_rs1_data;
        ex_operand_b = ex_fwd_rs2_data;

        case (idex_opcode)
            `OPC_AUIPC: begin
                ex_operand_a = idex_pc;
                ex_operand_b = idex_imm;
            end
            `OPC_JAL: begin
                ex_operand_a = idex_pc;
                ex_operand_b = idex_imm;
            end
            `OPC_JALR: begin
                ex_operand_a = ex_fwd_rs1_data;
                ex_operand_b = idex_imm;
            end
            `OPC_BRANCH: begin
                ex_operand_a = idex_pc;
                ex_operand_b = idex_imm;
            end
            `OPC_LUI: begin
                ex_operand_a = 32'd0;
                ex_operand_b = idex_imm;
            end
            `OPC_ITYPE,
            `OPC_LOAD,
            `OPC_STORE: begin
                ex_operand_a = ex_fwd_rs1_data;
                ex_operand_b = idex_imm;
            end
            default: begin
                ex_operand_a = ex_fwd_rs1_data;
                ex_operand_b = ex_fwd_rs2_data;
            end
        endcase
    end

    branch_control #(
        .DWIDTH(DWIDTH)
    ) branch_control_0 (
        .funct3_i (idex_funct3),
        .rs1_i    (ex_fwd_rs1_data),
        .rs2_i    (ex_fwd_rs2_data),
        .breq_o   (ex_breq),
        .brlt_o   (ex_brlt)
    );

    execute #(
        .DWIDTH(DWIDTH)
    ) execute_0 (
        .rs1_i    (ex_operand_a),
        .rs2_i    (ex_operand_b),
        .alusel_i (idex_alusel),
        .res_o    (e_alu_res)
    );

    always_comb begin
        e_br_taken = 1'b0;

        if (idex_opcode == `OPC_BRANCH) begin
            case (idex_funct3)
                `F3_BEQ:  e_br_taken = ex_breq;
                `F3_BNE:  e_br_taken = ~ex_breq;
                `F3_BLT:  e_br_taken = ex_brlt;
                `F3_BGE:  e_br_taken = ~ex_brlt;
                `F3_BLTU: e_br_taken = ex_brlt;
                `F3_BGEU: e_br_taken = ~ex_brlt;
                default:  e_br_taken = 1'b0;
            endcase
        end
    end


    always_comb begin
        if (idex_opcode == `OPC_JALR)
            ex_branch_target = (ex_fwd_rs1_data + idex_imm) & 32'hffff_fffe;
        else
            ex_branch_target = idex_pc + idex_imm;
    end

    assign branch_taken_ex = e_br_taken | idex_pcsel;
    assign next_pc = ex_branch_target;

    // EX/MEM
    always_ff @(posedge clk) begin
        if (reset) begin
            exmem_pc       <= '0;
            exmem_insn     <= '0;
            exmem_opcode   <= '0;
            exmem_rd       <= '0;
            exmem_rs2      <= '0;
            exmem_funct3   <= '0;
            exmem_alu_res  <= '0;
            exmem_rs2_data <= '0;
            exmem_regwren  <= 1'b0;
            exmem_memren   <= 1'b0;
            exmem_memwren  <= 1'b0;
            exmem_wbsel    <= `WB_OFF;
        end else begin
            exmem_pc       <= idex_pc;
            exmem_insn     <= idex_insn;
            exmem_opcode   <= idex_opcode;
            exmem_rd       <= idex_rd;
            exmem_rs2      <= idex_rs2;
            exmem_funct3   <= idex_funct3;
            exmem_alu_res  <= e_alu_res;
            exmem_rs2_data <= idex_rs2_data;
            exmem_regwren  <= idex_regwren;
            exmem_memren   <= idex_memren;
            exmem_memwren  <= idex_memwren;
            exmem_wbsel    <= idex_wbsel;
        end
    end

    // proper store-data forwarding
    always_comb begin
        mem_store_data = exmem_rs2_data;

        if ((exmem_rs2 != 5'd0) && (memwb_rd == exmem_rs2))
            mem_store_data = wb_data;
    end

    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(32'h01000000)
    ) data_memory_0 (
        .clk        (clk),
        .rst        (reset),
        .addr_i     (exmem_alu_res),
        .data_i     (mem_store_data),
        .read_en_i  (exmem_memren),
        .write_en_i (exmem_memwren),
        .funct3_i   (exmem_funct3),
        .data_o     (m_data),
        .raw_data_o (),
        .data_vld_o (m_data_vld)
    );

    // MEM/WB
    always_ff @(posedge clk) begin
        if (reset) begin
            memwb_pc       <= '0;
            memwb_insn     <= '0;
            memwb_rd       <= '0;
            memwb_alu_res  <= '0;
            memwb_mem_data <= '0;
            memwb_regwren  <= 1'b0;
            memwb_wbsel    <= `WB_OFF;
        end else begin
            memwb_pc       <= exmem_pc;
            memwb_insn     <= exmem_insn;
            memwb_rd       <= exmem_rd;
            memwb_alu_res  <= exmem_alu_res;
            memwb_mem_data <= m_data;
            memwb_regwren  <= exmem_regwren;
            memwb_wbsel    <= exmem_wbsel;
        end
    end

    writeback #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) writeback_0 (
        .pc_i             (memwb_pc),
        .alu_res_i        (memwb_alu_res),
        .memory_data_i    (memwb_mem_data),
        .wbsel_i          (memwb_wbsel),
        .writeback_data_o (wb_data)
    );

    // optional light debug only
    always_ff @(posedge clk) begin
        if (!reset) begin
            if (w_pc_probe == 32'h01000230 || w_pc_probe == 32'h0100023c) begin
                $display("WB_PASSFAIL: w_pc=%h x15=%h w_enable=%b w_dest=%0d w_data=%h",
                        w_pc_probe, rf_x15, w_enable_probe, w_destination_probe, w_data_probe);
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!reset && exmem_pc == 32'h01000058) begin
            $display("FAILDBG_M: pc=%h insn=%h opcode=%h rs2=%0d exmem_rs2_data=%h mem_store_data=%h memwb_rd=%0d wb_data=%h",
                    exmem_pc, exmem_insn, exmem_opcode, exmem_rs2, exmem_rs2_data, mem_store_data, memwb_rd, wb_data);
        end
    end

    always_ff @(posedge clk) begin
        if (!reset && (memwb_rd == 5'd15) && memwb_regwren) begin
            $display("X15DBG: w_pc=%h wbsel=%0d alu_res=%h mem_data=%h wb_data=%h",
                    memwb_pc, memwb_wbsel, memwb_alu_res, memwb_mem_data, wb_data);
        end
    end

    // program termination logic
    reg is_program = 0;
    always_ff @(posedge clk) begin
        if (data_out == 32'h00000073) $finish;
        if (data_out == 32'h00008067) is_program = 1;
        if (is_program && (register_file_0.registers[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
    end

endmodule : pd5