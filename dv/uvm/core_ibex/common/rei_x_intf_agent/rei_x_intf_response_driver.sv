
// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// CLASS: rei_x_intf_response_driver
//------------------------------------------------------------------------------

class rei_x_intf_response_driver extends uvm_driver #(rei_x_intf_seq_item);

  protected virtual rei_x_intf vif;

  int unsigned max_resp_delay = 35;
  int unsigned min_resp_delay = 0;

  `uvm_component_utils(rei_x_intf_response_driver)
  `uvm_component_new

  rei_x_intf_mailbox_container #(
    .NumMbx(32),
    .msg_t(rei_x_intf_seq_item),
    .idx_t(logic[4:0])
  ) resp_mbx_cnt;

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    resp_mbx_cnt = new();
    if(!uvm_config_db#(virtual rei_x_intf)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    fork
      reset_signals();
      send_responses();
    join
  endtask : run_phase

  virtual protected task reset_signals();
    vif.response_driver_cb.p_valid     <= 'b0;
    vif.response_driver_cb.p_data      <= 'b0;
    vif.response_driver_cb.p_error     <= 'b0;
    vif.response_driver_cb.p_rd        <= 'b0;
    vif.response_driver_cb.p_dualwb    <= 'b0;
  endtask : reset_signals

  virtual protected task send_responses();
    @(negedge vif.response_driver_cb.reset);
    fork
      // get pending responses
    forever begin
      rei_x_intf_seq_item req, req_c;
      seq_item_port.get_next_item(req);
      // TODO : Remove print
      `uvm_info(get_full_name(), $sformatf("[send_responses] got item with instruction: %0x", req.q_instr_data), UVM_LOW)
      $cast(req_c, req.clone());
      req_c.set_id_info(req);
      resp_mbx_cnt.put(req_c, req_c.p_rd);
      seq_item_port.item_done();
    end
    // send in randomized order
    forever begin
      rei_x_intf_seq_item req;
      while(!resp_mbx_cnt.try_get_random(req)) begin
        vif.wait_clks(1);
      end
      send_resp(req);
    end
    join
  endtask

  virtual protected task send_resp(rei_x_intf_seq_item tr);
    int resp_delay;
    // TODO remove print
    `uvm_info(get_full_name(), $sformatf("[send_resp] got item with instruction: %0x", tr.q_instr_data), UVM_LOW)
    // Randomize Delay
    if (!std::randomize(resp_delay) with {
      resp_delay dist {
        min_resp_delay                                : /3,
        [min_resp_delay + 1 : max_resp_delay / 2 - 1] : /4,
        [max_resp_delay / 2 : max_resp_delay - 1]     : /2,
        max_resp_delay                                : /1
      };
    }) begin
      `uvm_fatal(`gfn, $sformatf("Cannot randomize req delay"))
    end
    vif.wait_clks(resp_delay);
    // send resp.
    if(~vif.response_driver_cb.reset) begin
      vif.response_driver_cb.p_valid  <= 1'b1;
      vif.response_driver_cb.p_data   <= tr.p_data;
      vif.response_driver_cb.p_error  <= tr.p_error;
      vif.response_driver_cb.p_rd     <= tr.p_rd;
      if (tr.insn_type == DUAL_WRITEBACK) begin
        vif.response_driver_cb.p_dualwb <= 1'b1;
      end else begin
        vif.response_driver_cb.p_dualwb <= 1'b0;
      end
      vif.wait_clks(1);
      if (!vif.response_driver_cb.p_ready) begin
        @(vif.response_driver_cb iff vif.response_driver_cb.p_ready);
      end
      vif.response_driver_cb.p_valid  <= 1'b0;
      vif.response_driver_cb.p_data   <= 'x;
      vif.response_driver_cb.p_error  <= 'x;
      vif.response_driver_cb.p_rd     <= 'x;
      vif.response_driver_cb.p_dualwb <= 'x;
    end
  endtask : send_resp

endclass : rei_x_intf_response_driver
