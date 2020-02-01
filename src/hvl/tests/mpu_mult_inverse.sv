// mpu_mult_inverse.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Multiply a unitary matrix with its inverse to obtain an indentity matrix.
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;
import hvl_stimulus_includes::*;

class mpu_mult_inverse extends stimulus_tb;

    function new();
        super.new();
        $display("Testcase: Multiply unitary matrices with their inverses");
    endfunction : new

    task execute(input int unsigned runs);
        repeat (runs) begin
            this.stim_data.ready_to_load = TRUE;
            this.stim_data.generated_matrix = {
                $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0)
            };
            this.stim_data.addr0 = 0;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = {
                $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0)
            };
            this.stim_data.addr0 = 1;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = {
                $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0)
            };
            this.stim_data.addr0 = 2;
            this.stimulus2driver.put(this.stim_data);
            this.stim_data.generated_matrix = {
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0),
                $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0),
                $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(1.0), $shortrealtobits(0.0), $shortrealtobits(0.0), $shortrealtobits(0.0)
            };
            this.stim_data.addr0 = 3;
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
            this.stim_data.addr1 = 1;
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

endclass : mpu_mult_inverse
