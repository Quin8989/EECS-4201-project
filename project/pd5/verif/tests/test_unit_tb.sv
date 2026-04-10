/*
 * PD6 Unit & Pipeline Integration Testbench
 *
 * Part A – Unit tests (same submodules as PD4):
 *   1. Execute (ALU)       – all 10 ALU operations
 *   2. Branch Control      – BEQ, BNE, BLT, BGE, BLTU, BGEU
 *   3. Memory              – LB, LH, LW, LBU, LHU, SB, SH, SW
 *   4. Writeback           – all 4 wbsel modes
 *   5. Immediate Generator – I, S, B, U, J type immediates
 *
 * Part B – Pipeline integration tests (PD6-specific):
 *   6. RAW forwarding      – MX and WX bypass paths
 *   7. Load-use stall      – one-cycle bubble on load-then-use
 *   8. Branch squash       – instructions after taken branch are squashed
 *   9. Store-data forward  – WM bypass for store after ALU write
 *  10. Full instruction mix – small program run through the pipeline
 */

`include "constants.svh"

module test_unit_tb;

    // ---- Parameters ----
    localparam logic [31:0] BASE_ADDR   = 32'h0100_0000;
    localparam int          DWIDTH      = 32;
    localparam int          AWIDTH      = 32;

    // ---- Scoreboard ----
    integer test_count  = 0;
    integer error_count = 0;
    integer pass_count  = 0;

    // ---- Clock ----
    logic clk = 0;
    always #5 clk = ~clk; // 10-unit period

    // ---- Check helpers (same style as PD4) ----
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
        input string label,
        input logic  actual,
        input logic  expected
    );
        test_count++;
        if (actual !== expected) begin
            error_count++;
            $error("[FAIL] %s: expected %0b, got %0b", label, expected, actual);
        end else begin
            pass_count++;
        end
    endtask

    // ================================================================
    //  PART A – Submodule unit tests
    // ================================================================

    // ---- 1. Execute (ALU) ----
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

        exe_rs1 = 32'd10; exe_rs2 = 32'd20; exe_alusel = `ALU_ADD;
        #1; check32("ALU ADD  10+20", exe_res, 32'd30);

        exe_rs1 = 32'd50; exe_rs2 = 32'd15; exe_alusel = `ALU_SUB;
        #1; check32("ALU SUB  50-15", exe_res, 32'd35);

        exe_rs1 = 32'h0000_FF00; exe_rs2 = 32'h0000_0F0F; exe_alusel = `ALU_AND;
        #1; check32("ALU AND", exe_res, 32'h0000_0F00);

        exe_rs1 = 32'h0000_FF00; exe_rs2 = 32'h0000_00FF; exe_alusel = `ALU_OR;
        #1; check32("ALU OR", exe_res, 32'h0000_FFFF);

        exe_rs1 = 32'h0000_AAAA; exe_rs2 = 32'h0000_5555; exe_alusel = `ALU_XOR;
        #1; check32("ALU XOR", exe_res, 32'h0000_FFFF);

        exe_rs1 = 32'd1; exe_rs2 = 32'd4; exe_alusel = `ALU_SLL;
        #1; check32("ALU SLL  1<<4", exe_res, 32'd16);

        exe_rs1 = 32'h8000_0000; exe_rs2 = 32'd1; exe_alusel = `ALU_SRL;
        #1; check32("ALU SRL  0x80000000>>1", exe_res, 32'h4000_0000);

        exe_rs1 = 32'hFFFF_FFF8; exe_rs2 = 32'd1; exe_alusel = `ALU_SRA;
        #1; check32("ALU SRA  -8>>>1", exe_res, 32'hFFFF_FFFC);

        exe_rs1 = 32'hFFFF_FFFF; exe_rs2 = 32'd1; exe_alusel = `ALU_SLT;
        #1; check32("ALU SLT  -1<1", exe_res, 32'd1);

        exe_rs1 = 32'd1; exe_rs2 = 32'hFFFF_FFFF; exe_alusel = `ALU_SLTU;
        #1; check32("ALU SLTU 1<0xFFFF_FFFF", exe_res, 32'd1);

        exe_rs1 = 32'h7FFF_FFFF; exe_rs2 = 32'd1; exe_alusel = `ALU_ADD;
        #1; check32("ALU ADD  overflow", exe_res, 32'h8000_0000);

        exe_rs1 = 32'd42; exe_rs2 = 32'd42; exe_alusel = `ALU_SUB;
        #1; check32("ALU SUB  equal", exe_res, 32'd0);
    endtask

    // ---- 2. Branch Control ----
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

        br_funct3 = `F3_BEQ; br_rs1 = 32'd100; br_rs2 = 32'd100;
        #1; check1("BEQ equal breq",  br_breq, 1'b1);
            check1("BEQ equal brlt",  br_brlt, 1'b0);

        br_funct3 = `F3_BEQ; br_rs1 = 32'd100; br_rs2 = 32'd200;
        #1; check1("BEQ neq breq", br_breq, 1'b0);

        br_funct3 = `F3_BNE; br_rs1 = 32'd5; br_rs2 = 32'd10;
        #1; check1("BNE neq breq", br_breq, 1'b0);

        br_funct3 = `F3_BLT; br_rs1 = 32'hFFFF_FFFF; br_rs2 = 32'd1;
        #1; check1("BLT signed -1<1 brlt", br_brlt, 1'b1);

        br_funct3 = `F3_BGE; br_rs1 = 32'd5; br_rs2 = 32'd3;
        #1; check1("BGE signed 5>=3 brlt", br_brlt, 1'b0);

        br_funct3 = `F3_BLTU; br_rs1 = 32'd1; br_rs2 = 32'hFFFF_FFFF;
        #1; check1("BLTU unsigned 1<max brlt", br_brlt, 1'b1);

        br_funct3 = `F3_BGEU; br_rs1 = 32'hFFFF_FFFF; br_rs2 = 32'd1;
        #1; check1("BGEU unsigned max>=1 brlt", br_brlt, 1'b0);
    endtask

    // ---- 3. Memory ----
    logic              mem_rst;
    logic [AWIDTH-1:0] mem_addr;
    logic [DWIDTH-1:0] mem_data_i, mem_data_o;
    logic              mem_ren, mem_wen;
    logic [2:0]        mem_funct3;

    memory #(
        .AWIDTH   (AWIDTH),
        .DWIDTH   (DWIDTH),
        .BASE_ADDR(BASE_ADDR)
    ) u_mem (
        .clk        (clk),
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
        mem_rst = 1'b0; mem_ren = 1'b1; mem_wen = 1'b0;

        // SW then LW
        mem_addr = BASE_ADDR; mem_data_i = 32'hDEAD_BEEF;
        mem_funct3 = `F3_WORD; mem_wen = 1'b1;
        @(posedge clk); mem_wen = 1'b0; @(negedge clk);
        check32("MEM SW/LW", mem_data_o, 32'hDEAD_BEEF);

        // SH then LH (signed)
        mem_addr = BASE_ADDR + 32'd4; mem_data_i = 32'h0000_8234;
        mem_funct3 = `F3_HALF; mem_wen = 1'b1;
        @(posedge clk); mem_wen = 1'b0; mem_funct3 = `F3_HALF;
        @(negedge clk); check32("MEM SH/LH sign-ext", mem_data_o, 32'hFFFF_8234);

        // LHU (unsigned) from same address
        mem_funct3 = `F3_HALFU;
        @(negedge clk); check32("MEM LHU zero-ext", mem_data_o, 32'h0000_8234);

        // SB then LB (signed)
        mem_addr = BASE_ADDR + 32'd8; mem_data_i = 32'h0000_00F5;
        mem_funct3 = `F3_BYTE; mem_wen = 1'b1;
        @(posedge clk); mem_wen = 1'b0; mem_funct3 = `F3_BYTE;
        @(negedge clk); check32("MEM SB/LB sign-ext", mem_data_o, 32'hFFFF_FFF5);

        // LBU (unsigned) from same address
        mem_funct3 = `F3_BYTEU;
        @(negedge clk); check32("MEM LBU zero-ext", mem_data_o, 32'h0000_00F5);

        // Verify earlier word intact
        mem_addr = BASE_ADDR; mem_funct3 = `F3_WORD;
        @(negedge clk); check32("MEM LW readback", mem_data_o, 32'hDEAD_BEEF);

        // Overwrite word
        mem_addr = BASE_ADDR; mem_data_i = 32'hCAFE_BABE;
        mem_funct3 = `F3_WORD; mem_wen = 1'b1;
        @(posedge clk); mem_wen = 1'b0;
        @(negedge clk); check32("MEM SW overwrite", mem_data_o, 32'hCAFE_BABE);

        // SB should not clobber neighboring bytes
        mem_addr = BASE_ADDR + 32'd16; mem_data_i = 32'hFFFF_FFFF;
        mem_funct3 = `F3_WORD; mem_wen = 1'b1;
        @(posedge clk);
        mem_data_i = 32'h0000_00AA; mem_funct3 = `F3_BYTE; mem_wen = 1'b1;
        @(posedge clk); mem_wen = 1'b0;
        mem_funct3 = `F3_WORD;
        @(negedge clk); check32("MEM SB partial", mem_data_o, 32'hFFFF_FFAA);
    endtask

    // ---- 4. Writeback ----
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
        wb_pc = 32'h0100_0010; wb_alu = 32'h0000_002A; wb_mem_data = 32'h0000_00FF;

        wb_sel = `WB_OFF; #1; check32("WB OFF -> ALU", wb_data_o, 32'h0000_002A);
        wb_sel = `WB_ALU; #1; check32("WB ALU",        wb_data_o, 32'h0000_002A);
        wb_sel = `WB_MEM; #1; check32("WB MEM",        wb_data_o, 32'h0000_00FF);
        wb_sel = `WB_PC4; #1; check32("WB PC4",        wb_data_o, 32'h0100_0014);
    endtask

    // ---- 5. Immediate Generator ----
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

        // I-type: ADDI x1, x0, 42
        ig_opcode = `OPC_ITYPE;
        ig_insn   = {12'h02A, 5'd0, 3'b000, 5'd1, `OPC_ITYPE};
        #1; check32("IGEN I-type +42", ig_imm, 32'd42);

        // I-type: ADDI x1, x0, -5
        ig_opcode = `OPC_ITYPE;
        ig_insn   = {12'hFFB, 5'd0, 3'b000, 5'd1, `OPC_ITYPE};
        #1; check32("IGEN I-type -5", ig_imm, 32'hFFFF_FFFB);

        // S-type: SW x2, 16(x1)
        ig_opcode = `OPC_STORE;
        ig_insn   = {7'b000_0000, 5'd2, 5'd1, 3'b010, 5'b10000, `OPC_STORE};
        #1; check32("IGEN S-type +16", ig_imm, 32'd16);

        // B-type: BEQ x0, x0, +8
        ig_opcode = `OPC_BRANCH;
        ig_insn   = {1'b0, 6'b000000, 5'd0, 5'd0, 3'b000, 4'b0100, 1'b0, `OPC_BRANCH};
        #1; check32("IGEN B-type +8", ig_imm, 32'd8);

        // U-type: LUI x1, 0xABCDE
        ig_opcode = `OPC_LUI;
        ig_insn   = {20'hABCDE, 5'd1, `OPC_LUI};
        #1; check32("IGEN U-type LUI", ig_imm, 32'hABCDE000);

        // J-type: JAL x1, +4
        ig_opcode = `OPC_JAL;
        ig_insn   = {1'b0, 10'b00_0000_0010, 1'b0, 8'b0000_0000, 5'd1, `OPC_JAL};
        #1; check32("IGEN J-type +4", ig_imm, 32'd4);

        // R-type: no immediate
        ig_opcode = `OPC_RTYPE;
        ig_insn   = {`FUNCT7_STD, 5'd2, 5'd1, 3'b000, 5'd3, `OPC_RTYPE};
        #1; check32("IGEN R-type -> 0", ig_imm, 32'd0);
    endtask

    // ================================================================
    //  PART B – Pipeline integration tests
    // ================================================================
    //
    // Instantiate the full pd5 top-level.  We preload tiny hand-crafted
    // programs into the fetch instruction memory and observe the register
    // file / pipeline signals after enough clock cycles.
    //
    // The pipeline is: IF | ID | EX | MEM | WB  (5 stages, 1 cycle each
    // for non-stalled / non-squashed instructions).

    logic pipe_clk, pipe_rst;
    assign pipe_clk = clk;

    pd5 #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) dut (
        .clk   (pipe_clk),
        .reset (pipe_rst)
    );

    // Helper: read a register value from the register file inside the DUT
    function automatic logic [31:0] reg_val(input int idx);
        return dut.register_file_0.registers[idx];
    endfunction

    // Helper: wait N rising edges
    task automatic tick(input int n);
        repeat (n) @(posedge clk);
    endtask

    // Helper: preload an instruction word into fetch instruction memory
    // byte-addressable: word at address i*4 relative to base
    task automatic preload_insn(input int word_idx, input logic [31:0] insn);
        dut.fetch_0.insn_mem.main_memory[word_idx*4]     = insn[7:0];
        dut.fetch_0.insn_mem.main_memory[word_idx*4 + 1] = insn[15:8];
        dut.fetch_0.insn_mem.main_memory[word_idx*4 + 2] = insn[23:16];
        dut.fetch_0.insn_mem.main_memory[word_idx*4 + 3] = insn[31:24];
    endtask

    // Encoding helpers --------------------------------------------------
    // R-type: funct7[6:0] rs2[4:0] rs1[4:0] funct3[2:0] rd[4:0] opcode[6:0]
    function automatic logic [31:0] enc_r(
        input logic [6:0] funct7, input logic [4:0] rs2,
        input logic [4:0] rs1,    input logic [2:0] funct3,
        input logic [4:0] rd,     input logic [6:0] opcode
    );
        return {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    // I-type: imm[11:0] rs1[4:0] funct3[2:0] rd[4:0] opcode[6:0]
    function automatic logic [31:0] enc_i(
        input logic [11:0] imm,   input logic [4:0] rs1,
        input logic [2:0] funct3, input logic [4:0] rd,
        input logic [6:0] opcode
    );
        return {imm, rs1, funct3, rd, opcode};
    endfunction

    // S-type: imm[11:5] rs2 rs1 funct3 imm[4:0] opcode
    function automatic logic [31:0] enc_s(
        input logic [11:0] imm,   input logic [4:0] rs2,
        input logic [4:0] rs1,    input logic [2:0] funct3,
        input logic [6:0] opcode
    );
        return {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction

    // B-type: imm[12|10:5] rs2 rs1 funct3 imm[4:1|11] opcode
    function automatic logic [31:0] enc_b(
        input logic [12:0] imm,   input logic [4:0] rs2,
        input logic [4:0] rs1,    input logic [2:0] funct3,
        input logic [6:0] opcode
    );
        return {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction

    // NOP : ADDI x0, x0, 0
    localparam logic [31:0] NOP  = 32'h0000_0013;
    // ECALL
    localparam logic [31:0] ECALL = 32'h0000_0073;

    // ---- 6. RAW forwarding (MX and WX) ----
    task test_forwarding;
        $display("\n--- Pipeline: RAW Forwarding ---");

        // Program:
        //   ADDI x1, x0, 10       # x1 = 10
        //   ADDI x2, x1, 20       # MX-fwd: x2 = 10+20 = 30
        //   ADDI x3, x1, 5        # WX-fwd: x3 = 10+5  = 15
        //   NOP
        //   NOP
        //   NOP
        //   NOP
        //   ECALL

        preload_insn(0, enc_i(12'd10,  5'd0, `F3_ADD_SUB, 5'd1, `OPC_ITYPE));  // ADDI x1,x0,10
        preload_insn(1, enc_i(12'd20,  5'd1, `F3_ADD_SUB, 5'd2, `OPC_ITYPE));  // ADDI x2,x1,20
        preload_insn(2, enc_i(12'd5,   5'd1, `F3_ADD_SUB, 5'd3, `OPC_ITYPE));  // ADDI x3,x1,5
        preload_insn(3, NOP);
        preload_insn(4, NOP);
        preload_insn(5, NOP);
        preload_insn(6, NOP);
        preload_insn(7, ECALL);

        // Reset and run
        pipe_rst = 1'b1; tick(3); pipe_rst = 1'b0;
        // Pipeline fills: need ~8 cycles for last ADDI to reach WB
        tick(12);

        check32("FWD x1 = 10", reg_val(1), 32'd10);
        check32("FWD x2 = 30 (MX)", reg_val(2), 32'd30);
        check32("FWD x3 = 15 (WX)", reg_val(3), 32'd15);
    endtask

    // ---- 7. Load-use stall ----
    task test_load_use_stall;
        $display("\n--- Pipeline: Load-Use Stall ---");

        // Preload data memory with value 42 at BASE_ADDR
        dut.data_memory_0.main_memory[0] = 8'd42;
        dut.data_memory_0.main_memory[1] = 8'd0;
        dut.data_memory_0.main_memory[2] = 8'd0;
        dut.data_memory_0.main_memory[3] = 8'd0;

        // Program:
        //   LUI  x5, 0x01000       # x5 = 0x0100_0000 (BASE_ADDR)
        //   LW   x6, 0(x5)         # x6 = mem[BASE] = 42; load
        //   ADDI x7, x6, 8         # uses x6 immediately -> load-use stall, x7 = 50
        //   NOP * 5
        //   ECALL

        preload_insn(0, {20'h01000, 5'd5, `OPC_LUI});                          // LUI x5, 0x01000
        preload_insn(1, enc_i(12'd0, 5'd5, `F3_WORD, 5'd6, `OPC_LOAD));        // LW x6, 0(x5)
        preload_insn(2, enc_i(12'd8, 5'd6, `F3_ADD_SUB, 5'd7, `OPC_ITYPE));    // ADDI x7, x6, 8
        preload_insn(3, NOP);
        preload_insn(4, NOP);
        preload_insn(5, NOP);
        preload_insn(6, NOP);
        preload_insn(7, NOP);
        preload_insn(8, ECALL);

        pipe_rst = 1'b1; tick(3); pipe_rst = 1'b0;
        tick(14); // extra cycle for stall

        check32("LU x5 = BASE",  reg_val(5), BASE_ADDR);
        check32("LU x6 = 42",    reg_val(6), 32'd42);
        check32("LU x7 = 50",    reg_val(7), 32'd50);
    endtask

    // ---- 8. Branch squash ----
    task test_branch_squash;
        $display("\n--- Pipeline: Branch Squash ---");

        // Program:
        //   ADDI  x1, x0, 5        # x1 = 5
        //   ADDI  x2, x0, 5        # x2 = 5
        //   BEQ   x1, x2, +8       # taken -> skip next insn (target = PC+8 = insn at idx 4)
        //   ADDI  x3, x0, 99       # SQUASHED – should not execute
        //   ADDI  x4, x0, 77       # branch target – x4 = 77
        //   NOP * 4
        //   ECALL

        preload_insn(0, enc_i(12'd5,  5'd0, `F3_ADD_SUB, 5'd1, `OPC_ITYPE)); // ADDI x1,x0,5
        preload_insn(1, enc_i(12'd5,  5'd0, `F3_ADD_SUB, 5'd2, `OPC_ITYPE)); // ADDI x2,x0,5
        preload_insn(2, enc_b(13'd8,  5'd2, 5'd1, `F3_BEQ, `OPC_BRANCH));    // BEQ x1,x2,+8
        preload_insn(3, enc_i(12'd99, 5'd0, `F3_ADD_SUB, 5'd3, `OPC_ITYPE)); // ADDI x3,x0,99 (squashed)
        preload_insn(4, enc_i(12'd77, 5'd0, `F3_ADD_SUB, 5'd4, `OPC_ITYPE)); // ADDI x4,x0,77
        preload_insn(5, NOP);
        preload_insn(6, NOP);
        preload_insn(7, NOP);
        preload_insn(8, NOP);
        preload_insn(9, ECALL);

        pipe_rst = 1'b1; tick(3); pipe_rst = 1'b0;
        tick(14);

        check32("BR x1 = 5",       reg_val(1), 32'd5);
        check32("BR x2 = 5",       reg_val(2), 32'd5);
        check32("BR x3 = 0 (squashed)", reg_val(3), 32'd0);  // must NOT be 99
        check32("BR x4 = 77 (target)",  reg_val(4), 32'd77);
    endtask

    // ---- 9. Store-data forwarding (WM bypass) ----
    task test_store_forward;
        $display("\n--- Pipeline: Store-Data Forward (WM) ---");

        // Program:
        //   LUI   x5, 0x01000         # x5 = BASE_ADDR
        //   ADDI  x8, x0, 123         # x8 = 123
        //   NOP                        # spacing
        //   SW    x8, 64(x5)          # store 123 to BASE+64; uses WM bypass for x8
        //   LW    x9, 64(x5)          # load back -> x9 should be 123
        //   NOP * 4
        //   ECALL

        preload_insn(0, {20'h01000, 5'd5, `OPC_LUI});                            // LUI x5
        preload_insn(1, enc_i(12'd123, 5'd0, `F3_ADD_SUB, 5'd8, `OPC_ITYPE));    // ADDI x8,x0,123
        preload_insn(2, NOP);
        preload_insn(3, enc_s(12'd64,  5'd8, 5'd5, `F3_WORD, `OPC_STORE));       // SW x8,64(x5)
        preload_insn(4, enc_i(12'd64,  5'd5, `F3_WORD, 5'd9, `OPC_LOAD));        // LW x9,64(x5)
        preload_insn(5, NOP);
        preload_insn(6, NOP);
        preload_insn(7, NOP);
        preload_insn(8, NOP);
        preload_insn(9, ECALL);

        pipe_rst = 1'b1; tick(3); pipe_rst = 1'b0;
        tick(14);

        check32("SF x8 = 123",       reg_val(8),  32'd123);
        check32("SF x9 = 123 (WM)",  reg_val(9),  32'd123);
    endtask

    // ---- 10. Full instruction mix ----
    task test_full_mix;
        $display("\n--- Pipeline: Full Instruction Mix ---");

        // Small program computing sum = 1+2+3 = 6 via a loop
        //   ADDI  x10, x0, 0        # sum = 0
        //   ADDI  x11, x0, 1        # i = 1
        //   ADDI  x12, x0, 4        # limit = 4 (loop while i < 4)
        // loop:
        //   ADD   x10, x10, x11     # sum += i
        //   ADDI  x11, x11, 1       # i++
        //   BLT   x11, x12, -8      # if i < limit goto loop (offset = -8)
        //   NOP * 4
        //   ECALL

        preload_insn(0, enc_i(12'd0,  5'd0,  `F3_ADD_SUB, 5'd10, `OPC_ITYPE));  // ADDI x10,x0,0
        preload_insn(1, enc_i(12'd1,  5'd0,  `F3_ADD_SUB, 5'd11, `OPC_ITYPE));  // ADDI x11,x0,1
        preload_insn(2, enc_i(12'd4,  5'd0,  `F3_ADD_SUB, 5'd12, `OPC_ITYPE));  // ADDI x12,x0,4

        // loop body at insn indices 3,4,5
        preload_insn(3, enc_r(`FUNCT7_STD, 5'd11, 5'd10, `F3_ADD_SUB, 5'd10, `OPC_RTYPE)); // ADD x10,x10,x11
        preload_insn(4, enc_i(12'd1,  5'd11, `F3_ADD_SUB, 5'd11, `OPC_ITYPE));              // ADDI x11,x11,1

        // BLT x11, x12, -8   (target is insn index 3 = PC of insn5 + (-8))
        // offset = -8 -> 13-bit signed: 13'h1FF8  (= -8 in 13-bit 2's complement)
        preload_insn(5, enc_b(13'h1FF8, 5'd12, 5'd11, `F3_BLT, `OPC_BRANCH));   // BLT x11,x12,-8

        preload_insn(6, NOP);
        preload_insn(7, NOP);
        preload_insn(8, NOP);
        preload_insn(9, NOP);
        preload_insn(10, ECALL);

        pipe_rst = 1'b1; tick(3); pipe_rst = 1'b0;
        tick(40); // enough cycles for 3 loop iterations + drain

        // After loop: i went 1->2->3->4, sum = 1+2+3 = 6
        check32("MIX x10 = 6 (sum)", reg_val(10), 32'd6);
        check32("MIX x11 = 4 (i)",   reg_val(11), 32'd4);
        check32("MIX x12 = 4 (lim)", reg_val(12), 32'd4);
    endtask

    // ================================================================
    //  Main test sequence
    // ================================================================
    initial begin
        $display("\n========================================");
        $display("  PD6 Unit & Pipeline Testbench");
        $display("========================================");

        // Apply memory reset
        mem_rst = 1'b1; pipe_rst = 1'b1;
        @(posedge clk); @(posedge clk);
        mem_rst = 1'b0; pipe_rst = 1'b0;

        // Part A: submodule unit tests
        test_execute();
        test_branch_control();
        test_memory();
        test_writeback();
        test_igen();

        // Part B: pipeline integration tests
        test_forwarding();
        test_load_use_stall();
        test_branch_squash();
        test_store_forward();
        test_full_mix();

        // Summary
        $display("\n========================================");
        $display("  Total: %0d   Passed: %0d   Failed: %0d", test_count, pass_count, error_count);
        $display("========================================");
        if (error_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", error_count);
            $fatal(1, "Testbench detected %0d error(s)", error_count);
        end
        $finish;
    end

endmodule : test_unit_tb
