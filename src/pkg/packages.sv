// packages.sv
//
// Desciption:
// ----------------------------------------------------------------------------
// Contains packages with definitions for design and testbench.

timeunit 1ns/100ps;

// Definitions for global space
package global_defs;
    timeunit 1ns/100ps;

    // Type defines
    typedef enum logic {FALSE, TRUE} bool_t;

    // Floating point sizes
    parameter SP = 32;  // Single precision
    parameter DP = 64;  // Double precions
    parameter FP = SP;  // Selection for design

    // Multiplication methods, only make one selection (TODO: MULT_WALLACE, MULT_BOOTH)
    parameter MULT_SIMULATION = 0;
    parameter MULT_BOOTH_RADIX4 = 1;
    parameter MULT_WALLACE = 0;
    
    // Testbench
    parameter CLOCK_PERIOD = 10;

    // Maximum matrix dimensions (m x k)(k x n)
    parameter M = 2;
    parameter K = 2;
    parameter N = 2;
    parameter MBITS = $clog2(M);
    parameter KBITS = $clog2(K);
    parameter NBITS = $clog2(N);
    parameter MATRIX_REGISTERS = 4;
    parameter MATRIX_REG_SIZE = $clog2(MATRIX_REGISTERS);

endpackage : global_defs


// Input/Output bit width for multiplication
package bit_width;
    parameter  INWIDTH  = 16;
    localparam OUTWIDTH = INWIDTH * 2;
endpackage : bit_width


// FPU BFM interface definitions
package fpu_pkg;
    typedef enum logic [1:0] {
        NOP  = 2'b00,
        ADD  = 2'b01,
        MULT = 2'b10
    } fpu_operation_t;
endpackage : fpu_pkg


// MPU BFM interface definitions
package mpu_pkg;
    typedef enum logic [1:0] {
        NOP   = 2'b00,
        LOAD  = 2'b01,
        STORE = 2'b10
    } mpu_operation_t;

    typedef enum logic {
        LOAD_IDLE   = 1'b0,
        LOAD_MATRIX = 1'b1
    } load_state_t;

endpackage : mpu_pkg

