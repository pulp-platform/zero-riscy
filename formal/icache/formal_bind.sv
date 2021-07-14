// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

bind ibex_icache formal_tb #(
  .BranchPredictor (BranchPredictor),
  .ICacheECC       (ICacheECC),
  .BranchCache     (BranchCache),

  .NUM_FB          (NUM_FB)
) tb_i (.*);
