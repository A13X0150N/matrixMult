// mpu_load_store.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Load and store to all registers
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;
import hvl_stimulus_includes::*;

class mpu_load_store extends stimulus_tb;

    function new();
        super.new();
    endfunction : new

    task execute();
    	$display("Testcase: Load and store to all registers");
        this.stim_data.ready_to_multiply = FALSE;
        this.stim_data.ready_to_load = TRUE;
        for (int i = 0, shortreal ii = 0.0; i < MATRIX_REGISTERS; ++i, ii = ii + 1.0 * 36.0) begin
            this.stim_data.generated_matrix = generate_matrix(ii, 1.0);  // Each element is unique and sequential across all matrix registers
            this.stim_data.addr0 = i;
            if (i == MATRIX_REGISTERS-1) begin
                this.stim_data.ready_to_load = FALSE;
                this.stim_data.ready_to_store = TRUE;
            end
            this.stimulus2driver.put(this.stim_data);
        end
    endtask : execute

endclass : mpu_load_store
