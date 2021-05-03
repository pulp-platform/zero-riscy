// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// CLASS: rei_x_intf_monitor
//------------------------------------------------------------------------------

class rei_x_intf_monitor extends uvm_monitor;

  protected virtual rei_x_intf vif;

  rei_x_intf_mailbox_container #(
    .NumMbx(32),
    .msg_t(rei_x_intf_seq_item),
    .idx_t(logic[4:0])
  ) collect_resp_mbx_cnt;
  uvm_analysis_port#(rei_x_intf_seq_item) item_collected_port;
  uvm_analysis_port#(rei_x_intf_seq_item) req_ph_port;
  uvm_analysis_port#(rei_x_intf_seq_item) ack_ph_port;

  `uvm_component_utils(rei_x_intf_monitor)
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port", this);
    req_ph_port = new("req_ph_port_monitor", this);
    ack_ph_port = new("ack_ph_port_monitor", this);
    collect_resp_mbx_cnt = new();
    if(!uvm_config_db#(virtual rei_x_intf)::get(this, "", "vif", vif)) begin
       `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
    end
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    wait (vif.monitor_cb.reset === 1'b0);
    fork : check_rei_x_intf
      collect_req_phase();
      collect_resp_phase();
    join
  endtask : run_phase

  virtual protected task collect_req_phase();
    rei_x_intf_seq_item trans_collected;
    forever begin
      trans_collected = rei_x_intf_seq_item::type_id::create("trans_collected");
      while (~vif.async_monitor.q_valid) begin
        vif.wait_clks(1);
        #1step;
      end
      trans_collected.q_instr_data = vif.async_monitor.q_instr_data;
      req_ph_port.write(trans_collected);
      `uvm_info(get_full_name(), $sformatf("[monitor] Detect request with instruction: %0x",
                trans_collected.q_instr_data), UVM_HIGH)
      if (!(vif.monitor_cb.q_valid & vif.monitor_cb.q_ready)) begin
        @(vif.monitor_cb iff (vif.monitor_cb.q_valid & vif.monitor_cb.q_ready));
      end
      trans_collected.q_rs         = vif.monitor_cb.q_rs;
      if(!vif.monitor_cb.k_accept) begin
        trans_collected.insn_type = ILLEGAL;
        trans_collected.p_data    = 'x;
        trans_collected.p_error   = 'x;
        trans_collected.p_rd      = 'x;
        item_collected_port.write(trans_collected);
      end else if(vif.monitor_cb.k_writeback == 2'b01) begin
        trans_collected.insn_type = SINGLE_WRITEBACK;
        ack_ph_port.write(trans_collected);
      end else if(vif.monitor_cb.k_writeback == 2'b11) begin
        trans_collected.insn_type = DUAL_WRITEBACK;
        ack_ph_port.write(trans_collected);
      end else if(vif.monitor_cb.k_is_mem_op) begin
        // Unsupported, treat the same as no writeback for now.
        trans_collected.insn_type = MEM_OP;
        trans_collected.p_data    = 'x;
        trans_collected.p_error   = 'x;
        trans_collected.p_rd      = 'x;
        item_collected_port.write(trans_collected);
      end else begin
        trans_collected.insn_type = NO_WRITEBACK;
        trans_collected.p_data    = 'x;
        trans_collected.p_error   = 'x;
        trans_collected.p_rd      = 'x;
        item_collected_port.write(trans_collected);
      end
      if( !((trans_collected.insn_type == SINGLE_WRITEBACK) ||
            (trans_collected.insn_type == DUAL_WRITEBACK))) begin
        // Expect no response phase
      end else begin
        collect_resp_mbx_cnt.put(trans_collected, trans_collected.q_instr_data[11:7]);
      end
      vif.wait_clks(1);
      #1step;
    end
  endtask : collect_req_phase

  virtual protected task collect_resp_phase();
    rei_x_intf_seq_item trans_collected;
    forever begin
      // do begin
        // vif.wait_clks(1);
      // end while(!(vif.monitor_cb.p_valid && vif.monitor_cb.p_ready));
      vif.wait_clks(1);
      @(vif.monitor_cb iff (vif.monitor_cb.p_valid && vif.monitor_cb.p_ready));
      collect_resp_mbx_cnt.get(trans_collected, vif.monitor_cb.p_rd);
      trans_collected.p_data    = vif.monitor_cb.p_data;
      trans_collected.p_error   = vif.monitor_cb.p_error;
      trans_collected.p_rd      = vif.monitor_cb.p_rd;
      item_collected_port.write(trans_collected);
    end
  endtask : collect_resp_phase

endclass : rei_x_intf_monitor
