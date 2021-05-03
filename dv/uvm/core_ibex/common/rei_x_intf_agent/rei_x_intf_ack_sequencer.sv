// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// CLASS: rei_x_intf_ack_sequencer
//------------------------------------------------------------------------------

class rei_x_intf_ack_sequencer extends uvm_sequencer #(rei_x_intf_seq_item);

  // TLM port to peek the request phase from the ack monitor
  uvm_tlm_analysis_fifo #(rei_x_intf_seq_item) req_ph_port;

  `uvm_component_utils(rei_x_intf_ack_sequencer)

  function new (string name, uvm_component parent);
    super.new(name, parent);
    req_ph_port = new("req_ph_port_sequencer", this);
  endfunction : new

  // On reset, empty the tlm fifo
  function void reset();
    req_ph_port.flush();
  endfunction

endclass : rei_x_intf_ack_sequencer
