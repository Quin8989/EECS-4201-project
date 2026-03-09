/*
 * Module: memory
 *
 * Description: Byte-addressable memory. Supports read and write
 * with different access sizes (byte, halfword, word).
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) AWIDTH address addr_i
 * 4) DWIDTH data to write data_i
 * 5) read enable signal read_en_i
 * 6) write enable signal write_en_i
 * 7) 3-bit funct3 funct3_i for load/store type
 *
 * Outputs:
 * 1) DWIDTH data output data_o
 * 2) data out valid signal data_vld_o
 */

`include "constants.svh"

`ifndef MEM_DEPTH
`define MEM_DEPTH 65535     // 64 KB byte-addressable memory
`endif
`ifndef LINE_COUNT
`define LINE_COUNT 4096     // max number of 32-bit words to preload
`endif
`ifndef MEM_PATH
`define MEM_PATH "program.hex"
`endif


module memory #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32,
    parameter logic [31:0] BASE_ADDR = 32'h01000000
) (
    input logic clk,
    input logic rst,
    input logic [AWIDTH-1:0] addr_i = BASE_ADDR,
    input logic [DWIDTH-1:0] data_i,
    input logic read_en_i,
    input logic write_en_i,
    input logic [2:0] funct3_i,
    output logic [DWIDTH-1:0] data_o,
    output logic [DWIDTH-1:0] raw_data_o,
    output logic data_vld_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */

    logic [DWIDTH-1:0] temp_memory [0:`MEM_DEPTH];
    logic [7:0] main_memory [0:`MEM_DEPTH];
    logic [AWIDTH-1:0] address;
    assign address = (addr_i - BASE_ADDR) & (`MEM_DEPTH - 1);

    // data valid: asserted whenever a read is requested
    always_comb begin
        if (rst) data_vld_o = 1'b0;
        else     data_vld_o = read_en_i;
    end

    // preload instruction data from hex file
    initial begin
        for (int i = 0; i <= `MEM_DEPTH; i++) begin
            main_memory[i] = 8'h00;
        end
        $readmemh(`MEM_PATH, temp_memory);
        for (int i = 0; i < `LINE_COUNT; i++) begin
            main_memory[4*i]     = temp_memory[i][7:0];
            main_memory[4*i + 1] = temp_memory[i][15:8];
            main_memory[4*i + 2] = temp_memory[i][23:16];
            main_memory[4*i + 3] = temp_memory[i][31:24];
        end
        $display("IMEMORY: Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
    end

    // read logic: size-aware with sign extension
    logic [7:0]  byte_val;
    logic [15:0] half_val;
    logic [31:0] word_val;

    // mask helper for multi-byte indexing
    localparam logic [31:0] MASK = `MEM_DEPTH - 1;

    always_comb begin
        byte_val = main_memory[address];
        half_val = {main_memory[(address + 1) & MASK], main_memory[address]};
        word_val = {main_memory[(address + 3) & MASK], main_memory[(address + 2) & MASK],
                    main_memory[(address + 1) & MASK], main_memory[address]};

        raw_data_o = word_val;

        unique case (funct3_i)
            `F3_BYTE:  data_o = {{24{byte_val[7]}}, byte_val};
            `F3_HALF:  data_o = {{16{half_val[15]}}, half_val};
            `F3_WORD:  data_o = word_val;
            `F3_BYTEU: data_o = {24'b0, byte_val};
            `F3_HALFU: data_o = {16'b0, half_val};
            default:   data_o = word_val;
        endcase
    end

    // write logic: size-aware
    always @(posedge clk) begin
        if (write_en_i) begin
            unique case (funct3_i)
                `F3_BYTE: begin
                    main_memory[address] <= data_i[7:0];
                end
                `F3_HALF: begin
                    main_memory[address]              <= data_i[7:0];
                    main_memory[(address + 1) & MASK] <= data_i[15:8];
                end
                default: begin
                    main_memory[address]              <= data_i[7:0];
                    main_memory[(address + 1) & MASK] <= data_i[15:8];
                    main_memory[(address + 2) & MASK] <= data_i[23:16];
                    main_memory[(address + 3) & MASK] <= data_i[31:24];
                end
            endcase
        end
    end

endmodule : memory
