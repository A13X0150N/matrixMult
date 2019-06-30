// top.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Top-level design for DUT and testbench. Eventually migrate to UVM.

import global_defs::*;

module top;
    initial $display("\n\tBegin tests\n");

    mpu_load_store_tb mpu_memory_test();  
    fpu_multiplier_tb mult_test();
    fpu_adder_tb add_test();

    initial #(CLOCK_PERIOD*CYCLES) $stop; 
    final $display("\n\tEnd of test\n\n");
endmodule : top
