// ----  Probes  ----
`define PROBE_F_PC          f_pc
`define PROBE_F_INSN        f_insn

`define PROBE_D_PC          d_pc_probe
`define PROBE_D_OPCODE      d_opcode_probe
`define PROBE_D_RD          d_rd_probe
`define PROBE_D_FUNCT3      d_funct3_probe
`define PROBE_D_RS1         d_rs1_probe
`define PROBE_D_RS2         d_rs2_probe
`define PROBE_D_FUNCT7      d_funct7_probe
`define PROBE_D_IMM         d_imm_probe
`define PROBE_D_SHAMT       d_shamt_probe

`define PROBE_R_WRITE_ENABLE      memwb_regwren
`define PROBE_R_WRITE_DESTINATION memwb_rd
`define PROBE_R_WRITE_DATA        wb_data
`define PROBE_R_READ_RS1          d_rs1
`define PROBE_R_READ_RS2          d_rs2
`define PROBE_R_READ_RS1_DATA     d_rs1_data
`define PROBE_R_READ_RS2_DATA     d_rs2_data

`define PROBE_E_PC                e_pc_probe
`define PROBE_E_ALU_RES           e_alu_res_probe
`define PROBE_E_BR_TAKEN          e_br_taken_probe

`define PROBE_M_PC                m_pc_probe
`define PROBE_M_ADDRESS           m_address_probe
`define PROBE_M_SIZE_ENCODED      m_size_encoded
`define PROBE_M_DATA              m_data_probe

`define PROBE_W_PC                w_pc_probe
`define PROBE_W_ENABLE            w_enable_probe
`define PROBE_W_DESTINATION       w_destination_probe
`define PROBE_W_DATA              w_data_probe

// ----  Probes  ----

// ----  Top module  ----
`define TOP_MODULE  pd5 
// ----  Top module  ----
