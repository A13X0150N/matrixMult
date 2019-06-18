// packages.sv
//
// Desciption:
// ----------------------------------------------------------------------------
// Contains packages with definitions for design and testbench.

// Definitions for guiding design
package mm_defs;
	
	// Type defines
	typedef enum logic {FALSE, TRUE} bool;

	// Multiplication methods, only make one selection (TODO: MULT_WALLACE, MULT_BOOTH)
	parameter MULT_SIMULATION = 1;
	parameter MULT_WALLACE = 0;
	parameter MULT_BOOTHE = 0;

endpackage : mm_defs


// Input/Output bit width for multiplication
package bit_width;

	parameter INPUTSIZE = 16;					// Maximum input size for binary multiplication
	localparam INWIDTH = $clog2(INPUTSIZE);
	localparam OUTWIDTH = INWIDTH * 2;

endpackage : bit_width

