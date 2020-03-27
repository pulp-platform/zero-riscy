// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

class ibex_icache_driver extends dv_base_driver #(ibex_icache_item, ibex_icache_agent_cfg);
  `uvm_component_utils(ibex_icache_driver)
  `uvm_component_new

  // reset signals
  virtual task automatic reset_signals();
    cfg.vif.reset();
  endtask

  // drive trans received from sequencer
  virtual task automatic get_and_drive();
    forever begin
      seq_item_port.get_next_item(req);
      `uvm_info(`gfn, $sformatf("rcvd item:\n%0s", req.sprint()), UVM_HIGH)

      case (req.trans_type)
        ICacheTransTypeBranch: drive_branch_trans(req);
        ICacheTransTypeReq:    drive_req_trans(req);
        default:               `uvm_fatal(`gfn, "Unknown transaction type")
      endcase

      `uvm_info(`gfn, "item sent", UVM_HIGH)
      seq_item_port.item_done();
    end
  endtask

  // Drive the cache for a "branch" transaction.
  //
  // This concurrently asserts branch with a given address for a cycle while doing the usual
  // (enable/disable, invalidate, read instructions).
  virtual task automatic drive_branch_trans(ibex_icache_item req);
    // Make sure that req is enabled (has no effect unless this is the first transaction)
    cfg.vif.req <= 1'b1;

    fork
        cfg.vif.branch_to(req.branch_addr);
        if (req.toggle_enable) toggle_enable();
        if (req.invalidate) invalidate();
        read_insns(req.num_insns);
    join
  endtask

  // Drive the cache for a "req transaction".
  //
  // This lowers req for zero or more cycles, at the same time as setting the enable pin and (maybe)
  // pulsing the invalidate line. Once that is done, it reads zero or more instructions.
  virtual task automatic drive_req_trans(ibex_icache_item req);
    int unsigned req_low_cycles;
    bit          allow_no_low_cycles;

    // How many cycles should we lower the request line? If there aren't any instructions to read,
    // this is constrained to be positive (to avoid a confusing zero-time transaction).
    allow_no_low_cycles = req.num_insns > 0;
    `DV_CHECK_STD_RANDOMIZE_WITH_FATAL(req_low_cycles,
                                       req_low_cycles dist {
                                           0           :/ (allow_no_low_cycles ? 20 : 0),
                                           [1:33]      :/ 5,
                                           [100:200]   :/ 2,
                                           [1000:1200] :/ 1 };)

    fork
        if (req_low_cycles > 0) lower_req(req_low_cycles);
        if (req.toggle_enable) toggle_enable();
        if (req.invalidate) invalidate();
    join
    read_insns(req.num_insns);
  endtask

  // Toggle whether the cache is enabled
  virtual task automatic toggle_enable();
    cfg.vif.enable <= ~cfg.vif.enable;
  endtask

  // Read up to num_insns instructions from the cache, stopping early on an error
  virtual task automatic read_insns(int num_insns);
    for (int i = 0; i < num_insns; i++) begin
      read_insn();
      // Spot any error and exit early
      if (cfg.vif.err)
        break;
    end
  endtask

  // Read a single instruction from the cache
  virtual task automatic read_insn();
    int unsigned delay;

    // Maybe (1 time in 10) wait for a valid signal before even considering asserting ready.
    if ($urandom_range(9) == 0)
      wait (cfg.vif.valid);

    // Then pick how long we wait before asserting that we are ready.
    //
    // TODO: Make this configurable and weight 0 more heavily.
    cfg.vif.wait_clks($urandom_range(3));

    // Assert ready and then wait until valid
    cfg.vif.ready <= 1'b1;
    while (1'b1) begin
      @(posedge cfg.vif.clk);
      if (cfg.vif.valid)
        break;
    end

    cfg.vif.ready <= 1'b0;
  endtask

  // Lower the req line for the given number of cycles
  virtual task automatic lower_req(int unsigned num_cycles);
    cfg.vif.req <= 1'b0;
    repeat (num_cycles) @(posedge cfg.vif.clk);
    cfg.vif.req <= 1'b1;
  endtask

  // Raise the invalidate line for a randomly chosen number of cycles > 0.
  virtual task automatic invalidate();
    int unsigned num_cycles;
    `DV_CHECK_STD_RANDOMIZE_WITH_FATAL(num_cycles,
                                       num_cycles dist { 0 :/ 499, [1:20] :/ 1 };)
    cfg.vif.invalidate_pulse(num_cycles);
  endtask

endclass
