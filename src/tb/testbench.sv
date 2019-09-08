// testbench.sv

`include "src/tb/driver.sv"
`include "src/tb/coverage.sv"
`include "src/tb/scoreboard.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

class testbench;

    virtual mpu_bfm bfm;

    driver driver_h;
    coverage coverage_h;
    scoreboard scoreboard_h;

    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    task execute();
    	mpu_top.mpu_bfm.wait_for_reset();
        display_message("Reset Complete");
        $display("\n\n\n");
        display_message("Beginning Top-Level Testbench");
        this.driver_h = new(bfm);
        this.coverage_h = new(bfm);
        this.scoreboard_h = new(bfm);
        fork
            this.driver_h.execute();
            this.coverage_h.execute();
            this.scoreboard_h.execute();
        join_none
    endtask : execute

endclass : testbench
