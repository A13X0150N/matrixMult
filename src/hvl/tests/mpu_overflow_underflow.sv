// mpu_overflow_underflow.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Multiply very large floating point and very large floating point to show
// overflow and very small with very small to show underflow.
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;
import hvl_stimulus_includes::*;

class mpu_overflow_underflow extends stimulus_tb;

    function new();
        super.new();
        $display("Testcase: Multiply large/small matrices to get overflow/underflow");
    endfunction : new

    task execute(input int unsigned runs);
        repeat (runs) begin
            this.stim_data.ready_to_load = TRUE;
            this.stim_data.generated_matrix = {
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32
            };
            this.stim_data.addr0 = 0;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = {
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32,
                BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32, BIG_FLOAT_32
            };
            this.stim_data.addr0 = 1;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = {
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32
            };
            this.stim_data.addr0 = 2;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = {
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32,
                SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32, SMALL_FLOAT_32
            };
            this.stim_data.addr0 = 3;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.ready_to_load = FALSE;
            this.stim_data.ready_to_multiply = TRUE;
            this.stim_data.addr0 = 0;
            this.stim_data.addr1 = 1;
            this.stim_data.dest  = 4;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = 1;
            this.stim_data.addr1 = 0;
            this.stim_data.dest  = 5;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = 2;
            this.stim_data.addr1 = 3;
            this.stim_data.dest  = 6;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = 3;
            this.stim_data.addr1 = 2;
            this.stim_data.dest  = 7;
            this.stim_data.ready_to_store = TRUE;        
            this.stimulus2driver.put(this.stim_data);
        end
    endtask : execute

endclass : mpu_overflow_underflow
