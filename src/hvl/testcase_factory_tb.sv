// testcase_factory_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Testcase factory that generates different types of tests to run from command
// line arguments.
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;
import hvl_stimulus_includes::*;

class testcase_factory_tb;

	static function stimulus_tb generate_testcase(string testcase);
		
		mpu_load_store mpu_load_store_h;
		mpu_mult_pos_one mpu_mult_pos_one_h;

		case (testcase)
			"load_store" : begin
				mpu_load_store_h = new();
				return mpu_load_store_h;
			end
			"multiply_positive_ones": begin
				mpu_mult_pos_one_h = new();
				return mpu_mult_pos_one_h;
			end
			default: $fatal("Invalid testcase selection \n\t * * * Aborting Testbench * * *");
		endcase

	endfunction : generate_testcase


endclass : testcase_factory_tb