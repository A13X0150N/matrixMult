// mpu_mult_random.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Multiply matrices on repeat
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;
import hvl_stimulus_includes::*;

class mpu_mult_repeat extends stimulus_tb;

    function new();
        super.new();
        $display("Testcase: Multiply matrices together on repeat");
    endfunction : new

    task execute(input int unsigned runs);
        this.stim_data.ready_to_multiply_repeat = TRUE;
        this.stim_data.ready_to_load = TRUE;
        this.stim_data.generated_matrix = generate_matrix(1.0, 0.0);        // Uniform +1.0 matrix
        this.stim_data.addr0 = 0;
        this.stimulus2driver.put(this.stim_data);
        this.stim_data.generated_matrix = generate_matrix(1.0, 1.0);        // Increment +1.0 matrix
        this.stim_data.addr0 = 1;
        this.stimulus2driver.put(this.stim_data);
        this.stim_data.ready_to_load = FALSE;
        this.stim_data.ready_to_multiply_repeat = TRUE;
        this.stim_data.ready_to_multiply = TRUE;
        this.stim_data.addr0 = 0;
        this.stim_data.addr1 = 1;
        this.stim_data.dest  = 2;
        this.stim_data.ready_to_store = TRUE;        
        this.stimulus2driver.put(this.stim_data);
    endtask : execute

endclass : mpu_mult_repeat
