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

`include "src/hvl/tests/mpu_mult_pos_one.sv"

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;

class testcase_factory_tb;

	static function stimulus_tb generate_testcase(string testcase);
		mpu_mult_pos_one mpu_mult_pos_one_h;

		case(testcase)
			"multiply_positive_one": begin
				mpu_mult_pos_one_h = new();
				return mpu_mult_pos_one_h;
			end
			default: $fatal("Invalid testcase selection \n\t * * * Aborting Testbench * * *");
		endcase

	endfunction : generate_testcase


endclass : testcase_factory_tb