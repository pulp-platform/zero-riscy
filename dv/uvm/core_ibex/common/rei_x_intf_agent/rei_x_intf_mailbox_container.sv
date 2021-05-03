
// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// CLASS: rei_x_intf_mailbox_container
//------------------------------------------------------------------------------

  // Mailbox Container:
  //
  // Maintain an associative array of mailboxes using similar syntax
  // as regular mailboxes.
  class rei_x_intf_mailbox_container #(
    parameter int  NumMbx = -1,
    parameter type msg_t  = logic,
    parameter type idx_t  = logic
  );
    localparam idx_pointer_width = NumMbx == 1 ? 1 : $clog2(NumMbx);
    mailbox mbx[NumMbx];
    int unsigned mbx_pointer[idx_t];
    int unsigned mbx_next = 0;
    int unsigned idx_pointer[logic[idx_pointer_width-1:0]];

    // This event is triggered once a mailbox is assigned an identifier
    // `get` functions waiting for specific mailboxes must wait for
    // this assignement to happen.
    event e_mbx_assigned [logic[31:0]];

    function new;
      foreach (mbx[ii]) mbx[ii] = new;
    endfunction

    function automatic event new_event();
      event e;
      return e;
    endfunction

    task put(input msg_t msg, input idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        if(!e_mbx_assigned.exists(idx)) begin
          this.e_mbx_assigned[idx] = new_event();
        end
        assert(mbx_next <= NumMbx);
        mbx_pointer[idx] = mbx_next;
        idx_pointer[mbx_next] = idx;
        -> e_mbx_assigned[idx];
        mbx_next++;
      end
      mbx[mbx_pointer[idx]].put(msg);
    endtask

    function automatic int num(idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        return 0;
      end else begin
        return mbx[mbx_pointer[idx]].num();
      end
    endfunction

    function automatic int num_direct(int i);
      assert(i < NumMbx);
      return mbx[i].num();
    endfunction

    task get(output msg_t msg, input idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        if(!e_mbx_assigned.exists(idx)) begin
          this.e_mbx_assigned[idx] = new_event();
        end
        @(e_mbx_assigned[idx]);
        assert(mbx_pointer.exists(idx));
      end
      mbx[mbx_pointer[idx]].get(msg);
    endtask

    task get_direct(output msg_t msg, input int i);
      assert(i < NumMbx);
      mbx[i].get(msg);
    endtask

    task peek(output msg_t msg, input idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        @(e_mbx_assigned[idx]);
        assert(mbx_pointer.exists(idx));
      end
      msg=new;
      mbx[mbx_pointer[idx]].peek(msg);
    endtask

    task peek_direct(output msg_t msg, input int i);
      assert(i < NumMbx);
      mbx[i].peek(msg);
    endtask

    function try_get(output msg_t msg, input idx_t idx);
      if (!mbx_pointer.exists(idx)) begin
        return 0;
      end
      return mbx[mbx_pointer[idx]].try_get(msg);
    endfunction

    function try_get_direct(output msg_t msg, input int i);
      assert(i < NumMbx);
      return mbx[i].try_get(msg);
    endfunction

    // try_get message from random mailbox, if any.
    function automatic bit try_get_random(output msg_t msg);
      automatic int mbx_id[NumMbx];
      automatic bit msg_found = 1'b0;
      for (int i = 0; i < NumMbx; i++) begin
        mbx_id[i] = i;
      end
      mbx_id.shuffle();
      for (int i = 0; i < NumMbx; i++) begin
        if(idx_pointer.exists(mbx_id[i])) begin
          msg_found |= try_get(msg, idx_pointer[mbx_id[i]]);
        end
        if (msg_found) break;
      end
      return msg_found;
    endfunction

    function automatic bit empty();
      automatic bit result = 1;
      for (int i = 0; i < NumMbx; i++) begin
        result &= (mbx[i].num() == 0);
      end
      return result;
    endfunction

  endclass
