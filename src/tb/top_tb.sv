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

`include "src/tb/testbench_tb.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

module top_tb;

    testbench_tb testbench_h;                   // Testbench handle

    // Object instantiation
    initial begin
        testbench_h = new(mpu_top.mpu_bfm);
        testbench_h.execute();
    end

    final begin
        display_message("End of Testbench");
        //display_message("Design Registers");
        //simulation_register_dump(mpu_top.mpu_register_file.matrix_register_array);
        //$display("\n\n");
        //display_message("Testbench Registers");
        //simulation_register_dump(testbench_h.checker_h.ref_register_array);
        testbench_h.scoreboard_h.current_stats();
        $display("\n\n");
    end

endmodule : top_tb
