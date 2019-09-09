// scoreboard_tb.sv

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

// Scoreboard tracks bugs that are discovered and tests that are passed
class scoreboard_tb;

    virtual mpu_bfm bfm;
    mailbox checker2scoreboard;
    static int tests_passed;
    static int tests_failed;
    int test_result;

    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

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

    static task current_stats();
        display_message("Testbench Results");
        $display("\n\t Tests Passed: %d", tests_passed);
        $display("\n\t Tests Failed: %d", tests_failed);
    endtask

endclass : scoreboard_tb
