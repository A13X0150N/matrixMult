// mpu_mult_pos_one.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Multiply by various matrices by +1
//
// ----------------------------------------------------------------------------

`include "src/hvl/stimulus_tb.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

class mpu_mult_pos_one extends stimulus_tb;

    function new();
        super.new();
    endfunction : new

    task execute();
    	$display("Testcase: Multiply a matrix with a matrix filled with +1");

    	/*generate_matrix(1.0, 0.0, this.load_data);             // Uniform +1.0 matrix
    	stimulus2driver.put();

        ////////////////////////////////
        // Check multiply by +1 cases //
        ////////////////////////////////
        generate_matrix(1.0, 1.0, this.load_data);
        this.checker_data.matrix_in = this.load_data.matrix;
        load(0);
        generate_matrix(1.0, 0.0, this.load_data);             // Uniform +1.0 matrix
        this.checker_data.matrix_in = this.load_data.matrix;
        load(1);
        generate_matrix_reverse(100.0, 100.0, this.load_data); // Matrix of large numbers
        this.checker_data.matrix_in = this.load_data.matrix;
        load(2);
        generate_matrix(0.01, 0.01, this.load_data);           // Matrix of small numbers
        this.checker_data.matrix_in = this.load_data.matrix;
        load(3);
        multiply(0, 1, 4);
        multiply(1, 1, 5);
        multiply(2, 1, 6);
        multiply(3, 1, 7);
        store_registers();*/
        //simulation_register_dump(mpu_top.mpu_register_file.matrix_register_array);




    endtask : execute



endclass
