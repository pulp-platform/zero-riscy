// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

module core_ibex_tb_top;

  import uvm_pkg::*;
  import core_ibex_test_pkg::*;

  wire clk;
  wire rst_n;
  logic fetch_enable;

  clk_rst_if     ibex_clk_if(.clk(clk), .rst_n(rst_n));
  irq_if         irq_vif(.clk(clk));
  ibex_mem_intf  data_mem_vif(.clk(clk));
  ibex_mem_intf  instr_mem_vif(.clk(clk));
  rei_x_intf     rei_x_intf_vif(.clk(clk));

  // DUT probe interface
  core_ibex_dut_probe_if dut_if(.clk(clk));

  // Instruction monitor interface
  core_ibex_instr_monitor_if instr_monitor_if(.clk(clk));

  // RVFI interface
  core_ibex_rvfi_if rvfi_if(.clk(clk));

  // CSR access interface
  core_ibex_csr_if csr_if(.clk(clk));

  // VCS does not support overriding enum and string parameters via command line. Instead, a
  // `define is used that can be set from the command line. If no value has been specified, this
  // gives a default. Other simulators don't take the detour via `define and can override the
  // corresponding parameters directly.
  `ifndef IBEX_CFG_RV32M
    `define IBEX_CFG_RV32M ibex_pkg::RV32MFast
  `endif

  `ifndef IBEX_CFG_RV32B
    `define IBEX_CFG_RV32B ibex_pkg::RV32BNone
  `endif

  `ifndef IBEX_CFG_RegFile
    `define IBEX_CFG_RegFile ibex_pkg::RegFileFF
  `endif

  parameter bit          PMPEnable      = 1'b0;
  parameter int unsigned PMPGranularity = 0;
  parameter int unsigned PMPNumRegions  = 4;
  parameter bit RV32E                   = 1'b0;
  parameter ibex_pkg::rv32m_e RV32M     = `IBEX_CFG_RV32M;
  parameter ibex_pkg::rv32b_e RV32B     = `IBEX_CFG_RV32B;
  parameter ibex_pkg::regfile_e RegFile = `IBEX_CFG_RegFile;
  parameter bit BranchTargetALU         = 1'b0;
  parameter bit WritebackStage          = 1'b0;
  parameter bit ICache                  = 1'b0;
  parameter bit ICacheECC               = 1'b0;
  parameter bit BranchPredictor         = 1'b0;
  parameter bit XInterface              = 1'b0;
  parameter bit XInterfaceTernaryOps    = 1'b0;

  logic [31:0] hart_id;
  assign hart_id = 32'h0;

  ibex_top_tracing #(
    .DmHaltAddr           ( 32'h`BOOT_ADDR + 'h0 ),
    .DmExceptionAddr      ( 32'h`BOOT_ADDR + 'h4 ),
    .PMPEnable            ( PMPEnable            ),
    .PMPGranularity       ( PMPGranularity       ),
    .PMPNumRegions        ( PMPNumRegions        ),
    .RV32E                ( RV32E                ),
    .RV32M                ( RV32M                ),
    .RV32B                ( RV32B                ),
    .RegFile              ( RegFile              ),
    .BranchTargetALU      ( BranchTargetALU      ),
    .WritebackStage       ( WritebackStage       ),
    .ICache               ( ICache               ),
    .ICacheECC            ( ICacheECC            ),
    .BranchPredictor      ( BranchPredictor      ),
    .XInterface           ( XInterface           ),
    .XInterfaceTernaryOps ( XInterfaceTernaryOps )
  ) dut (
    .clk_i                (clk                  ),
    .rst_ni               (rst_n                ),

    .test_en_i            (1'b0                 ),
    .scan_rst_ni          (1'b1                 ),
    .ram_cfg_i            ('b0                  ),

    .hart_id_i            (hart_id              ),
    .boot_addr_i          (32'h`BOOT_ADDR       ), // align with spike boot address

    .instr_req_o          (instr_mem_vif.request),
    .instr_gnt_i          (instr_mem_vif.grant  ),
    .instr_rvalid_i       (instr_mem_vif.rvalid ),
    .instr_addr_o         (instr_mem_vif.addr   ),
    .instr_rdata_i        (instr_mem_vif.rdata  ),
    .instr_err_i          (instr_mem_vif.error  ),

    .data_req_o           (data_mem_vif.request ),
    .data_gnt_i           (data_mem_vif.grant   ),
    .data_rvalid_i        (data_mem_vif.rvalid  ),
    .data_addr_o          (data_mem_vif.addr    ),
    .data_we_o            (data_mem_vif.we      ),
    .data_be_o            (data_mem_vif.be      ),
    .data_rdata_i         (data_mem_vif.rdata   ),
    .data_wdata_o         (data_mem_vif.wdata   ),
    .data_err_i           (data_mem_vif.error   ),

    .irq_software_i       (irq_vif.irq_software ),
    .irq_timer_i          (irq_vif.irq_timer    ),
    .irq_external_i       (irq_vif.irq_external ),
    .irq_fast_i           (irq_vif.irq_fast     ),
    .irq_nm_i             (irq_vif.irq_nm       ),

    .acc_x_q_valid_o      (rei_x_intf_vif.q_valid        ),
    .acc_x_q_ready_i      (rei_x_intf_vif.q_ready        ),
    .acc_x_q_instr_data_o (rei_x_intf_vif.q_instr_data   ),
    .acc_x_q_rs1_o        (rei_x_intf_vif.q_rs[0]          ),
    .acc_x_q_rs2_o        (rei_x_intf_vif.q_rs[1]          ),
    .acc_x_q_rs3_o        (rei_x_intf_vif.q_rs[2]          ),
    .acc_x_q_rs_valid_o   (rei_x_intf_vif.q_rs_valid     ),
    .acc_x_q_rd_clean_o   (rei_x_intf_vif.q_rd_clean[0]  ),
    .acc_x_k_writeback_i  (rei_x_intf_vif.k_writeback    ),
    .acc_x_k_is_mem_op_i  (rei_x_intf_vif.k_is_mem_op    ),
    .acc_x_k_accept_i     (rei_x_intf_vif.k_accept       ),

    .acc_x_p_valid_i      (rei_x_intf_vif.p_valid        ),
    .acc_x_p_ready_o      (rei_x_intf_vif.p_ready        ),
    .acc_x_p_rd_i         (rei_x_intf_vif.p_rd           ),
    .acc_x_p_data_i       (rei_x_intf_vif.p_data[0]      ),
    .acc_x_p_error_i      (rei_x_intf_vif.p_error        ),

    .debug_req_i          (dut_if.debug_req     ),
    .crash_dump_o         (                     ),

    .fetch_enable_i       (dut_if.fetch_enable  ),
    .alert_minor_o        (dut_if.alert_minor   ),
    .alert_major_o        (dut_if.alert_major   ),
    .core_sleep_o         (dut_if.core_sleep    )
  );

  // TODO: Get this into core ?
  logic        unused_acc_x_k_writeback_1;
  logic        unused_acc_x_p_dualwb;
  logic [31:0] unused_acc_x_p_data_1;

  assign unused_acc_x_p_dualwb        = rei_x_intf_vif.p_dualwb;
  assign unused_acc_x_k_writeback_1   = rei_x_intf_vif.k_writeback[1];
  assign unused_acc_x_p_data_1        = rei_x_intf_vif.p_data[1];
  assign rei_x_intf_vif.q_rd_clean[1] = 1'b0;



  // Data load/store vif connection
  assign data_mem_vif.reset                   = ~rst_n;
  // Instruction fetch vif connnection
  assign instr_mem_vif.reset                  = ~rst_n;
  assign rei_x_intf_vif.reset                   = ~rst_n;
  assign instr_mem_vif.we                     = 0;
  assign instr_mem_vif.be                     = 0;
  assign instr_mem_vif.wdata                  = 0;
  // RVFI interface connections
  assign rvfi_if.valid                        = dut.rvfi_valid;
  assign rvfi_if.order                        = dut.rvfi_order;
  assign rvfi_if.insn                         = dut.rvfi_insn;
  assign rvfi_if.trap                         = dut.rvfi_trap;
  assign rvfi_if.intr                         = dut.rvfi_intr;
  assign rvfi_if.mode                         = dut.rvfi_mode;
  assign rvfi_if.ixl                          = dut.rvfi_ixl;
  assign rvfi_if.rs1_addr                     = dut.rvfi_rs1_addr;
  assign rvfi_if.rs2_addr                     = dut.rvfi_rs2_addr;
  assign rvfi_if.rs1_rdata                    = dut.rvfi_rs1_rdata;
  assign rvfi_if.rs2_rdata                    = dut.rvfi_rs2_rdata;
  assign rvfi_if.rd_addr                      = dut.rvfi_rd_addr;
  assign rvfi_if.rd_wdata                     = dut.rvfi_rd_wdata;
  assign rvfi_if.pc_rdata                     = dut.rvfi_pc_rdata;
  assign rvfi_if_pc_wdata                     = dut.rvfi_pc_wdata;
  assign rvfi_if.mem_addr                     = dut.rvfi_mem_addr;
  assign rvfi_if.mem_rmask                    = dut.rvfi_mem_rmask;
  assign rvfi_if.mem_rdata                    = dut.rvfi_mem_rdata;
  assign rvfi_if.mem_wdata                    = dut.rvfi_mem_wdata;
  // Irq interface connections
  assign irq_vif.reset                        = ~rst_n;
  // Dut_if interface connections
  assign dut_if.ecall                         = dut.u_ibex_top.u_ibex_core.id_stage_i.controller_i.ecall_insn;
  assign dut_if.wfi                           = dut.u_ibex_top.u_ibex_core.id_stage_i.controller_i.wfi_insn;
  assign dut_if.ebreak                        = dut.u_ibex_top.u_ibex_core.id_stage_i.controller_i.ebrk_insn;
  assign dut_if.illegal_instr                 = dut.u_ibex_top.u_ibex_core.id_stage_i.controller_i.illegal_insn_d;
  assign dut_if.dret                          = dut.u_ibex_top.u_ibex_core.id_stage_i.controller_i.dret_insn;
  assign dut_if.mret                          = dut.u_ibex_top.u_ibex_core.id_stage_i.controller_i.mret_insn;
  assign dut_if.reset                         = ~rst_n;
  assign dut_if.priv_mode                     = dut.u_ibex_top.u_ibex_core.priv_mode_id;
  // Instruction monitor connections
  assign instr_monitor_if.valid_id            = dut.u_ibex_top.u_ibex_core.id_stage_i.instr_valid_i;
  assign instr_monitor_if.err_id              = dut.u_ibex_top.u_ibex_core.id_stage_i.controller_i.instr_fetch_err;
  assign instr_monitor_if.is_compressed_id    = dut.u_ibex_top.u_ibex_core.id_stage_i.instr_is_compressed_i;
  assign instr_monitor_if.instr_compressed_id = dut.u_ibex_top.u_ibex_core.id_stage_i.instr_rdata_c_i;
  assign instr_monitor_if.instr_id            = dut.u_ibex_top.u_ibex_core.id_stage_i.instr_rdata_i;
  assign instr_monitor_if.pc_id               = dut.u_ibex_top.u_ibex_core.pc_id;
  assign instr_monitor_if.branch_taken_id     = dut.u_ibex_top.u_ibex_core.id_stage_i.controller_i.branch_set_i;
  assign instr_monitor_if.branch_target_id    = dut.u_ibex_top.u_ibex_core.branch_target_ex;
  assign instr_monitor_if.stall_id            = dut.u_ibex_top.u_ibex_core.id_stage_i.stall_id;
  assign instr_monitor_if.jump_set_id         = dut.u_ibex_top.u_ibex_core.id_stage_i.jump_set;
  // CSR interface connections
  assign csr_if.csr_access                    = dut.u_ibex_top.u_ibex_core.csr_access;
  assign csr_if.csr_addr                      = dut.u_ibex_top.u_ibex_core.csr_addr;
  assign csr_if.csr_wdata                     = dut.u_ibex_top.u_ibex_core.csr_wdata;
  assign csr_if.csr_rdata                     = dut.u_ibex_top.u_ibex_core.csr_rdata;
  assign csr_if.csr_op                        = dut.u_ibex_top.u_ibex_core.csr_op;

  initial begin
    // Drive the clock and reset lines. Reset everything and start the clock at the beginning of
    // time
    ibex_clk_if.set_active();
    fork
      ibex_clk_if.apply_reset(.reset_width_clks (100));
    join_none

    uvm_config_db#(virtual clk_rst_if)::set(null, "*", "clk_if", ibex_clk_if);
    uvm_config_db#(virtual core_ibex_dut_probe_if)::set(null, "*", "dut_if", dut_if);
    uvm_config_db#(virtual core_ibex_instr_monitor_if)::set(null,
                                                            "*",
                                                            "instr_monitor_if",
                                                            instr_monitor_if);
    uvm_config_db#(virtual core_ibex_csr_if)::set(null, "*", "csr_if", csr_if);
    uvm_config_db#(virtual core_ibex_rvfi_if)::set(null, "*", "rvfi_if", rvfi_if);
    uvm_config_db#(virtual ibex_mem_intf)::set(null, "*data_if_response*", "vif", data_mem_vif);
    uvm_config_db#(virtual ibex_mem_intf)::set(null, "*instr_if_response*", "vif", instr_mem_vif);
    uvm_config_db#(virtual rei_x_intf)::set(null, "*rei_x_if_response*", "vif", rei_x_intf_vif);
    uvm_config_db#(virtual rei_x_intf)::set(null, "*rei_x_if_ack*", "vif", rei_x_intf_vif);
    uvm_config_db#(virtual irq_if)::set(null, "*", "vif", irq_vif);
    run_test();
  end

  endmodule
