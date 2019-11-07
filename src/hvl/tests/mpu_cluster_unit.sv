// mpu_cluster_unit.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Multiply by increasing powers of 2 to show that the cluster is correctly
// configured
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;
import hvl_stimulus_includes::*;

class mpu_cluster_unit extends stimulus_tb;

    function new();
        super.new();
    endfunction : new

    task execute();
    	$display("Testcase: Multiply increasing powers of 2 for cluster configuartion checking");
        this.stim_data.ready_to_load = TRUE;
    	this.stim_data.ready_to_multiply = FALSE;
        this.stim_data.generated_matrix = generate_matrix(1.0, 0.0);        // Uniform +1.0 matrix
        this.stim_data.addr0 = 0;
        this.stimulus2driver.put(this.stim_data);
        this.stim_data.generated_matrix = {
            $shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(1.0), $shortrealtobits(1.0),
            $shortrealtobits(2.0), $shortrealtobits(2.0), $shortrealtobits(2.0), $shortrealtobits(2.0), $shortrealtobits(2.0), $shortrealtobits(2.0),
            $shortrealtobits(4.0), $shortrealtobits(4.0), $shortrealtobits(4.0), $shortrealtobits(4.0), $shortrealtobits(4.0), $shortrealtobits(4.0),
            $shortrealtobits(8.0), $shortrealtobits(8.0), $shortrealtobits(8.0), $shortrealtobits(8.0), $shortrealtobits(8.0), $shortrealtobits(8.0),
            $shortrealtobits(16.0), $shortrealtobits(16.0), $shortrealtobits(16.0), $shortrealtobits(16.0), $shortrealtobits(16.0), $shortrealtobits(16.0),
            $shortrealtobits(32.0), $shortrealtobits(32.0), $shortrealtobits(32.0), $shortrealtobits(32.0), $shortrealtobits(32.0), $shortrealtobits(32.0)
        };
        this.stim_data.addr0 = 1;
        this.stimulus2driver.put(this.stim_data);
        this.stim_data.generated_matrix = {
            $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
            $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
            $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
            $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
            $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0),
            $shortrealtobits(1.0), $shortrealtobits(2.0), $shortrealtobits(4.0), $shortrealtobits(8.0), $shortrealtobits(16.0), $shortrealtobits(32.0)
        };
        this.stim_data.addr0 = 2;
        this.stimulus2driver.put(this.stim_data);
        this.stim_data.ready_to_load = FALSE;
        this.stim_data.ready_to_multiply = TRUE;
        this.stim_data.addr0 = 0;
        this.stim_data.addr1 = 1;
        this.stim_data.dest  = 3;
        this.stimulus2driver.put(this.stim_data);
        this.stim_data.addr0 = 1;
        this.stim_data.addr1 = 0;
        this.stim_data.dest  = 4;
        this.stimulus2driver.put(this.stim_data);
        this.stim_data.addr0 = 0;
        this.stim_data.addr1 = 2;
        this.stim_data.dest  = 5;
        this.stimulus2driver.put(this.stim_data);
        this.stim_data.addr0 = 2;
        this.stim_data.addr1 = 0;
        this.stim_data.dest  = 6;
        this.stimulus2driver.put(this.stim_data);
        this.stim_data.addr0 = 0;
        this.stim_data.addr1 = 0;
        this.stim_data.dest  = 7;
        this.stim_data.ready_to_store = TRUE;        
        this.stimulus2driver.put(this.stim_data);
    endtask : execute

endclass : mpu_cluster_unit
