// top_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: August 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Top level testbench that can run different types of tests.
//
// ----------------------------------------------------------------------------

`include "src/hvl/testbench_tb.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

module top_tb;

    testbench_tb testbench_h;   // Testbench handle
    string testcase;
    int unsigned runs;

    // Object instantiation
    initial begin
        $display("\n\t * START TIME: ");
        $system("date");
        if($value$plusargs("TESTCASE=%s", testcase));
        if($value$plusargs("RUNS=%d", runs));
        testbench_h = new(mpu_top.mpu_bfm, testcase, runs);
        testbench_h.execute();
        #(CLOCK_PERIOD*MAX_CYCLES) $warning("MAX_CYCLES exceeded before end of test, shutting down testbench\n");
        $finish;
    end

    final begin
        display_message("End of Testbench");
        $display("\n\t * STOP TIME: ");
        $system("date");
        //display_message("Design Registers");
        //simulation_register_dump(mpu_top.mpu_register_file.matrix_register_array);
        //$display("\n\n");
        display_message("Testbench Registers");
        simulation_register_dump(testbench_h.checker_h.ref_register_array);
        testbench_h.scoreboard_h.current_stats();
        $display("\n\n");
    end

endmodule : top_tb
