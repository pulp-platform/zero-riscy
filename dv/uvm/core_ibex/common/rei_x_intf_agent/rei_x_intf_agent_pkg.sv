// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

package rei_x_intf_agent_pkg;

  import uvm_pkg::*;

  parameter int DATA_WIDTH = 32;

  typedef enum { ILLEGAL, SINGLE_WRITEBACK, DUAL_WRITEBACK, NO_WRITEBACK, MEM_OP } acc_e;

  `include "uvm_macros.svh"
  `include "rei_x_intf_seq_item.sv"

  typedef uvm_sequencer#(rei_x_intf_seq_item) rei_x_intf_request_sequencer;

  `include "rei_x_intf_mailbox_container.sv"
  `include "rei_x_intf_monitor.sv"
  `include "rei_x_intf_response_driver.sv"
  `include "rei_x_intf_response_sequencer.sv"
  `include "rei_x_intf_response_seq_lib.sv"
  `include "rei_x_intf_response_agent.sv"
  `include "rei_x_intf_ack_driver.sv"
  `include "rei_x_intf_ack_sequencer.sv"
  `include "rei_x_intf_ack_seq_lib.sv"
  `include "rei_x_intf_ack_agent.sv"
  `include "rei_x_intf_request_driver.sv"
  `include "rei_x_intf_request_agent.sv"

endpackage
