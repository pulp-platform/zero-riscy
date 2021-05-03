#!/bin/bash

set -ex

if [ ! -d riscv-extension-interface ]; then
  git clone git@github.com:ganoam/riscv-extension-interface
  cd riscv-extension-interface
  git checkout ibex-test
  cd ..
fi

if [ ! -d riscv-bitmanip ]; then
  git clone git@github.com:riscv/riscv-bitmanip.git
  cd ..
fi


