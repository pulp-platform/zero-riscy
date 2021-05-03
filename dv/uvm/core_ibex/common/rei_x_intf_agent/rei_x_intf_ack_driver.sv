// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// CLASS: rei_x_intf_ack_driver
//------------------------------------------------------------------------------

class rei_x_intf_ack_driver extends uvm_driver #(rei_x_intf_seq_item);

  protected virtual rei_x_intf vif;

  int unsigned min_ack_delay = 0;
  int unsigned max_ack_delay = 10;

  `uvm_component_utils(rei_x_intf_ack_driver)
  `uvm_component_new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual rei_x_intf)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    fork
      reset_signals();
      send_acks();
    join
  endtask : run_phase

  virtual protected task reset_signals();
    vif.async_ack_driver.q_ready     <= 'b0;
    vif.async_ack_driver.k_writeback <= 'b0;
    vif.async_ack_driver.k_is_mem_op <= 'b0;
    vif.async_ack_driver.k_accept    <= 'b0;
  endtask : reset_signals

  virtual protected task send_acks();
    @(negedge vif.response_driver_cb.reset);
    forever begin
      rei_x_intf_seq_item req, req_c;
      seq_item_port.get_next_item(req);
      $cast(req_c, req.clone());
      req_c.set_id_info(req);
      send_ack(req_c);
      seq_item_port.item_done();
    end
  endtask : send_acks

  virtual protected task send_ack(rei_x_intf_seq_item tr);
    int ack_delay;
    vif.async_ack_driver.q_ready     <= 1'b0;
    vif.async_ack_driver.k_accept    <= 1'b0;
    vif.async_ack_driver.k_writeback <= 2'b0;
    vif.async_ack_driver.k_is_mem_op <= 1'b0;
    // Randomize Delay
    if (!std::randomize(ack_delay) with {
      ack_delay dist {
        min_ack_delay                         :/ 5,
        [min_ack_delay+1 : max_ack_delay-1]   :/ 4,
        max_ack_delay                         :/ 1
      };
    }) begin
      `uvm_fatal(`gfn, $sformatf("Cannot randomize ack"))
    end
    vif.wait_clks(ack_delay);

    // send ack.
    if(~vif.response_driver_cb.reset) begin
      while (!(((tr.use_rs ~^ vif.async_ack_driver.q_rs_valid) | ~tr.use_rs) == '1)) begin
        vif.wait_clks(1);
        #1step;
      end
      if (tr.insn_type == SINGLE_WRITEBACK) begin
        while (!(vif.async_ack_driver.q_rd_clean[0])) begin
          vif.wait_clks(1);
          #1step;
        end
        vif.async_ack_driver.q_ready     <= 1'b1;
        vif.async_ack_driver.k_accept    <= 1'b1;
        vif.async_ack_driver.k_writeback <= 2'b01;
        vif.async_ack_driver.k_is_mem_op <= 1'b0;
      end else if (tr.insn_type == DUAL_WRITEBACK) begin
        while (! (vif.async_ack_driver.q_rd_clean == 2'b11)) begin
          vif.wait_clks(1);
          #1step;
        end
        vif.async_ack_driver.q_ready     <= 1'b1;
        vif.async_ack_driver.k_accept    <= 1'b1;
        vif.async_ack_driver.k_writeback <= 2'b11;
        vif.async_ack_driver.k_is_mem_op <= 1'b0;
      end else if (tr.insn_type == MEM_OP) begin
        vif.async_ack_driver.q_ready <= 1'b1;
        // Unsupported for now.
        vif.async_ack_driver.k_accept    <= 1'b1;
        vif.async_ack_driver.k_writeback <= 2'b00;
        vif.async_ack_driver.k_is_mem_op <= 1'b1;
      end else if (tr.insn_type == NO_WRITEBACK) begin
        vif.async_ack_driver.q_ready     <= 1'b1;
        vif.async_ack_driver.k_accept    <= 1'b1;
        vif.async_ack_driver.k_writeback <= 2'b00;
        vif.async_ack_driver.k_is_mem_op <= 1'b0;
      end else if (tr.insn_type == ILLEGAL) begin
        vif.async_ack_driver.q_ready     <= 1'b1;
        vif.async_ack_driver.k_accept    <= 1'b0;
        vif.async_ack_driver.k_writeback <= 2'b00;
        vif.async_ack_driver.k_is_mem_op <= 1'b0;
      end else begin
        `uvm_fatal(`gfn, $sformatf("Unknown transaction type"))
      end
      vif.wait_clks(1);
      #1step
      vif.async_ack_driver.q_ready <= 1'b0;
    end
  endtask : send_ack

endclass : rei_x_intf_ack_driver
