.. _riscv_trace:                                                                                         


RISC-V Trace Interface
======================

Ibex implements an instruction trace interface compatible with the `RISC-V Trace Specification, version 1.0, as released on March 20, 2020 <https://github.com/riscv/riscv-trace-spec/>`_. 
This interface exports needed internal signals as ibex_core outputs to be used to encode the trace packets to be logged.

Signals implemented until now are shown in the table below:


Trace Signals
-------------

+--------------------+----------+-------------------------------------------------------------+
|   Signal Name      |   Bits   |                         Description                         |
+====================+==========+=============================================================+
| rv_trace_itype     |    3     | 0: Final instruction in block is none of other itype codes; |
|                    |          | 1: Exception. An exception that traps occurred              |
|                    |          | following the final retired instruction in the block;       |
|                    |          | 2: Interrupt. An interrupt that traps occurred              |
|                    |          | following the final retired instruction in the block;       |
|                    |          | 3: Exception or interrupt return;  (not yet implemented)    |
|                    |          | 4: Nontaken branch;                                         |
|                    |          | 5: Taken branch;                                            |
|                    |          | 6: Uninferable jump                (not yet implemented)    |
+--------------------+----------+-------------------------------------------------------------+
| rv_trace_iaddr     |   32     | Contains the value of the address all the time.             |
+--------------------+----------+-------------------------------------------------------------+
| rv_trace_cause     |    7     | ucause/mcause CSR                                           |
+--------------------+----------+-------------------------------------------------------------+
| rv_trace_tval      |   32     | Associated trap value, e.g. address of                      |
|                    |          | exceptions, as written to the utval/mtval CSR               |
+--------------------+----------+-------------------------------------------------------------+
| rv_trace_priv      |    2     | Privilege level for all instructions retired on this cycle. |
+--------------------+----------+-------------------------------------------------------------+
| rv_trace_iretire   |    1     | The trace signals are valid (1), or not (0).                |                         
+--------------------+----------+-------------------------------------------------------------+

Parameters
----------

Referring to Table 7.1 in the RISC-V Trace Specification v1.0, here are the parameters specified in the the implemented interface:

+----------------+-------+
| Parameter      | Value |
+----------------+-------+ 
| itype_width_p  |   3   |
+----------------+-------+
| ecause_width_p |   6   |
+----------------+-------+
| ecause_choice_p|   1   |
+----------------+-------+
