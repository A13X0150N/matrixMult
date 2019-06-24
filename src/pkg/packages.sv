// packages.sv
//
// Desciption:
// ----------------------------------------------------------------------------
// Contains packages with definitions for design and testbench.

timeunit 1ns/100ps;

// Definitions for guiding design
package mm_defs;
	
	// Type defines
	typedef enum logic {FALSE, TRUE} bool;

	// Multiplication methods, only make one selection (TODO: MULT_WALLACE, MULT_BOOTH)
	parameter MULT_SIMULATION = 0;
	parameter MULT_BOOTH_RADIX4 = 1;
	parameter MULT_WALLACE = 0;
	
	// testbench
	parameter CLOCK_PERIOD = 10;

endpackage : mm_defs


// Input/Output bit width for multiplication
package bit_width;

	parameter  INWIDTH  = 16;
	localparam OUTWIDTH = INWIDTH * 2;

endpackage : bit_width

