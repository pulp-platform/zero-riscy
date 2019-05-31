// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// CLASS: ibex_mem_intf_monitor
//------------------------------------------------------------------------------

class ibex_mem_intf_monitor extends uvm_monitor;

  protected virtual ibex_mem_intf vif;

  mailbox #(ibex_mem_intf_seq_item)          collect_data_queue;
  uvm_analysis_port#(ibex_mem_intf_seq_item) item_collected_port;
  uvm_analysis_port#(ibex_mem_intf_seq_item) addr_ph_port;

  `uvm_component_utils(ibex_mem_intf_monitor)
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port", this);
    addr_ph_port = new("addr_ph_port_monitor", this);
    collect_data_queue = new();
    if(!uvm_config_db#(virtual ibex_mem_intf)::get(this, "", "vif", vif)) begin
       `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    end
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    wait(vif.reset === 1'b0);
    fork
      collect_address_phase();
      collect_data_phase();
    join
  endtask : run_phase

  virtual protected task collect_address_phase();
    ibex_mem_intf_seq_item trans_collected;
    forever begin
      trans_collected = ibex_mem_intf_seq_item::type_id::create("trans_collected");
      while(!(vif.request && vif.grant)) @(posedge vif.clock);
      trans_collected.addr = vif.addr;
      trans_collected.be   = vif.be;
      `uvm_info(get_full_name(), $sformatf("Detect request with address: %0x",
                trans_collected.addr), UVM_HIGH)
      if(vif.we) begin
        trans_collected.read_write = WRITE;
        trans_collected.data = vif.wdata;
      end else begin
        trans_collected.read_write = READ;
      end
      addr_ph_port.write(trans_collected);
      `uvm_info(get_full_name(),"Send through addr_ph_port", UVM_HIGH)
      if(trans_collected.read_write == WRITE)
        item_collected_port.write(trans_collected);
      else
        collect_data_queue.put(trans_collected);
      @(posedge vif.clock);
    end
  endtask : collect_address_phase

  virtual protected task collect_data_phase();
    ibex_mem_intf_seq_item trans_collected;
    forever begin
      collect_data_queue.get(trans_collected);
      do
        @(posedge vif.clock);
      while(vif.rvalid === 0);
      trans_collected.data = vif.rdata;
      item_collected_port.write(trans_collected);
    end
  endtask : collect_data_phase

endclass : ibex_mem_intf_monitor
