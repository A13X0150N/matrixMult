// top_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Testbench to check the load and store ability of the design.

`include "src/tb/testbench_tb.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

module top_tb;

    testbench_tb testbench_h;

    initial begin
        testbench_h = new(mpu_top.mpu_bfm);
        testbench_h.execute();
    end

    final begin
        display_message("End of Testbench");
        //$display("\n\n\t Design Registers\n");
        //simulation_register_dump(mpu_top.mpu_register_file.matrix_register_array);
        //$display("\n\n\n\n\t Testbench Registers\n");
        //simulation_register_dump(testbench_h.checker_h.ref_register_array);
        $display("\n * * *  Total coverage: %0.2f%%  * * *\n\n", $get_coverage());
        testbench_h.scoreboard_h.current_stats();
        $display("\n\n");
    end

endmodule : top_tb
