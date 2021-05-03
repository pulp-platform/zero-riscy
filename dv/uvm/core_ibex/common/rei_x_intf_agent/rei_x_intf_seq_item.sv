// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// CLASS: rei_x_intf_seq_item
//------------------------------------------------------------------------------

class rei_x_intf_seq_item extends uvm_sequence_item;

  rand bit [31:0]                q_instr_data;
  rand bit [2:0][DATA_WIDTH-1:0] q_rs;
  rand acc_e                     insn_type;
  rand bit [1:0][DATA_WIDTH-1:0] p_data;
  rand bit                       p_error;
  rand bit [4:0]                 p_rd;
  rand bit [2:0]                 use_rs;


  `uvm_object_utils_begin(rei_x_intf_seq_item)
    `uvm_field_int      (q_instr_data,     UVM_DEFAULT)
    `uvm_field_int      (q_rs,             UVM_DEFAULT)
    `uvm_field_enum     (acc_e, insn_type, UVM_DEFAULT)
    `uvm_field_int      (p_data,           UVM_DEFAULT)
    `uvm_field_int      (p_error,          UVM_DEFAULT)
    `uvm_field_int      (p_rd,             UVM_DEFAULT)
    `uvm_field_int      (use_rs,           UVM_DEFAULT)
  `uvm_object_utils_end

  `uvm_object_new

endclass : rei_x_intf_seq_item
