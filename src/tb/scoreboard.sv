// scoreboard.sv

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

// Scoreboard tracks bugs that are discovered and tests that are passed
class scoreboard;

    virtual mpu_bfm bfm;

    function new (virtual mpu_bfm b);
        this.bfm = b;
    endfunction : new

    task execute();
        $display("scoreboard_h.execute()");
    endtask : execute

endclass : scoreboard
