// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// CLASS: rei_x_intf_response_agent
//------------------------------------------------------------------------------

class rei_x_intf_response_agent extends uvm_agent;

  rei_x_intf_response_driver     driver;
  rei_x_intf_response_sequencer  sequencer;
  rei_x_intf_monitor             monitor;

  `uvm_component_utils(rei_x_intf_response_agent)
  `uvm_component_new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = rei_x_intf_monitor::type_id::create("monitor", this);
    if(get_is_active() == UVM_ACTIVE) begin
      driver = rei_x_intf_response_driver::type_id::create("driver", this);
      sequencer = rei_x_intf_response_sequencer::type_id::create("sequencer", this);
    end
  endfunction : build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
      monitor.ack_ph_port.connect(sequencer.ack_ph_port.analysis_export);
    end
  endfunction : connect_phase

  function void reset();
    sequencer.reset();
  endfunction

endclass : rei_x_intf_response_agent
