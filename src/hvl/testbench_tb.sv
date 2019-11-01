// testbench_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: August 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Testbench that instantiates the other components of the OOP testbench.
//
// ----------------------------------------------------------------------------

`include "src/hvl/driver_tb.sv"
`include "src/hvl/scoreboard_tb.sv"
`include "src/hvl/checker_tb.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

class testbench_tb;

    virtual mpu_bfm bfm;                                // Virtual BFM interface
    driver_tb driver_h;                                 // Testbench driver
    scoreboard_tb scoreboard_h;                         // Testbench scoreboard
    checker_tb checker_h;                               // Testbench checker
    mailbox #(mpu_data_sp) driver2checker;              // Top-level driver2checker mailbox
    mailbox checker2scoreboard;                         // Top-level checker2scoreboard mailbox

    // Object instantiation
    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    // Testbench execution
    task execute();
        display_message("Beginning Top-Level Testbench");
        $display("\n");
        mpu_top.mpu_bfm.wait_for_reset();
        display_message("Reset Complete");
        $display("\n");

        // Instantiate testbench pieces
        this.driver_h = new(bfm);
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
