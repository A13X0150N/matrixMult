// mpu_mult_zero.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Multiply by various matrices by 0
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;
import hvl_stimulus_includes::*;

class mpu_mult_zero extends stimulus_tb;

    function new();
        super.new();
        $display("Testcase: Multiply a matrix with a matrix filled with 0");
    endfunction : new

    task execute(input int unsigned runs);
        repeat (runs) begin
            this.stim_data.ready_to_load = TRUE;
            this.stim_data.generated_matrix = generate_matrix(0.0, 0.0);        // Uniform 0.0 matrix
            this.stim_data.addr0 = 0;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = generate_matrix(1.0, 0.0);        // Uniform +1.0 matrix
            this.stim_data.addr0 = 1;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = generate_matrix(-1.0, 0.0);       // Uniform -1.0 matrix
            this.stim_data.addr0 = 2;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = generate_matrix(0.01, 0.01);      // Matrix of small numbers
            this.stim_data.addr0 = 3;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.ready_to_load = FALSE;
            this.stim_data.ready_to_multiply = TRUE;
            this.stim_data.addr0 = 0;
            this.stim_data.addr1 = 0;
            this.stim_data.dest  = 4;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = 0;
            this.stim_data.addr1 = 1;
            this.stim_data.dest  = 5;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = 0;
            this.stim_data.addr1 = 2;
            this.stim_data.dest  = 6;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = 0;
            this.stim_data.addr1 = 3;
            this.stim_data.dest  = 7;
            this.stim_data.ready_to_store = TRUE;        
            this.stimulus2driver.put(this.stim_data);
        end
    endtask : execute

endclass : mpu_mult_zero
