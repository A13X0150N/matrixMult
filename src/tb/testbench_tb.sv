// testbench_tb.sv

`include "src/tb/driver_tb.sv"
`include "src/tb/coverage_tb.sv"
`include "src/tb/scoreboard_tb.sv"
`include "src/tb/checker_tb.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

class testbench_tb;

    virtual mpu_bfm bfm;

    // Testbench components
    driver_tb driver_h;
    coverage_tb coverage_h;
    scoreboard_tb scoreboard_h;
    checker_tb checker_h;

    // Mailboxes
    mailbox #(mpu_data_sp) driver2checker;
    mailbox checker2scoreboard;

    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    task execute();
        display_message("Beginning Top-Level Testbench");
        $display("\n");
        mpu_top.mpu_bfm.wait_for_reset();
        display_message("Reset Complete");
        $display("\n");

        // Instantiate testbench pieces
        this.driver_h = new(bfm);
        this.coverage_h = new(bfm);
        this.scoreboard_h = new(bfm);
        this.checker_h = new(bfm);
        
        // Set up mailboxes
        this.driver2checker = new();
        this.checker2scoreboard = new();
        driver_h.driver2checker = this.driver2checker;
        checker_h.driver2checker = this.driver2checker;
        checker_h.checker2scoreboard = this.checker2scoreboard;
        scoreboard_h.checker2scoreboard = this.checker2scoreboard;
        
        // Execute testbench
        fork
            this.driver_h.execute();
            this.scoreboard_h.execute();
            this.checker_h.execute();
        join_none
    endtask : execute

endclass : testbench_tb
