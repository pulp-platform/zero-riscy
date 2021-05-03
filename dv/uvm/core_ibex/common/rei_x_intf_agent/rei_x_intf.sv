// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

interface rei_x_intf#(
  parameter int DATA_WIDTH = 32
) (
  input clk
);
  wire                       reset;
  wire [31:0]                q_instr_data;
  wire [2:0][DATA_WIDTH-1:0] q_rs;
  wire [2:0]                 q_rs_valid;
  wire [1:0]                 q_rd_clean;
  wire                       q_valid;
  wire                       k_accept;
  wire [1:0]                 k_writeback;
  wire                       k_is_mem_op;
  wire                       q_ready;
  wire [1:0][DATA_WIDTH-1:0] p_data;
  wire                       p_error;
  wire [4:0]                 p_rd;
  wire                       p_dualwb;
  wire                       p_valid;
  wire                       p_ready;

  clocking request_driver_cb @(posedge clk);
    default input #1step output #0;
    input  reset;
    output q_instr_data;
    output q_rs;
    output q_rs_valid;
    output q_rd_clean;
    output q_valid;
    input  k_accept;
    input  k_writeback;
    input  k_is_mem_op;
    input  q_ready;
    input  p_data;
    input  p_error;
    input  p_rd;
    input  p_dualwb;
    input  p_valid;
    output p_ready;
  endclocking

  clocking response_driver_cb @(posedge clk);
    default input #1step output #0;
    input  reset;
    output p_data;
    output p_error;
    output p_rd;
    output p_dualwb;
    output p_valid;
    input  p_ready;
  endclocking

  modport async_ack_driver(
    input  reset,
    input  q_instr_data,
    input  q_rs,
    input  q_rs_valid,
    input  q_rd_clean,
    input  q_valid,
    output k_accept,
    output k_writeback,
    output k_is_mem_op,
    output q_ready
  );

   clocking monitor_cb @(posedge clk);
    default input #1step output #0;
    input reset;
    input q_instr_data;
    input q_rs;
    input q_rs_valid;
    input q_rd_clean;
    input q_valid;
    input k_accept;
    input k_writeback;
    input k_is_mem_op;
    input q_ready;
    input p_data;
    input p_error;
    input p_rd;
    input p_dualwb;
    input p_valid;
    input p_ready;
  endclocking

  modport async_monitor (
    input reset,
    input q_instr_data,
    input q_rs,
    input q_rs_valid,
    input q_rd_clean,
    input q_valid,
    input k_accept,
    input k_writeback,
    input k_is_mem_op,
    input q_ready,
    input p_data,
    input p_error,
    input p_rd,
    input p_dualwb,
    input p_valid,
    input p_ready
  );


  task automatic wait_clks(input int num);
    repeat (num) @(posedge clk);
  endtask

  task automatic wait_neg_clks(input int num);
    repeat (num) @(negedge clk);
  endtask

endinterface
