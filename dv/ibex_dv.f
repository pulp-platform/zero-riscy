// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

${PRJ_DIR}/ibex/dv/tb/prim_clock_gating.sv

// ibex CORE RTL files
+incdir+${PRJ_DIR}/ibex/rtl
${PRJ_DIR}/ibex/rtl/ibex_defines.sv
${PRJ_DIR}/ibex/rtl/ibex_tracer_defines.sv
${PRJ_DIR}/ibex/rtl/ibex_tracer.sv
${PRJ_DIR}/ibex/rtl/ibex_alu.sv
${PRJ_DIR}/ibex/rtl/ibex_compressed_decoder.sv
${PRJ_DIR}/ibex/rtl/ibex_controller.sv
${PRJ_DIR}/ibex/rtl/ibex_cs_registers.sv
${PRJ_DIR}/ibex/rtl/ibex_decoder.sv
${PRJ_DIR}/ibex/rtl/ibex_int_controller.sv
${PRJ_DIR}/ibex/rtl/ibex_ex_block.sv
${PRJ_DIR}/ibex/rtl/ibex_id_stage.sv
${PRJ_DIR}/ibex/rtl/ibex_if_stage.sv
${PRJ_DIR}/ibex/rtl/ibex_load_store_unit.sv
${PRJ_DIR}/ibex/rtl/ibex_multdiv_slow.sv
${PRJ_DIR}/ibex/rtl/ibex_multdiv_fast.sv
${PRJ_DIR}/ibex/rtl/ibex_prefetch_buffer.sv
${PRJ_DIR}/ibex/rtl/ibex_fetch_fifo.sv
${PRJ_DIR}/ibex/rtl/ibex_register_file_ff.sv
${PRJ_DIR}/ibex/rtl/ibex_core.sv

// Core DV files
+incdir+${PRJ_DIR}/ibex/dv/env
+incdir+${PRJ_DIR}/ibex/dv/tests
+incdir+${PRJ_DIR}/ibex/dv/common/ibex_mem_intf_agent
+incdir+${PRJ_DIR}/ibex/dv/common/mem_model
+incdir+${PRJ_DIR}/ibex/dv/common/utils
${PRJ_DIR}/ibex/dv/common/utils/clk_if.sv
${PRJ_DIR}/ibex/dv/common/utils/dv_utils_pkg.sv
${PRJ_DIR}/ibex/dv/common/mem_model/mem_model_pkg.sv
${PRJ_DIR}/ibex/dv/common/ibex_mem_intf_agent/ibex_mem_intf_agent_pkg.sv
${PRJ_DIR}/ibex/dv/env/core_ibex_env_pkg.sv
${PRJ_DIR}/ibex/dv/tests/core_ibex_test_pkg.sv
${PRJ_DIR}/ibex/dv/tb/core_ibex_tb_top.sv
