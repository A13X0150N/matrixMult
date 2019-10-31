// scoreboard_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: August 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Scoreboard that counts the number of pass/fails received from the reference
// model.
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

// Scoreboard tracks bugs that are discovered and tests that are passed
class scoreboard_tb;

    virtual mpu_bfm bfm;                            // Virtual BFM interface
    mailbox checker2scoreboard;                     // Mailbox from checker with test result
    static int tests_passed;                        // Number of tests passed
    static int tests_failed;                        // Number of tests failed
    int test_result;                                // Test result from mailbox

    // Object instantiation
    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    // Keep score
    task execute();
        tests_passed = 0;
        tests_failed = 0;
        forever begin
            checker2scoreboard.get(test_result);
            if (test_result == PASS) begin
                ++tests_passed;
            end
            else begin
                ++tests_failed;
            end
        end
    endtask : execute

    // Display score
    static task current_stats();
        display_message("Testbench Results");
        $display("\n\t Tests Passed: %d", tests_passed);
        $display("\t Tests Failed: %d", tests_failed);
        $display("\n\n\t The DUT is currently passing %0.2f%% of the tests\n", 100.0*tests_passed/(tests_passed+tests_failed));
    endtask

endclass : scoreboard_tb
