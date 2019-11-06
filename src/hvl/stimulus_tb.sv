// stimulus_tb.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: November 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Stimulus generator parent class
//
// ----------------------------------------------------------------------------

import global_defs::*;
import mpu_data_types::*;
import testbench_utilities::*;
import hvl_stimulus_includes::*;

virtual class stimulus_tb;

	mailbox #(stim_data_sp) stimulus2driver;
	stim_data_sp stim_data;

	function new();
		this.stim_data.ready_to_store = FALSE;
	endfunction : new

	pure virtual task execute();

endclass : stimulus_tb
