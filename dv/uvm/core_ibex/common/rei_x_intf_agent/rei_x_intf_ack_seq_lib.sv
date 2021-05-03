// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// SEQUENCE: rei_x_intf_ack_seq
//------------------------------------------------------------------------------

// The X Interface sequence lib emulates the RV32B_zbb_zbt extension.
// This covers instructions using different combinations of source registers.
// Only SINGLE_WRITEBACK instructions are covered so far.
//
// - DUAL_WRITEBACK functionality is not yet supported by Ibex
// - MEM_OP functionality is not yet supported by Ibex.
// - NO_WRITEBACK instructions are supported, but not used: This implies an
//   accelerator which maintains an internal architectural state. The obvious
//   choice would be the F extension. however, this requires MEM_OP support,
//   which is not yet implemented for Ibex.

class rei_x_intf_ack_seq extends uvm_sequence #(rei_x_intf_seq_item);

  rei_x_intf_seq_item item;

  `uvm_object_utils(rei_x_intf_ack_seq)
  `uvm_declare_p_sequencer(rei_x_intf_ack_sequencer)
  `uvm_object_new

  virtual task body();
    forever begin
      logic [5:0] shamt;
      // get request from req monitor
      p_sequencer.req_ph_port.get(item);
      // set known fields.
      req              = rei_x_intf_seq_item::type_id::create("req");
      req.q_instr_data = item.q_instr_data;
      req.q_rs         = item.q_rs;
      req.p_error      = 1'b0;                        // No errors as of yet. (no MEM_OP)
      req.p_rd         = item.q_instr_data[11:7];
      req.p_data[1]    = '0;                          // No DUAL_WRITEBACK instrucitons

      // Emulate the rv32b_zbb_zbt extension:
      casez (item.q_instr_data)
        32'b 0100000_zzzzz_zzzzz_111_zzzzz_0110011: begin // ANDN
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0100000_zzzzz_zzzzz_110_zzzzz_0110011: begin // ORN
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0100000_zzzzz_zzzzz_100_zzzzz_0110011: begin // XNOR
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0010000_zzzzz_zzzzz_001_zzzzz_0110011: begin // SLO
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0010000_zzzzz_zzzzz_101_zzzzz_0110011: begin // SRO
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0110000_zzzzz_zzzzz_001_zzzzz_0110011: begin // ROL
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0110000_zzzzz_zzzzz_101_zzzzz_0110011: begin // ROR
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 00100_00zzzzz_zzzzz_001_zzzzz_0010011: begin // SLOI (RV32)
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b 00100_00zzzzz_zzzzz_101_zzzzz_0010011: begin // SROI (RV32)
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b 01100_00zzzzz_zzzzz_101_zzzzz_0010011: begin // RORI (RV32)
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b zzzzz11_zzzzz_zzzzz_001_zzzzz_0110011: begin // CMIX
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b111;
        end
        32'b zzzzz11_zzzzz_zzzzz_101_zzzzz_0110011: begin // CMOV
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b111;
        end
        32'b zzzzz10_zzzzz_zzzzz_001_zzzzz_0110011: begin // FSL
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b111;
        end
        32'b zzzzz10_zzzzz_zzzzz_101_zzzzz_0110011: begin // FSR
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b111;
        end
        32'b zzzzz1_0zzzzz_zzzzz_101_zzzzz_0010011: begin // FSRI (RV32)
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b101;
        end
        32'b 0110000_00000_zzzzz_001_zzzzz_0010011: begin // CLZ
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b 0110000_00001_zzzzz_001_zzzzz_0010011: begin // CTZ
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b 0110000_00010_zzzzz_001_zzzzz_0010011: begin // PCNT
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b 0110000_00100_zzzzz_001_zzzzz_0010011: begin // SEXT.B
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b 0110000_00101_zzzzz_001_zzzzz_0010011: begin // SEXT.H
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b 0000100_zzzzz_zzzzz_100_zzzzz_0110011: begin // PACK
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0100100_zzzzz_zzzzz_100_zzzzz_0110011: begin // PACKU
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0000100_zzzzz_zzzzz_111_zzzzz_0110011: begin // PACK.H
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0000101_zzzzz_zzzzz_100_zzzzz_0110011: begin  // MIN
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0000101_zzzzz_zzzzz_101_zzzzz_0110011: begin  // MAX
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0000101_zzzzz_zzzzz_110_zzzzz_0110011: begin  // MINU
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 0000101_zzzzz_zzzzz_111_zzzzz_0110011: begin  // MAXU
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b011;
        end
        32'b 01101_0011111_zzzzz_101_zzzzz_0010011: begin // REV
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b 01101_0011000_zzzzz_101_zzzzz_0010011: begin // REV8
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        32'b 00101_0000111_zzzzz_101_zzzzz_0010011: begin // ORC.B
          req.insn_type = SINGLE_WRITEBACK;
          req.use_rs = 3'b001;
        end
        default: begin
          req.insn_type = ILLEGAL;
          req.use_rs=3'b000;
        end
      endcase
    `uvm_info(get_full_name(), $sformatf("seq_lib starting item with instrucion %0x", req.q_instr_data), UVM_LOW)
    start_item(req);
    finish_item(req);
    end

  endtask : body

endclass : rei_x_intf_ack_seq

