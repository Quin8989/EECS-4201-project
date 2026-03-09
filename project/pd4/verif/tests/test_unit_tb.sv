/*
 * PD4 Unit Testbench
 *
 * Tests individual modules of the RV32I single-cycle processor:
 *   1. Execute (ALU)       - all 10 ALU operations
 *   2. Branch Control      - BEQ, BNE, BLT, BGE, BLTU, BGEU
 *   3. Memory              - LB, LH, LW, LBU, LHU, SB, SH, SW
 *   4. Writeback           - all 4 wbsel modes
 *   5. Immediate Generator - I, S, B, U, J type immediates
 */

`include "constants.svh"

module test_unit_tb;

    // Testbench parameters
    localparam logic [31:0] BASE_ADDR   = 32'h0100_0000;
    localparam logic [31:0] STACK_INIT  = 32'h0110_0000;
    localparam int          DWIDTH      = 32;
    localparam int          AWIDTH      = 32;

    // Scoreboard
    integer test_count  = 0;
    integer error_count = 0;
    integer pass_count  = 0;

    // Clock
    logic clk  = 0;

    always #5 clk = ~clk;  // 10 time-unit period

    // Check helpers
    task automatic check32(
        input string       label,
        input logic [31:0] actual,
        input logic [31:0] expected
    );
        test_count++;
        if (actual !== expected) begin
            error_count++;
            $error("[FAIL] %s: expected 0x%08h, got 0x%08h", label, expected, actual);
        end else begin
            pass_count++;
        end
    endtask

    task automatic check1(
        input string    label,
        input logic     actual,
        input logic     expected
    );
        test_count++;
        if (actual !== expected) begin
            error_count++;
            $error("[FAIL] %s: expected %0b, got %0b", label, expected, actual);
        end else begin
            pass_count++;
        end
    endtask

    // 1. Execute (ALU)
    logic [DWIDTH-1:0] exe_rs1, exe_rs2, exe_res;
    logic [3:0]        exe_alusel;

    execute #(.DWIDTH(DWIDTH)) u_exe (
        .rs1_i    (exe_rs1),
        .rs2_i    (exe_rs2),
        .alusel_i (exe_alusel),
        .res_o    (exe_res)
    );

    task test_execute;
        $display("\n--- Execute (ALU) ---");

        // ADD: 10 + 20 = 30
        exe_rs1 = 32'd10; exe_rs2 = 32'd20; exe_alusel = `ALU_ADD;
        #1; check32("ALU ADD  10+20", exe_res, 32'd30);

        // SUB: 50 - 15 = 35
        exe_rs1 = 32'd50; exe_rs2 = 32'd15; exe_alusel = `ALU_SUB;
        #1; check32("ALU SUB  50-15", exe_res, 32'd35);

        // AND: 0xFF00 & 0x0F0F = 0x0F00
        exe_rs1 = 32'h0000_FF00; exe_rs2 = 32'h0000_0F0F; exe_alusel = `ALU_AND;
        #1; check32("ALU AND", exe_res, 32'h0000_0F00);

        // OR: 0xFF00 | 0x00FF = 0xFFFF
        exe_rs1 = 32'h0000_FF00; exe_rs2 = 32'h0000_00FF; exe_alusel = `ALU_OR;
        #1; check32("ALU OR", exe_res, 32'h0000_FFFF);

        // XOR: 0xAAAA ^ 0x5555 = 0xFFFF
        exe_rs1 = 32'h0000_AAAA; exe_rs2 = 32'h0000_5555; exe_alusel = `ALU_XOR;
        #1; check32("ALU XOR", exe_res, 32'h0000_FFFF);

        // SLL: 1 << 4 = 16
        exe_rs1 = 32'd1; exe_rs2 = 32'd4; exe_alusel = `ALU_SLL;
        #1; check32("ALU SLL  1<<4", exe_res, 32'd16);

        // SRL: 0x80000000 >> 1 = 0x40000000
        exe_rs1 = 32'h8000_0000; exe_rs2 = 32'd1; exe_alusel = `ALU_SRL;
        #1; check32("ALU SRL  0x80000000>>1", exe_res, 32'h4000_0000);

        // SRA: -8 >>> 1 = -4
        exe_rs1 = 32'hFFFF_FFF8; exe_rs2 = 32'd1; exe_alusel = `ALU_SRA;
        #1; check32("ALU SRA  -8>>>1", exe_res, 32'hFFFF_FFFC);

        // SLT: -1 < 1 -> 1
        exe_rs1 = 32'hFFFF_FFFF; exe_rs2 = 32'd1; exe_alusel = `ALU_SLT;
        #1; check32("ALU SLT  -1<1", exe_res, 32'd1);

        // SLTU: 1 < 0xFFFFFFFF -> 1
        exe_rs1 = 32'd1; exe_rs2 = 32'hFFFF_FFFF; exe_alusel = `ALU_SLTU;
        #1; check32("ALU SLTU 1<0xFFFF_FFFF", exe_res, 32'd1);

        // ADD overflow
        exe_rs1 = 32'h7FFF_FFFF; exe_rs2 = 32'd1; exe_alusel = `ALU_ADD;
        #1; check32("ALU ADD  overflow", exe_res, 32'h8000_0000);

        // SUB yielding zero
        exe_rs1 = 32'd42; exe_rs2 = 32'd42; exe_alusel = `ALU_SUB;
        #1; check32("ALU SUB  equal", exe_res, 32'd0);
    endtask

    // 2. Branch Control
    logic [2:0]        br_funct3;
    logic [DWIDTH-1:0] br_rs1, br_rs2;
    logic              br_breq, br_brlt;

    branch_control #(.DWIDTH(DWIDTH)) u_br (
        .funct3_i (br_funct3),
        .rs1_i    (br_rs1),
        .rs2_i    (br_rs2),
        .breq_o   (br_breq),
        .brlt_o   (br_brlt)
    );

    task test_branch_control;
        $display("\n--- Branch Control ---");

        // BEQ: equal operands -> breq=1
        br_funct3 = `F3_BEQ; br_rs1 = 32'd100; br_rs2 = 32'd100;
        #1; check1("BEQ equal breq",  br_breq, 1'b1);
            check1("BEQ equal brlt",  br_brlt, 1'b0);

        // BEQ: unequal operands -> breq=0
        br_funct3 = `F3_BEQ; br_rs1 = 32'd100; br_rs2 = 32'd200;
        #1; check1("BEQ neq breq", br_breq, 1'b0);

        // BNE: unequal -> breq=0
        br_funct3 = `F3_BNE; br_rs1 = 32'd5; br_rs2 = 32'd10;
        #1; check1("BNE neq breq", br_breq, 1'b0);

        // BLT: signed comparison, -1 < 1 -> brlt=1
        br_funct3 = `F3_BLT; br_rs1 = 32'hFFFF_FFFF; br_rs2 = 32'd1;
        #1; check1("BLT signed -1<1 brlt", br_brlt, 1'b1);

        // BGE: signed comparison, 5 >= 3 -> brlt=0
        br_funct3 = `F3_BGE; br_rs1 = 32'd5; br_rs2 = 32'd3;
        #1; check1("BGE signed 5>=3 brlt", br_brlt, 1'b0);

        // BLTU: unsigned comparison, 1 < 0xFFFF_FFFF -> brlt=1
        br_funct3 = `F3_BLTU; br_rs1 = 32'd1; br_rs2 = 32'hFFFF_FFFF;
        #1; check1("BLTU unsigned 1<max brlt", br_brlt, 1'b1);

        // BGEU: unsigned comparison, 0xFFFF_FFFF >= 1 -> brlt=0
        br_funct3 = `F3_BGEU; br_rs1 = 32'hFFFF_FFFF; br_rs2 = 32'd1;
        #1; check1("BGEU unsigned max>=1 brlt", br_brlt, 1'b0);
    endtask

    // 3. Memory
    logic              mem_clk, mem_rst;
    logic [AWIDTH-1:0] mem_addr;
    logic [DWIDTH-1:0] mem_data_i, mem_data_o;
    logic              mem_ren, mem_wen;
    logic [2:0]        mem_funct3;

    assign mem_clk = clk;

    memory #(
        .AWIDTH   (AWIDTH),
        .DWIDTH   (DWIDTH),
        .BASE_ADDR(BASE_ADDR)
    ) u_mem (
        .clk        (mem_clk),
        .rst        (mem_rst),
        .addr_i     (mem_addr),
        .data_i     (mem_data_i),
        .read_en_i  (mem_ren),
        .write_en_i (mem_wen),
        .funct3_i   (mem_funct3),
        .data_o     (mem_data_o),
        .raw_data_o (),
        .data_vld_o ()
    );

    task test_memory;
        $display("\n--- Memory ---");

        // De-assert reset and disable writes initially
        mem_rst  = 1'b0;
        mem_ren  = 1'b1;
        mem_wen  = 1'b0;

        // --- SW (store word) then LW (load word) ---
        mem_addr    = BASE_ADDR;           // address 0x01000000
        mem_data_i  = 32'hDEAD_BEEF;
        mem_funct3  = `F3_WORD;
        mem_wen     = 1'b1;
        @(posedge clk);                   // write takes effect on clock edge
        mem_wen = 1'b0;
        @(negedge clk);                   // read settles on negedge
        check32("MEM SW/LW", mem_data_o, 32'hDEAD_BEEF);

        // --- SH (store halfword) then LH (load halfword, signed) ---
        mem_addr    = BASE_ADDR + 32'd4;
        mem_data_i  = 32'h0000_8234;      // bit 15 set -> sign extends
        mem_funct3  = `F3_HALF;
        mem_wen     = 1'b1;
        @(posedge clk);
        mem_wen     = 1'b0;
        mem_funct3  = `F3_HALF;
        @(negedge clk);
        check32("MEM SH/LH sign-ext", mem_data_o, 32'hFFFF_8234);

        // --- LHU (load halfword unsigned) from same address ---
        mem_funct3 = `F3_HALFU;
        @(negedge clk);
        check32("MEM LHU zero-ext", mem_data_o, 32'h0000_8234);

        // --- SB (store byte) then LB (load byte, signed) ---
        mem_addr    = BASE_ADDR + 32'd8;
        mem_data_i  = 32'h0000_00F5;      // 0xF5, bit 7 set
        mem_funct3  = `F3_BYTE;
        mem_wen     = 1'b1;
        @(posedge clk);
        mem_wen     = 1'b0;
        mem_funct3  = `F3_BYTE;
        @(negedge clk);
        check32("MEM SB/LB sign-ext", mem_data_o, 32'hFFFF_FFF5);

        // --- LBU (load byte unsigned) from same address ---
        mem_funct3 = `F3_BYTEU;
        @(negedge clk);
        check32("MEM LBU zero-ext", mem_data_o, 32'h0000_00F5);

        // --- Verify word written earlier is still intact ---
        mem_addr   = BASE_ADDR;
        mem_funct3 = `F3_WORD;
        @(negedge clk);
        check32("MEM LW readback", mem_data_o, 32'hDEAD_BEEF);

        // overwrite a previously stored word
        mem_addr    = BASE_ADDR;
        mem_data_i  = 32'hCAFE_BABE;
        mem_funct3  = `F3_WORD;
        mem_wen     = 1'b1;
        @(posedge clk);
        mem_wen = 1'b0;
        @(negedge clk);
        check32("MEM SW overwrite", mem_data_o, 32'hCAFE_BABE);

        // SB should not affect neighboring bytes
        // Write 0xAA to byte 0
        mem_addr    = BASE_ADDR + 32'd16;
        mem_data_i  = 32'hFFFF_FFFF;
        mem_funct3  = `F3_WORD;
        mem_wen     = 1'b1;
        @(posedge clk);
        // Overwrite only byte 0 with 0xAA
        mem_data_i  = 32'h0000_00AA;
        mem_funct3  = `F3_BYTE;
        mem_wen     = 1'b1;
        @(posedge clk);
        mem_wen = 1'b0;
        // Read back as word
        mem_funct3  = `F3_WORD;
        @(negedge clk);
        check32("MEM SB partial", mem_data_o, 32'hFFFF_FFAA);
    endtask

    // 4. Writeback
    logic [AWIDTH-1:0] wb_pc;
    logic [DWIDTH-1:0] wb_alu, wb_mem_data, wb_data_o;
    logic [1:0]        wb_sel;

    writeback #(.DWIDTH(DWIDTH), .AWIDTH(AWIDTH)) u_wb (
        .pc_i            (wb_pc),
        .alu_res_i       (wb_alu),
        .memory_data_i   (wb_mem_data),
        .wbsel_i         (wb_sel),
        .writeback_data_o(wb_data_o)
    );

    task test_writeback;
        $display("\n--- Writeback ---");

        wb_pc       = 32'h0100_0010;  // some PC value
        wb_alu      = 32'h0000_002A;  // ALU result = 42
        wb_mem_data = 32'h0000_00FF;  // memory data = 255

        // WB_OFF: passes ALU through
        wb_sel = `WB_OFF;
        #1; check32("WB OFF -> ALU", wb_data_o, 32'h0000_002A);

        // WB_ALU: select ALU result
        wb_sel = `WB_ALU;
        #1; check32("WB ALU", wb_data_o, 32'h0000_002A);

        // WB_MEM: select memory data
        wb_sel = `WB_MEM;
        #1; check32("WB MEM", wb_data_o, 32'h0000_00FF);

        // WB_PC4: select pc+4
        wb_sel = `WB_PC4;
        #1; check32("WB PC4", wb_data_o, 32'h0100_0014);
    endtask

    // 5. Immediate Generator
    logic [6:0]        ig_opcode;
    logic [DWIDTH-1:0] ig_insn;
    logic [31:0]       ig_imm;

    igen #(.DWIDTH(DWIDTH)) u_ig (
        .opcode_i (ig_opcode),
        .insn_i   (ig_insn),
        .imm_o    (ig_imm)
    );

    task test_igen;
        $display("\n--- Immediate Generator ---");

        // I-type: ADDI x1, x0, 42  ->  imm = 42
        // Encoding: imm[11:0]=42(0x02A), rs1=0, funct3=000, rd=1, opcode=0010011
        ig_opcode = `OPC_ITYPE;
        ig_insn   = {12'h02A, 5'd0, 3'b000, 5'd1, `OPC_ITYPE};
        #1; check32("IGEN I-type +42", ig_imm, 32'd42);

        // I-type: ADDI with negative imm = -5 (0xFFB in 12-bit)
        ig_opcode = `OPC_ITYPE;
        ig_insn   = {12'hFFB, 5'd0, 3'b000, 5'd1, `OPC_ITYPE};
        #1; check32("IGEN I-type -5", ig_imm, 32'hFFFF_FFFB);

        // S-type: SW x2, 16(x1)  ->  imm = 16
        // imm[11:5]=0, imm[4:0]=10000 -> 16
        ig_opcode = `OPC_STORE;
        ig_insn   = {7'b000_0000, 5'd2, 5'd1, 3'b010, 5'b10000, `OPC_STORE};
        #1; check32("IGEN S-type +16", ig_imm, 32'd16);

        // B-type: BEQ x0, x0, +8
        // imm = 8 -> imm[12|10:5]=0, imm[4:1]=0100, imm[11]=0
        // bit layout: insn[31]=0, insn[30:25]=000000, insn[11:8]=0100, insn[7]=0
        ig_opcode = `OPC_BRANCH;
        ig_insn   = {1'b0, 6'b000000, 5'd0, 5'd0, 3'b000, 4'b0100, 1'b0, `OPC_BRANCH};
        #1; check32("IGEN B-type +8", ig_imm, 32'd8);

        // U-type: LUI x1, 0xABCDE  ->  imm = 0xABCDE000
        ig_opcode = `OPC_LUI;
        ig_insn   = {20'hABCDE, 5'd1, `OPC_LUI};
        #1; check32("IGEN U-type LUI", ig_imm, 32'hABCDE000);

        // J-type: JAL x1, +4
        // imm[20|10:1|11|19:12] for offset=4 -> imm[10:1]=0000000010
        // insn[31]=0, insn[30:21]=0000000010, insn[20]=0, insn[19:12]=00000000
        ig_opcode = `OPC_JAL;
        ig_insn   = {1'b0, 10'b00_0000_0010, 1'b0, 8'b0000_0000, 5'd1, `OPC_JAL};
        #1; check32("IGEN J-type +4", ig_imm, 32'd4);

        // R-type: no immediate -> 0
        ig_opcode = `OPC_RTYPE;
        ig_insn   = {`FUNCT7_STD, 5'd2, 5'd1, 3'b000, 5'd3, `OPC_RTYPE};
        #1; check32("IGEN R-type -> 0", ig_imm, 32'd0);
    endtask

    // Main test sequence
    initial begin
        $display("\nPD4 Unit Testbench - Starting");

        // Apply reset for memory
        mem_rst = 1'b1;
        @(posedge clk);
        @(posedge clk);
        mem_rst = 1'b0;

        // Run all module tests
        test_execute();
        test_branch_control();
        test_memory();
        test_writeback();
        test_igen();

        // Results
        $display("\nTotal: %0d  Passed: %0d  Failed: %0d", test_count, pass_count, error_count);
        if (error_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", error_count);
            $fatal(1, "Unit testbench detected %0d error(s)", error_count);
        end
        $finish;
    end

endmodule : test_unit_tb
