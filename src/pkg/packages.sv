// packages.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
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
    parameter SP = 32;          // Single precision
    parameter DP = 64;          // Double precions [untested]
    parameter FP = SP;          // Selection for design
    parameter FPBITS = FP-1;    // Floating point bit number

    // Multiplication methods, only make one selection (For experimental directory)
    parameter MULT_SIMULATION = 0;
    parameter MULT_BOOTH_RADIX4 = 1;
    parameter MULT_WALLACE = 0;
    
    // Testbench
    parameter CLOCK_PERIOD = 10;
    parameter CYCLES = 100;

    // Maximum matrix dimensions (m x k)(k x n)
    parameter M = 3;
    parameter K = 3;
    parameter N = 3;
    parameter MBITS = $clog2(M)-1;
    parameter KBITS = $clog2(K)-1;
    parameter NBITS = $clog2(N)-1;
    parameter NUM_ELEMENTS = M*N;

    // Size of matrix register file
    parameter MATRIX_REGISTERS = 16;
    parameter MATRIX_REG_BITS = $clog2(MATRIX_REGISTERS)-1;

//    task cycles;
  //      (($time+(CLOCK_PERIOD/2))/CLOCK_PERIOD)
    //endtask : cycles

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

    typedef enum logic {
        STORE_IDLE   = 1'b0,
        STORE_MATRIX = 1'b1
    } store_state_t;
endpackage : mpu_pkg

