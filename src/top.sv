// top.sv
//
// Desciption:
// ----------------------------------------------------------------------------
// Top-level design for DUT and testbench. Eventually migrate UVM.

import mm_defs::*;

module top;
    initial $display("\n\tBegin tests\n");

    fpu_multiplier_tb mult_test();
    //fpu_adder_tb add_test();

    initial #(CLOCK_PERIOD*1000) $stop; 
    final $display("\n\tEnd of test\n\n");
endmodule : top