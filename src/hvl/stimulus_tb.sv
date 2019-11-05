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

virtual class stimulus_tb;

	mailbox stimulus2driver;

	function new();
		
	endfunction : new

	pure virtual task execute();

endclass : stimulus_tb
