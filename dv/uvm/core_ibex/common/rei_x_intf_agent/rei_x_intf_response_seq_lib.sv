
// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

//------------------------------------------------------------------------------
// SEQUENCE: rei_x_intf_response_seq
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

class rei_x_intf_response_seq extends uvm_sequence #(rei_x_intf_seq_item);

  rei_x_intf_seq_item item;

  `uvm_object_utils(rei_x_intf_response_seq)
  `uvm_declare_p_sequencer(rei_x_intf_response_sequencer)
  `uvm_object_new


  virtual task body();
    forever begin
      logic [5:0] shamt;
      // get request from req monitor
      p_sequencer.ack_ph_port.get(item);
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
          req.p_data[0] = item.q_rs[0] & ~item.q_rs[1];
        end
        32'b 0100000_zzzzz_zzzzz_110_zzzzz_0110011: begin // ORN
          req.p_data[0] = item.q_rs[0] | ~item.q_rs[1];
        end
        32'b 0100000_zzzzz_zzzzz_100_zzzzz_0110011: begin // XNOR
          req.p_data[0] = item.q_rs[0] ^ ~item.q_rs[1];
        end
        32'b 0010000_zzzzz_zzzzz_001_zzzzz_0110011: begin // SLO
          shamt = item.q_rs[1] & 6'b011111;
          req.p_data[0] = ~(~item.q_rs[0] << shamt);
        end
        32'b 0010000_zzzzz_zzzzz_101_zzzzz_0110011: begin // SRO
          shamt = item.q_rs[1] & 6'b011111;
          req.p_data[0] = ~(~item.q_rs[0] >> shamt);
        end
        32'b 0110000_zzzzz_zzzzz_001_zzzzz_0110011: begin // ROL
          shamt = item.q_rs[1] & 6'b011111;;
          req.p_data[0] = (item.q_rs[0] << shamt) | (item.q_rs[0] >> ((6'd32 - shamt) & 6'b011111));
        end
        32'b 0110000_zzzzz_zzzzz_101_zzzzz_0110011: begin // ROR
          shamt = item.q_rs[1] & 6'b011111;;
          req.p_data[0] = (item.q_rs[0] >> shamt) | (item.q_rs[0] << ((6'd32 - shamt) & 6'b011111));
        end
        32'b 00100_00zzzzz_zzzzz_001_zzzzz_0010011: begin // SLOI (RV32)
          shamt = (item.q_instr_data[24:20]);
          req.p_data[0] = ~(~item.q_rs[0] << shamt);
        end
        32'b 00100_00zzzzz_zzzzz_101_zzzzz_0010011: begin // SROI (RV32)
          shamt = (item.q_instr_data[24:20]);
          req.p_data[0] = ~(~item.q_rs[0] >> shamt);
        end
        32'b 01100_00zzzzz_zzzzz_101_zzzzz_0010011: begin // RORI (RV32)
          shamt = (item.q_instr_data[24:20]);
          req.p_data[0] =   (item.q_rs[0] >> shamt) | (item.q_rs[0] << ((6'd32 - shamt) & 6'b011111));
        end
        32'b zzzzz11_zzzzz_zzzzz_001_zzzzz_0110011: begin // CMIX
          req.p_data[0] = (item.q_rs[0] & item.q_rs[1]) | (item.q_rs[2] & ~item.q_rs[1]);
        end
        32'b zzzzz11_zzzzz_zzzzz_101_zzzzz_0110011: begin // CMOV
          req.p_data = |item.q_rs[1] ? item.q_rs[0] : item.q_rs[2];
        end
        32'b zzzzz10_zzzzz_zzzzz_001_zzzzz_0110011: begin // FSL
          shamt = item.q_rs[1] & 6'b111111;;
          if (shamt >=32) begin
            shamt -= 32;
            req.p_data[0] =
              |shamt ? (item.q_rs[2] << shamt) | (item.q_rs[0] >> (6'd32 - shamt)) : item.q_rs[2];
          end else begin
            req.p_data[0] =
              |shamt ? (item.q_rs[0] << shamt) | (item.q_rs[2] >> (6'd32 - shamt)) : item.q_rs[0];
          end
        end
        32'b zzzzz10_zzzzz_zzzzz_101_zzzzz_0110011: begin // FSR
          shamt = item.q_rs[1] & 6'b111111;;
          if (shamt >=32) begin
            shamt -= 32;
            req.p_data[0] =
              |shamt ? (item.q_rs[2] >> shamt) | (item.q_rs[0] << (6'd32 - shamt)) : item.q_rs[2];
          end else begin
            req.p_data[0] =
              |shamt ? (item.q_rs[0] >> shamt) | (item.q_rs[2] << (6'd32 - shamt)) : item.q_rs[0];
          end
        end
        32'b zzzzz1_0zzzzz_zzzzz_101_zzzzz_0010011: begin // FSRI (RV32)
          shamt = item.q_instr_data[25:20] & 6'b011111;;
          if (shamt >=32) begin
            shamt -= 32;
            req.p_data[0] =
              |shamt ? (item.q_rs[2] >> shamt) | (item.q_rs[0] << (6'd32 - shamt)) : item.q_rs[2];
          end else begin
            req.p_data[0] =
              |shamt ? (item.q_rs[0] >> shamt) | (item.q_rs[2] << (6'd32 - shamt)) : item.q_rs[0];
          end
        end
        32'b 0110000_00000_zzzzz_001_zzzzz_0010011: begin // CLZ
          req.p_data[0] = 32'd0;
          while ( |((item.q_rs[0] << req.p_data[0]) & 32'h1) == 1'b1 && req.p_data[0] <= 32) begin
            req.p_data[0]++;
          end
        end
        32'b 0110000_00010_zzzzz_001_zzzzz_0010011: begin // PCNT
          req.p_data[0] = 32'd0;
          for (int unsigned i = 0; i<32; i++) begin
            req.p_data[0] += |((item.q_rs[0] >> i) == 32'h1);
          end
        end
        32'b 0110000_00100_zzzzz_001_zzzzz_0010011: begin // SEXT.B
          req.p_data[0] = (item.q_rs[0] << 24) >>> 24;
        end
        32'b 0110000_00101_zzzzz_001_zzzzz_0010011: begin // SEXT.H
          req.p_data[0] = (item.q_rs[0] << 16) >>> 16;
        end
        32'b 0000100_zzzzz_zzzzz_100_zzzzz_0110011: begin // PACK
          req.p_data[0] = ((item.q_rs[0] <<16)>>16) | (item.q_rs[1]<<16);
        end
        32'b 0100100_zzzzz_zzzzz_100_zzzzz_0110011: begin // PACKU
          req.p_data[0] = (item.q_rs[0] >>16) | ((item.q_rs[1]>>16)<<16);
        end
        32'b 0000100_zzzzz_zzzzz_111_zzzzz_0110011: begin // PACK.H
          req.p_data[0] = (item.q_rs[0] & 8'hff) | ((item.q_rs[1] & 8'hff) <<8);
        end
        32'b 0000101_zzzzz_zzzzz_100_zzzzz_0110011: begin  // MIN
          req.p_data[0] = $signed(item.q_rs[0]) < $signed(item.q_rs[1]) ? item.q_rs[0] : item.q_rs[1];
        end
        32'b 0000101_zzzzz_zzzzz_101_zzzzz_0110011: begin  // MAX
          req.p_data[0] = $signed(item.q_rs[0]) > $signed(item.q_rs[1]) ? item.q_rs[0] : item.q_rs[1];
        end
        32'b 0000101_zzzzz_zzzzz_110_zzzzz_0110011: begin  // MINU
          req.p_data[0] = $unsigned(item.q_rs[0]) < $unsigned(item.q_rs[1]) ? item.q_rs[0] : item.q_rs[1];
        end
        32'b 0000101_zzzzz_zzzzz_111_zzzzz_0110011: begin  // MAXU
          req.p_data[0] = $unsigned(item.q_rs[0]) > $unsigned(item.q_rs[1]) ? item.q_rs[0] : item.q_rs[1];
        end
        32'b 01101_0011111_zzzzz_101_zzzzz_0010011: begin // REV
          req.p_data[0] = item.q_rs[0];
          req.p_data[0] = ((req.p_data[0] & 32'h 55555555) <<  1) | ((req.p_data[0] & 32'h AAAAAAAA) >>  1);
          req.p_data[0] = ((req.p_data[0] & 32'h 33333333) <<  2) | ((req.p_data[0] & 32'h CCCCCCCC) >>  2);
          req.p_data[0] = ((req.p_data[0] & 32'h 0F0F0F0F) <<  4) | ((req.p_data[0] & 32'h F0F0F0F0) >>  4);
          req.p_data[0] = ((req.p_data[0] & 32'h 00FF00FF) <<  8) | ((req.p_data[0] & 32'h FF00FF00) >>  8);
          req.p_data[0] = ((req.p_data[0] & 32'h 0000FFFF) << 16) | ((req.p_data[0] & 32'h FFFF0000) >> 16);
        end
        32'b 01101_0011000_zzzzz_101_zzzzz_0010011: begin // REV8
          req.p_data[0] = item.q_rs[0];
          req.p_data[0] = ((req.p_data[0] & 32'h 00FF00FF) <<  8) | ((req.p_data[0] & 32'h FF00FF00) >>  8);
          req.p_data[0] = ((req.p_data[0] & 32'h 0000FFFF) << 16) | ((req.p_data[0] & 32'h FFFF0000) >> 16);
        end
        32'b 00101_0000111_zzzzz_101_zzzzz_0010011: begin // ORC.B
          req.p_data[0] = {{8{|item.q_rs[0][31:24]}}, {8{|item.q_rs[0][23:16]}}, {8{|item.q_rs[0][15:8]}}, {8{|item.q_rs[0][7:0]}}};
        end
        default: begin
          req.p_data[0] = 'hx;
        end
      endcase
    start_item (req);
    finish_item(req);
    end

  endtask : body

endclass : rei_x_intf_response_seq

