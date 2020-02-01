// mpu_mult_random.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Multiply random matrices together
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;
import hvl_stimulus_includes::*;

class mpu_mult_random extends stimulus_tb;

    function new();
        super.new();
        $display("Testcase: Multiply random matrices together");
    endfunction : new

    task execute(input int unsigned runs);
        repeat(runs) begin
            this.stim_data.ready_to_load = TRUE;
            this.stim_data.generated_matrix = generate_matrix(-1.0*random_float()/10000, -1.0*random_float());
            this.stim_data.addr0 = 0;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = generate_matrix_reverse(0.001, random_float()/10000);
            this.stim_data.addr0 = 1;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = generate_matrix(0.1, random_float()*0.07);
            this.stim_data.addr0 = 2;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.ready_to_load = FALSE;
            this.stim_data.ready_to_multiply = TRUE;
            this.stim_data.addr0 = $urandom_range(0,2);
            this.stim_data.addr1 = $urandom_range(0,2);
            this.stim_data.dest  = 3;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = $urandom_range(0,3);
            this.stim_data.addr1 = $urandom_range(0,3);
            this.stim_data.dest  = 4;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = $urandom_range(0,4);
            this.stim_data.addr1 = $urandom_range(0,4);
            this.stim_data.dest  = 5;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = $urandom_range(0,5);
            this.stim_data.addr1 = $urandom_range(0,5);
            this.stim_data.dest  = 6;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.addr0 = $urandom_range(1,2);
            this.stim_data.addr1 = $urandom_range(1,2);
            this.stim_data.dest  = 7;
            this.stim_data.ready_to_store = TRUE;        
            this.stimulus2driver.put(this.stim_data);
        end
    endtask : execute

endclass : mpu_mult_random
