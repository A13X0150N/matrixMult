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
`include "src/hvl/testcase_factory_tb.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

class testbench_tb;

    virtual mpu_bfm bfm;                        // Virtual BFM interface
    driver_tb driver_h;                         // Testbench driver
    scoreboard_tb scoreboard_h;                 // Testbench scoreboard
    checker_tb checker_h;                       // Testbench checker
    mailbox #(mpu_data_sp) driver2checker;      // Top-level driver2checker mailbox
    mailbox checker2scoreboard;                 // Top-level checker2scoreboard mailbox
    mailbox #(stim_data_sp) stimulus2driver;    // Top-level stimulus2driver mailbox
    stimulus_tb stimulus_h;                     // Parent class test type
    int unsigned iterations;                    // Number of test iterations

    // Object instantiation
    function new (virtual mpu_bfm b, string testcase, int unsigned runs);
        this.bfm = b;
        this.stimulus_h = testcase_factory_tb::generate_testcase(testcase);
        this.iterations = runs;
    endfunction : new

    // Testbench execution
    task execute();
        display_message("Beginning Top-Level Testbench");
        $display("\n");
        mpu_top.mpu_bfm.wait_for_reset();
        display_message("Reset Complete");
        $display("\n");

        // Instantiate testbench pieces
        this.driver_h = new(this.bfm, this.iterations);
        this.scoreboard_h = new(this.bfm);
        this.checker_h = new(this.bfm);
        
        // Set up mailboxes
        this.driver2checker = new();
        this.checker2scoreboard = new();
        this.stimulus2driver = new();
        this.driver_h.driver2checker = this.driver2checker;
        this.checker_h.driver2checker = this.driver2checker;
        this.checker_h.checker2scoreboard = this.checker2scoreboard;
        this.scoreboard_h.checker2scoreboard = this.checker2scoreboard;
        this.stimulus_h.stimulus2driver = this.stimulus2driver;
        this.driver_h.stimulus2driver = this.stimulus2driver;
        
        // Execute testbench
        fork
            this.scoreboard_h.execute();
            this.checker_h.execute();
            this.stimulus_h.execute();
            this.driver_h.execute();
        join_none
    endtask : execute

endclass : testbench_tb
