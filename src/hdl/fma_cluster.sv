// fma_cluster.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: August 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// A 3x3 cluster of IEEE-754 Fused-Multiply Accumulate cores partitioned in a
// hypercube configuration.
//
// cluster naming convention:  label_i_j  
//
//
//      Example partitioning
//    3x3                 4x4
//  x x   x            x x   x x
//  x x   x            x x   x x
//
//  x x   x            x x   x x
//                     x x   x x
//
//
//                       Matrix B flows down  and up
//                               |                 ^
//                               |                 |
//   Matrix A flows right --->   v                 |
//               and left <---
// 
//
//                3x3 Grid                      Single FMA unit
//         FMA ---- FMA      FMA                      Up
//          | \      | \      | \                     |
//          |  ans   |  ans   |  ans                  v
//         FMA ---- FMA      FMA           Left ---> FMA ---> Right
//            \        \        \                     | \
//             ans      ans      ans                  v  ans
//         FMA ---- FMA       FMA                    Down
//            \        \        \
//             ans      ans      ans
//
//
// ----------------------------------------------------------------------------   

import global_defs::*;
import mpu_data_types::*;

module fma_cluster (
    input           clk,        // Clock
    input           rst,        // Synchronous reset active high

    output bit      busy_0_0_out, busy_0_1_out, busy_0_2_out, busy_0_3_out, busy_0_4_out, busy_0_5_out,
                    busy_1_0_out,                                                         busy_1_5_out,
                    busy_2_0_out,                                                         busy_2_5_out,
                    busy_3_0_out,                                                         busy_3_5_out,
                    busy_4_0_out,                                                         busy_4_5_out,
                    busy_5_0_out, busy_5_1_out, busy_5_2_out, busy_5_3_out, busy_5_4_out, busy_5_5_out,

    input  bit      float_0_req_0_0_in, float_0_req_0_5_in,
                    float_0_req_1_0_in, float_0_req_1_5_in,
                    float_0_req_2_0_in, float_0_req_2_5_in,
                    float_0_req_3_0_in, float_0_req_3_5_in,
                    float_0_req_4_0_in, float_0_req_4_5_in,
                    float_0_req_5_0_in, float_0_req_5_5_in,

    input  bit      float_1_req_0_0_in, float_1_req_0_1_in, float_1_req_0_2_in, float_1_req_0_3_in, float_1_req_0_4_in, float_1_req_0_5_in,
                    float_1_req_5_0_in, float_1_req_5_1_in, float_1_req_5_2_in, float_1_req_5_3_in, float_1_req_5_4_in, float_1_req_5_5_in, 

    input  float_sp float_0_data_0_0_in, float_0_data_0_5_in,
                    float_0_data_1_0_in, float_0_data_1_5_in,
                    float_0_data_2_0_in, float_0_data_2_5_in,
                    float_0_data_3_0_in, float_0_data_3_5_in,
                    float_0_data_4_0_in, float_0_data_4_5_in,
                    float_0_data_5_0_in, float_0_data_5_5_in,

    input  float_sp float_1_data_0_0_in, float_1_data_0_1_in, float_1_data_0_2_in, float_1_data_0_3_in, float_1_data_0_4_in, float_1_data_0_5_in,
                    float_1_data_5_0_in, float_1_data_5_1_in, float_1_data_5_2_in, float_1_data_5_3_in, float_1_data_5_4_in, float_1_data_5_5_in, 

    output float_sp result_0_0_out, result_0_1_out, result_0_2_out, result_0_3_out, result_0_4_out, result_0_5_out,
                    result_1_0_out, result_1_1_out, result_1_2_out, result_1_3_out, result_1_4_out, result_1_5_out,
                    result_2_0_out, result_2_1_out, result_2_2_out, result_2_3_out, result_2_4_out, result_2_5_out,
                    result_3_0_out, result_3_1_out, result_3_2_out, result_3_3_out, result_3_4_out, result_3_5_out,
                    result_4_0_out, result_4_1_out, result_4_2_out, result_4_3_out, result_4_4_out, result_4_5_out,
                    result_5_0_out, result_5_1_out, result_5_2_out, result_5_3_out, result_5_4_out, result_5_5_out, 

    output bit      ready_0_0_out, ready_0_1_out, ready_0_2_out, ready_0_3_out, ready_0_4_out, ready_0_5_out,
                    ready_1_0_out, ready_1_1_out, ready_1_2_out, ready_1_3_out, ready_1_4_out, ready_1_5_out,
                    ready_2_0_out, ready_2_1_out, ready_2_2_out, ready_2_3_out, ready_2_4_out, ready_2_5_out,
                    ready_3_0_out, ready_3_1_out, ready_3_2_out, ready_3_3_out, ready_3_4_out, ready_3_5_out,
                    ready_4_0_out, ready_4_1_out, ready_4_2_out, ready_4_3_out, ready_4_4_out, ready_4_5_out,
                    ready_5_0_out, ready_5_1_out, ready_5_2_out, ready_5_3_out, ready_5_4_out, ready_5_5_out,

    output bit      error_detected_out
);

    // Busy signals
    bit busy_0_0, busy_0_1, busy_0_2, busy_0_3, busy_0_4, busy_0_5,
        busy_1_0, busy_1_1, busy_1_2, busy_1_3, busy_1_4, busy_1_5,
        busy_2_0, busy_2_1, busy_2_2, busy_2_3, busy_2_4, busy_2_5,
        busy_3_0, busy_3_1, busy_3_2, busy_3_3, busy_3_4, busy_3_5,
        busy_4_0, busy_4_1, busy_4_2, busy_4_3, busy_4_4, busy_4_5,
        busy_5_0, busy_5_1, busy_5_2, busy_5_3, busy_5_4, busy_5_5;

    // Request signals - float 0 direction
    bit float_0_req_0_0, float_0_req_0_1, float_0_req_0_2, float_0_req_0_3, float_0_req_0_4, float_0_req_0_5,
        float_0_req_1_0, float_0_req_1_1, float_0_req_1_2, float_0_req_1_3, float_0_req_1_4, float_0_req_1_5,
        float_0_req_2_0, float_0_req_2_1, float_0_req_2_2, float_0_req_2_3, float_0_req_2_4, float_0_req_2_5,
        float_0_req_3_0, float_0_req_3_1, float_0_req_3_2, float_0_req_3_3, float_0_req_3_4, float_0_req_3_5,
        float_0_req_4_0, float_0_req_4_1, float_0_req_4_2, float_0_req_4_3, float_0_req_4_4, float_0_req_4_5,
        float_0_req_5_0, float_0_req_5_1, float_0_req_5_2, float_0_req_5_3, float_0_req_5_4, float_0_req_5_5;

    // Request signals - float 1 direction
    bit float_1_req_0_0, float_1_req_0_1, float_1_req_0_2, float_1_req_0_3, float_1_req_0_4, float_1_req_0_5,
        float_1_req_1_0, float_1_req_1_1, float_1_req_1_2, float_1_req_1_3, float_1_req_1_4, float_1_req_1_5,
        float_1_req_2_0, float_1_req_2_1, float_1_req_2_2, float_1_req_2_3, float_1_req_2_4, float_1_req_2_5,
        float_1_req_3_0, float_1_req_3_1, float_1_req_3_2, float_1_req_3_3, float_1_req_3_4, float_1_req_3_5,
        float_1_req_4_0, float_1_req_4_1, float_1_req_4_2, float_1_req_4_3, float_1_req_4_4, float_1_req_4_5,
        float_1_req_5_0, float_1_req_5_1, float_1_req_5_2, float_1_req_5_3, float_1_req_5_4, float_1_req_5_5;

    // Data signals - float 0 direction
    float_sp float_0_data_0_0, float_0_data_0_1, float_0_data_0_2, float_0_data_0_3, float_0_data_0_4, float_0_data_0_5,
             float_0_data_1_0, float_0_data_1_1, float_0_data_1_2, float_0_data_1_3, float_0_data_1_4, float_0_data_1_5,
             float_0_data_2_0, float_0_data_2_1, float_0_data_2_2, float_0_data_2_3, float_0_data_2_4, float_0_data_2_5,
             float_0_data_3_0, float_0_data_3_1, float_0_data_3_2, float_0_data_3_3, float_0_data_3_4, float_0_data_3_5,
             float_0_data_4_0, float_0_data_4_1, float_0_data_4_2, float_0_data_4_3, float_0_data_4_4, float_0_data_4_5,
             float_0_data_5_0, float_0_data_5_1, float_0_data_5_2, float_0_data_5_3, float_0_data_5_4, float_0_data_5_5;

    // Data signals - float 1 direction
    float_sp float_1_data_0_0, float_1_data_0_1, float_1_data_0_2, float_1_data_0_3, float_1_data_0_4, float_1_data_0_5,
             float_1_data_1_0, float_1_data_1_1, float_1_data_1_2, float_1_data_1_3, float_1_data_1_4, float_1_data_1_5,
             float_1_data_2_0, float_1_data_2_1, float_1_data_2_2, float_1_data_2_3, float_1_data_2_4, float_1_data_2_5,
             float_1_data_3_0, float_1_data_3_1, float_1_data_3_2, float_1_data_3_3, float_1_data_3_4, float_1_data_3_5,
             float_1_data_4_0, float_1_data_4_1, float_1_data_4_2, float_1_data_4_3, float_1_data_4_4, float_1_data_4_5,
             float_1_data_5_0, float_1_data_5_1, float_1_data_5_2, float_1_data_5_3, float_1_data_5_4, float_1_data_5_5;

    // Individual unit results
    float_sp result_0_0, result_0_1, result_0_2, result_0_3, result_0_4, result_0_5,
             result_1_0, result_1_1, result_1_2, result_1_3, result_1_4, result_1_5,
             result_2_0, result_2_1, result_2_2, result_2_3, result_2_4, result_2_5,
             result_3_0, result_3_1, result_3_2, result_3_3, result_3_4, result_3_5,
             result_4_0, result_4_1, result_4_2, result_4_3, result_4_4, result_4_5,
             result_5_0, result_5_1, result_5_2, result_5_3, result_5_4, result_5_5;

    // Output ready signals
    bit ready_0_0, ready_0_1, ready_0_2, ready_0_3, ready_0_4, ready_0_5,
        ready_1_0, ready_1_1, ready_1_2, ready_1_3, ready_1_4, ready_1_5,
        ready_2_0, ready_2_1, ready_2_2, ready_2_3, ready_2_4, ready_2_5,
        ready_3_0, ready_3_1, ready_3_2, ready_3_3, ready_3_4, ready_3_5,
        ready_4_0, ready_4_1, ready_4_2, ready_4_3, ready_4_4, ready_4_5,
        ready_5_0, ready_5_1, ready_5_2, ready_5_3, ready_5_4, ready_5_5;

    // Error signals
    bit error_0_0, error_0_1, error_0_2, error_0_3, error_0_4, error_0_5,
        error_1_0, error_1_1, error_1_2, error_1_3, error_1_4, error_1_5,
        error_2_0, error_2_1, error_2_2, error_2_3, error_2_4, error_2_5,
        error_3_0, error_3_1, error_3_2, error_3_3, error_3_4, error_3_5,
        error_4_0, error_4_1, error_4_2, error_4_3, error_4_4, error_4_5,
        error_5_0, error_5_1, error_5_2, error_5_3, error_5_4, error_5_5;

    // Signal I/O
    assign busy_0_0_out = busy_0_0;
    assign busy_0_1_out = busy_0_1;
    assign busy_0_2_out = busy_0_2;
    assign busy_0_3_out = busy_0_3;
    assign busy_0_4_out = busy_0_4;
    assign busy_0_5_out = busy_0_5;
    assign busy_1_0_out = busy_1_0;
    assign busy_1_5_out = busy_1_5;
    assign busy_2_0_out = busy_2_0;
    assign busy_2_5_out = busy_2_5;
    assign busy_3_0_out = busy_3_0;
    assign busy_3_5_out = busy_3_5;
    assign busy_4_0_out = busy_4_0;
    assign busy_4_5_out = busy_4_5;
    assign busy_5_0_out = busy_5_0;
    assign busy_5_1_out = busy_5_1;
    assign busy_5_2_out = busy_5_2;
    assign busy_5_3_out = busy_5_3;
    assign busy_5_4_out = busy_5_4;
    assign busy_5_5_out = busy_5_5;

    assign float_0_req_0_0 = float_0_req_0_0_in;
    assign float_0_req_0_5 = float_0_req_0_5_in;
    assign float_0_req_1_0 = float_0_req_1_0_in;
    assign float_0_req_1_5 = float_0_req_1_5_in;
    assign float_0_req_2_0 = float_0_req_2_0_in;
    assign float_0_req_2_5 = float_0_req_2_5_in;
    assign float_0_req_3_0 = float_0_req_3_0_in;
    assign float_0_req_3_5 = float_0_req_3_5_in;
    assign float_0_req_4_0 = float_0_req_4_0_in;
    assign float_0_req_4_5 = float_0_req_4_5_in;
    assign float_0_req_5_0 = float_0_req_5_0_in;
    assign float_0_req_5_5 = float_0_req_5_5_in;

    assign float_1_req_0_0 = float_1_req_0_0_in;
    assign float_1_req_0_1 = float_1_req_0_1_in;
    assign float_1_req_0_2 = float_1_req_0_2_in;
    assign float_1_req_0_3 = float_1_req_0_3_in;
    assign float_1_req_0_4 = float_1_req_0_4_in;
    assign float_1_req_0_5 = float_1_req_0_5_in;
    assign float_1_req_5_0 = float_1_req_5_0_in;
    assign float_1_req_5_1 = float_1_req_5_1_in;
    assign float_1_req_5_2 = float_1_req_5_2_in;
    assign float_1_req_5_3 = float_1_req_5_3_in;
    assign float_1_req_5_4 = float_1_req_5_4_in;
    assign float_1_req_5_5 = float_1_req_5_5_in;

    assign float_0_data_0_0 = float_0_data_0_0_in;
    assign float_0_data_0_5 = float_0_data_0_5_in;
    assign float_0_data_1_0 = float_0_data_1_0_in;
    assign float_0_data_1_5 = float_0_data_1_5_in;
    assign float_0_data_2_0 = float_0_data_2_0_in;
    assign float_0_data_2_5 = float_0_data_2_5_in;
    assign float_0_data_3_0 = float_0_data_3_0_in;
    assign float_0_data_3_5 = float_0_data_3_5_in;
    assign float_0_data_4_0 = float_0_data_4_0_in;
    assign float_0_data_4_5 = float_0_data_4_5_in;
    assign float_0_data_5_0 = float_0_data_5_0_in;
    assign float_0_data_5_5 = float_0_data_5_5_in;

    assign float_1_data_0_0 = float_1_data_0_0_in;
    assign float_1_data_0_1 = float_1_data_0_1_in;
    assign float_1_data_0_2 = float_1_data_0_2_in;
    assign float_1_data_0_3 = float_1_data_0_3_in;
    assign float_1_data_0_4 = float_1_data_0_4_in;
    assign float_1_data_0_5 = float_1_data_0_5_in;
    assign float_1_data_5_0 = float_1_data_5_0_in;
    assign float_1_data_5_1 = float_1_data_5_1_in;
    assign float_1_data_5_2 = float_1_data_5_2_in;
    assign float_1_data_5_3 = float_1_data_5_3_in;
    assign float_1_data_5_4 = float_1_data_5_4_in;
    assign float_1_data_5_5 = float_1_data_5_5_in;

    assign result_0_0_out = result_0_0;
    assign result_0_1_out = result_0_1;
    assign result_0_2_out = result_0_2;
    assign result_0_3_out = result_0_3;
    assign result_0_4_out = result_0_4;
    assign result_0_5_out = result_0_5;
    assign result_1_0_out = result_1_0;
    assign result_1_1_out = result_1_1;
    assign result_1_2_out = result_1_2;
    assign result_1_3_out = result_1_3;
    assign result_1_4_out = result_1_4;
    assign result_1_5_out = result_1_5;
    assign result_2_0_out = result_2_0;
    assign result_2_1_out = result_2_1;
    assign result_2_2_out = result_2_2;
    assign result_2_3_out = result_2_3;
    assign result_2_4_out = result_2_4;
    assign result_2_5_out = result_2_5;
    assign result_3_0_out = result_3_0;
    assign result_3_1_out = result_3_1;
    assign result_3_2_out = result_3_2;
    assign result_3_3_out = result_3_3;
    assign result_3_4_out = result_3_4;
    assign result_3_5_out = result_3_5;
    assign result_4_0_out = result_4_0;
    assign result_4_1_out = result_4_1;
    assign result_4_2_out = result_4_2;
    assign result_4_3_out = result_4_3;
    assign result_4_4_out = result_4_4;
    assign result_4_5_out = result_4_5;
    assign result_5_0_out = result_5_0;
    assign result_5_1_out = result_5_1;
    assign result_5_2_out = result_5_2;
    assign result_5_3_out = result_5_3;
    assign result_5_4_out = result_5_4;
    assign result_5_5_out = result_5_5;

    assign ready_0_0_out = ready_0_0;
    assign ready_0_1_out = ready_0_1;
    assign ready_0_2_out = ready_0_2;
    assign ready_0_3_out = ready_0_3;
    assign ready_0_4_out = ready_0_4;
    assign ready_0_5_out = ready_0_5;
    assign ready_1_0_out = ready_1_0;
    assign ready_1_1_out = ready_1_1;
    assign ready_1_2_out = ready_1_2;
    assign ready_1_3_out = ready_1_3;
    assign ready_1_4_out = ready_1_4;
    assign ready_1_5_out = ready_1_5;
    assign ready_2_0_out = ready_2_0;
    assign ready_2_1_out = ready_2_1;
    assign ready_2_2_out = ready_2_2;
    assign ready_2_3_out = ready_2_3;
    assign ready_2_4_out = ready_2_4;
    assign ready_2_5_out = ready_2_5;
    assign ready_3_0_out = ready_3_0;
    assign ready_3_1_out = ready_3_1;
    assign ready_3_2_out = ready_3_2;
    assign ready_3_3_out = ready_3_3;
    assign ready_3_4_out = ready_3_4;
    assign ready_3_5_out = ready_3_5;
    assign ready_4_0_out = ready_4_0;
    assign ready_4_1_out = ready_4_1;
    assign ready_4_2_out = ready_4_2;
    assign ready_4_3_out = ready_4_3;
    assign ready_4_4_out = ready_4_4;
    assign ready_4_5_out = ready_4_5;
    assign ready_5_0_out = ready_5_0;
    assign ready_5_1_out = ready_5_1;
    assign ready_5_2_out = ready_5_2;
    assign ready_5_3_out = ready_5_3;
    assign ready_5_4_out = ready_5_4;
    assign ready_5_5_out = ready_5_5;

    assign error_detected = error_0_0 | error_0_1 | error_0_2 | error_0_3 | error_0_4 | error_0_5 | 
                            error_1_0 | error_1_1 | error_1_2 | error_1_3 | error_1_4 | error_1_5 | 
                            error_2_0 | error_2_1 | error_2_2 | error_2_3 | error_2_4 | error_2_5 |
                            error_3_0 | error_3_1 | error_3_2 | error_3_3 | error_3_4 | error_3_5 |
                            error_4_0 | error_4_1 | error_4_2 | error_4_3 | error_4_4 | error_4_5 |
                            error_5_0 | error_5_1 | error_5_2 | error_5_3 | error_5_4 | error_5_5;

    // FMA units
    fpu_fma fma_0_0 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_0_1),
        .float_1_busy_in    (busy_1_0),
        .busy_out           (busy_0_0),

        .float_0_req_in     (float_0_req_0_0),
        .float_0_req_out    (float_0_req_0_1),
        .float_1_req_in     (float_1_req_0_0),
        .float_1_req_out    (float_1_req_1_0),

        .float_0_in         (float_0_data_0_0),
        .float_0_out        (float_0_data_0_1),
        .float_1_in         (float_1_data_0_0),
        .float_1_out        (float_1_data_1_0),

        .float_answer_out   (result_0_0),
        .ready_answer_out   (ready_0_0),
        .error_out          (error_0_0)
    );

    fpu_fma fma_0_1 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_0_2),
        .float_1_busy_in    (busy_1_1),
        .busy_out           (busy_0_1),

        .float_0_req_in     (float_0_req_0_1),
        .float_0_req_out    (float_0_req_0_2),
        .float_1_req_in     (float_1_req_0_1),
        .float_1_req_out    (float_1_req_1_1),

        .float_0_in         (float_0_data_0_1),
        .float_0_out        (float_0_data_0_2),
        .float_1_in         (float_1_data_0_1),
        .float_1_out        (float_1_data_1_1),

        .float_answer_out   (result_0_1),
        .ready_answer_out   (ready_0_1),
        .error_out          (error_0_1)
    );

    fpu_fma fma_0_2 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_1_2),
        .busy_out           (busy_0_2),

        .float_0_req_in     (float_0_req_0_2),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_0_2),
        .float_1_req_out    (float_1_req_1_2),

        .float_0_in         (float_0_data_0_2),
        .float_0_out        (),
        .float_1_in         (float_1_data_0_2),
        .float_1_out        (float_1_data_1_2),

        .float_answer_out   (result_0_2),
        .ready_answer_out   (ready_0_2),
        .error_out          (error_0_2)
    );

    fpu_fma fma_0_3 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_1_3),
        .busy_out           (busy_0_3),

        .float_0_req_in     (float_0_req_0_3),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_0_3),
        .float_1_req_out    (float_1_req_1_3),

        .float_0_in         (float_0_data_0_3),
        .float_0_out        (),
        .float_1_in         (float_1_data_0_3),
        .float_1_out        (float_1_data_1_3),

        .float_answer_out   (result_0_3),
        .ready_answer_out   (ready_0_3),
        .error_out          (error_0_3)
    );

    fpu_fma fma_0_4 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_0_3),
        .float_1_busy_in    (busy_1_4),
        .busy_out           (busy_0_4),

        .float_0_req_in     (float_0_req_0_4),
        .float_0_req_out    (float_0_req_0_3),
        .float_1_req_in     (float_1_req_0_4),
        .float_1_req_out    (float_1_req_1_4),

        .float_0_in         (float_0_data_0_4),
        .float_0_out        (float_0_data_0_3),
        .float_1_in         (float_1_data_0_4),
        .float_1_out        (float_1_data_1_4),

        .float_answer_out   (result_0_4),
        .ready_answer_out   (ready_0_4),
        .error_out          (error_0_4)
    );

    fpu_fma fma_0_5 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_0_4),
        .float_1_busy_in    (busy_1_5),
        .busy_out           (busy_0_5),

        .float_0_req_in     (float_0_req_0_5),
        .float_0_req_out    (float_0_req_0_4),
        .float_1_req_in     (float_1_req_0_5),
        .float_1_req_out    (float_1_req_1_5),

        .float_0_in         (float_0_data_0_5),
        .float_0_out        (float_0_data_0_4),
        .float_1_in         (float_1_data_0_5),
        .float_1_out        (float_1_data_1_5),

        .float_answer_out   (result_0_5),
        .ready_answer_out   (ready_0_5),
        .error_out          (error_0_5)
    );

    fpu_fma fma_1_0 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_1_1),
        .float_1_busy_in    (busy_2_0),
        .busy_out           (busy_1_0),

        .float_0_req_in     (float_0_req_1_0),
        .float_0_req_out    (float_0_req_1_1),
        .float_1_req_in     (float_1_req_1_0),
        .float_1_req_out    (float_1_req_2_0),

        .float_0_in         (float_0_data_1_0),
        .float_0_out        (float_0_data_1_1),
        .float_1_in         (float_1_data_1_0),
        .float_1_out        (float_1_data_2_0),

        .float_answer_out   (result_1_0),
        .ready_answer_out   (ready_1_0),
        .error_out          (error_1_0)
    );

    fpu_fma fma_1_1 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_1_2),
        .float_1_busy_in    (busy_2_1),
        .busy_out           (busy_1_1),

        .float_0_req_in     (float_0_req_1_1),
        .float_0_req_out    (float_0_req_1_2),
        .float_1_req_in     (float_1_req_1_1),
        .float_1_req_out    (float_1_req_2_1),

        .float_0_in         (float_0_data_1_1),
        .float_0_out        (float_0_data_1_2),
        .float_1_in         (float_1_data_1_1),
        .float_1_out        (float_1_data_2_1),

        .float_answer_out   (result_1_1),
        .ready_answer_out   (ready_1_1),
        .error_out          (error_1_1)
    );

    fpu_fma fma_1_2 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_2_2),
        .busy_out           (busy_1_2),

        .float_0_req_in     (float_0_req_1_2),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_1_2),
        .float_1_req_out    (float_1_req_2_2),

        .float_0_in         (float_0_data_1_2),
        .float_0_out        (),
        .float_1_in         (float_1_data_1_2),
        .float_1_out        (float_1_data_2_2),

        .float_answer_out   (result_1_2),
        .ready_answer_out   (ready_1_2),
        .error_out          (error_1_2)
    );

    fpu_fma fma_1_3 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_2_3),
        .busy_out           (busy_1_3),

        .float_0_req_in     (float_0_req_1_3),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_1_3),
        .float_1_req_out    (float_1_req_2_3),

        .float_0_in         (float_0_data_1_3),
        .float_0_out        (),
        .float_1_in         (float_1_data_1_3),
        .float_1_out        (float_1_data_2_3),

        .float_answer_out   (result_1_3),
        .ready_answer_out   (ready_1_3),
        .error_out          (error_1_3)
    );

    fpu_fma fma_1_4 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_1_3),
        .float_1_busy_in    (busy_2_4),
        .busy_out           (busy_1_4),

        .float_0_req_in     (float_0_req_1_4),
        .float_0_req_out    (float_0_req_1_3),
        .float_1_req_in     (float_1_req_1_4),
        .float_1_req_out    (float_1_req_2_4),

        .float_0_in         (float_0_data_1_4),
        .float_0_out        (float_0_data_1_3),
        .float_1_in         (float_1_data_1_4),
        .float_1_out        (float_1_data_2_4),

        .float_answer_out   (result_1_4),
        .ready_answer_out   (ready_1_4),
        .error_out          (error_1_4)
    );

    fpu_fma fma_1_5 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_1_4),
        .float_1_busy_in    (busy_2_5),
        .busy_out           (busy_1_5),

        .float_0_req_in     (float_0_req_1_5),
        .float_0_req_out    (float_0_req_1_4),
        .float_1_req_in     (float_1_req_1_5),
        .float_1_req_out    (float_1_req_2_5),

        .float_0_in         (float_0_data_1_5),
        .float_0_out        (float_0_data_1_4),
        .float_1_in         (float_1_data_1_5),
        .float_1_out        (float_1_data_2_5),

        .float_answer_out   (result_1_5),
        .ready_answer_out   (ready_1_5),
        .error_out          (error_1_5)
    );

    fpu_fma fma_2_0 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_2_1),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_2_0),

        .float_0_req_in     (float_0_req_2_0),
        .float_0_req_out    (float_0_req_2_1),
        .float_1_req_in     (float_1_req_2_0),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_2_0),
        .float_0_out        (float_0_data_2_1),
        .float_1_in         (float_1_data_2_0),
        .float_1_out        (),

        .float_answer_out   (result_2_0),
        .ready_answer_out   (ready_2_0),
        .error_out          (error_2_0)
    );

    fpu_fma fma_2_1 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_2_2),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_2_1),

        .float_0_req_in     (float_0_req_2_1),
        .float_0_req_out    (float_0_req_2_2),
        .float_1_req_in     (float_1_req_2_1),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_2_1),
        .float_0_out        (float_0_data_2_2),
        .float_1_in         (float_1_data_2_1),
        .float_1_out        (),

        .float_answer_out   (result_2_1),
        .ready_answer_out   (ready_2_1),
        .error_out          (error_2_1)
    );

    fpu_fma fma_2_2 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_2_2),

        .float_0_req_in     (float_0_req_2_2),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_2_2),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_2_2),
        .float_0_out        (),
        .float_1_in         (float_1_data_2_2),
        .float_1_out        (),

        .float_answer_out   (result_2_2),
        .ready_answer_out   (ready_2_2),
        .error_out          (error_2_2)
    );

    fpu_fma fma_2_3 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_2_3),

        .float_0_req_in     (float_0_req_2_3),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_2_3),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_2_3),
        .float_0_out        (),
        .float_1_in         (float_1_data_2_3),
        .float_1_out        (),

        .float_answer_out   (result_2_3),
        .ready_answer_out   (ready_2_3),
        .error_out          (error_2_3)
    );

    fpu_fma fma_2_4 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_2_3),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_2_4),

        .float_0_req_in     (float_0_req_2_4),
        .float_0_req_out    (float_0_req_2_3),
        .float_1_req_in     (float_1_req_2_4),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_2_4),
        .float_0_out        (float_0_data_2_3),
        .float_1_in         (float_1_data_2_4),
        .float_1_out        (),

        .float_answer_out   (result_2_4),
        .ready_answer_out   (ready_2_4),
        .error_out          (error_2_4)
    );

    fpu_fma fma_2_5 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_2_4),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_2_5),

        .float_0_req_in     (float_0_req_2_5),
        .float_0_req_out    (float_0_req_2_4),
        .float_1_req_in     (float_1_req_2_5),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_2_5),
        .float_0_out        (float_0_data_2_4),
        .float_1_in         (float_1_data_2_5),
        .float_1_out        (),

        .float_answer_out   (result_2_5),
        .ready_answer_out   (ready_2_5),
        .error_out          (error_2_5)
    );

    fpu_fma fma_3_0 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_3_1),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_3_0),

        .float_0_req_in     (float_0_req_3_0),
        .float_0_req_out    (float_0_req_3_1),
        .float_1_req_in     (float_1_req_3_0),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_3_0),
        .float_0_out        (float_0_data_3_1),
        .float_1_in         (float_1_data_3_0),
        .float_1_out        (),

        .float_answer_out   (result_3_0),
        .ready_answer_out   (ready_3_0),
        .error_out          (error_3_0)
    );

    fpu_fma fma_3_1 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_3_2),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_3_1),

        .float_0_req_in     (float_0_req_3_1),
        .float_0_req_out    (float_0_req_3_2),
        .float_1_req_in     (float_1_req_3_1),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_3_1),
        .float_0_out        (float_0_data_3_2),
        .float_1_in         (float_1_data_3_1),
        .float_1_out        (),

        .float_answer_out   (result_3_1),
        .ready_answer_out   (ready_3_1),
        .error_out          (error_3_1)
    );

    fpu_fma fma_3_2 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_3_2),

        .float_0_req_in     (float_0_req_3_2),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_3_2),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_3_2),
        .float_0_out        (),
        .float_1_in         (float_1_data_3_2),
        .float_1_out        (),

        .float_answer_out   (result_3_2),
        .ready_answer_out   (ready_3_2),
        .error_out          (error_3_2)
    );

    fpu_fma fma_3_3 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_3_3),

        .float_0_req_in     (float_0_req_3_3),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_3_3),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_3_3),
        .float_0_out        (),
        .float_1_in         (float_1_data_3_3),
        .float_1_out        (),

        .float_answer_out   (result_3_3),
        .ready_answer_out   (ready_3_3),
        .error_out          (error_3_3)
    );

    fpu_fma fma_3_4 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_3_3),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_3_4),

        .float_0_req_in     (float_0_req_3_4),
        .float_0_req_out    (float_0_req_3_3),
        .float_1_req_in     (float_1_req_3_4),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_3_4),
        .float_0_out        (float_0_data_3_3),
        .float_1_in         (float_1_data_3_4),
        .float_1_out        (),

        .float_answer_out   (result_3_4),
        .ready_answer_out   (ready_3_4),
        .error_out          (error_3_4)
    );

    fpu_fma fma_3_5 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_3_4),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_3_5),

        .float_0_req_in     (float_0_req_3_5),
        .float_0_req_out    (float_0_req_3_4),
        .float_1_req_in     (float_1_req_3_5),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_3_5),
        .float_0_out        (float_0_data_3_4),
        .float_1_in         (float_1_data_3_5),
        .float_1_out        (),

        .float_answer_out   (result_3_5),
        .ready_answer_out   (ready_3_5),
        .error_out          (error_3_5)
    );

    fpu_fma fma_4_0 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_4_1),
        .float_1_busy_in    (busy_3_0),
        .busy_out           (busy_4_0),

        .float_0_req_in     (float_0_req_4_0),
        .float_0_req_out    (float_0_req_4_1),
        .float_1_req_in     (float_1_req_4_0),
        .float_1_req_out    (float_1_req_3_0),

        .float_0_in         (float_0_data_4_0),
        .float_0_out        (float_0_data_4_1),
        .float_1_in         (float_1_data_4_0),
        .float_1_out        (float_1_data_3_0),

        .float_answer_out   (result_4_0),
        .ready_answer_out   (ready_4_0),
        .error_out          (error_4_0)
    );

    fpu_fma fma_4_1 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_4_2),
        .float_1_busy_in    (busy_3_1),
        .busy_out           (busy_4_1),

        .float_0_req_in     (float_0_req_4_1),
        .float_0_req_out    (float_0_req_4_2),
        .float_1_req_in     (float_1_req_4_1),
        .float_1_req_out    (float_1_req_3_1),

        .float_0_in         (float_0_data_4_1),
        .float_0_out        (float_0_data_4_2),
        .float_1_in         (float_1_data_4_1),
        .float_1_out        (float_1_data_3_1),

        .float_answer_out   (result_4_1),
        .ready_answer_out   (ready_4_1),
        .error_out          (error_4_1)
    );

    fpu_fma fma_4_2 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_3_2),
        .busy_out           (busy_4_2),

        .float_0_req_in     (float_0_req_4_2),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_4_2),
        .float_1_req_out    (float_1_req_3_2),

        .float_0_in         (float_0_data_4_2),
        .float_0_out        (),
        .float_1_in         (float_1_data_4_2),
        .float_1_out        (float_1_data_3_2),

        .float_answer_out   (result_4_2),
        .ready_answer_out   (ready_4_2),
        .error_out          (error_4_2)
    );

fpu_fma fma_4_3 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_3_3),
        .busy_out           (busy_4_3),

        .float_0_req_in     (float_0_req_4_3),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_4_3),
        .float_1_req_out    (float_1_req_3_3),

        .float_0_in         (float_0_data_4_3),
        .float_0_out        (),
        .float_1_in         (float_1_data_4_3),
        .float_1_out        (float_1_data_3_3),

        .float_answer_out   (result_4_3),
        .ready_answer_out   (ready_4_3),
        .error_out          (error_4_3)
    );

    fpu_fma fma_4_4 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_4_3),
        .float_1_busy_in    (busy_3_4),
        .busy_out           (busy_4_4),

        .float_0_req_in     (float_0_req_4_4),
        .float_0_req_out    (float_0_req_4_3),
        .float_1_req_in     (float_1_req_4_4),
        .float_1_req_out    (float_1_req_3_4),

        .float_0_in         (float_0_data_4_4),
        .float_0_out        (float_0_data_4_3),
        .float_1_in         (float_1_data_4_4),
        .float_1_out        (float_1_data_3_4),

        .float_answer_out   (result_4_4),
        .ready_answer_out   (ready_4_4),
        .error_out          (error_4_4)
    );

    fpu_fma fma_4_5 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_4_4),
        .float_1_busy_in    (busy_3_5),
        .busy_out           (busy_4_5),

        .float_0_req_in     (float_0_req_4_5),
        .float_0_req_out    (float_0_req_4_4),
        .float_1_req_in     (float_1_req_4_5),
        .float_1_req_out    (float_1_req_3_5),

        .float_0_in         (float_0_data_4_5),
        .float_0_out        (float_0_data_4_4),
        .float_1_in         (float_1_data_4_5),
        .float_1_out        (float_1_data_3_5),

        .float_answer_out   (result_4_5),
        .ready_answer_out   (ready_4_5),
        .error_out          (error_4_5)
    );

    fpu_fma fma_5_0 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_5_1),
        .float_1_busy_in    (busy_4_0),
        .busy_out           (busy_5_0),

        .float_0_req_in     (float_0_req_5_0),
        .float_0_req_out    (float_0_req_5_1),
        .float_1_req_in     (float_1_req_5_0),
        .float_1_req_out    (float_1_req_4_0),

        .float_0_in         (float_0_data_5_0),
        .float_0_out        (float_0_data_5_1),
        .float_1_in         (float_1_data_5_0),
        .float_1_out        (float_1_data_4_0),

        .float_answer_out   (result_5_0),
        .ready_answer_out   (ready_5_0),
        .error_out          (error_5_0)
    );

    fpu_fma fma_5_1 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_5_2),
        .float_1_busy_in    (busy_4_1),
        .busy_out           (busy_5_1),

        .float_0_req_in     (float_0_req_5_1),
        .float_0_req_out    (float_0_req_5_2),
        .float_1_req_in     (float_1_req_5_1),
        .float_1_req_out    (float_1_req_4_1),

        .float_0_in         (float_0_data_5_1),
        .float_0_out        (float_0_data_5_2),
        .float_1_in         (float_1_data_5_1),
        .float_1_out        (float_1_data_4_1),

        .float_answer_out   (result_5_1),
        .ready_answer_out   (ready_5_1),
        .error_out          (error_5_1)
    );

    fpu_fma fma_5_2 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_4_2),
        .busy_out           (busy_5_2),

        .float_0_req_in     (float_0_req_5_2),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_5_2),
        .float_1_req_out    (float_1_req_4_2),

        .float_0_in         (float_0_data_5_2),
        .float_0_out        (),
        .float_1_in         (float_1_data_5_2),
        .float_1_out        (float_1_data_4_2),

        .float_answer_out   (result_5_2),
        .ready_answer_out   (ready_5_2),
        .error_out          (error_5_2)
    );

    fpu_fma fma_5_3 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_4_3),
        .busy_out           (busy_5_3),

        .float_0_req_in     (float_0_req_5_3),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_5_3),
        .float_1_req_out    (float_1_req_4_3),

        .float_0_in         (float_0_data_5_3),
        .float_0_out        (),
        .float_1_in         (float_1_data_5_3),
        .float_1_out        (float_1_data_4_3),

        .float_answer_out   (result_5_3),
        .ready_answer_out   (ready_5_3),
        .error_out          (error_5_3)
    );

    fpu_fma fma_5_4 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_5_3),
        .float_1_busy_in    (busy_4_4),
        .busy_out           (busy_5_4),

        .float_0_req_in     (float_0_req_5_4),
        .float_0_req_out    (float_0_req_5_3),
        .float_1_req_in     (float_1_req_5_4),
        .float_1_req_out    (float_1_req_4_4),

        .float_0_in         (float_0_data_5_4),
        .float_0_out        (float_0_data_5_3),
        .float_1_in         (float_1_data_5_4),
        .float_1_out        (float_1_data_4_4),

        .float_answer_out   (result_5_4),
        .ready_answer_out   (ready_5_4),
        .error_out          (error_5_4)
    );

    fpu_fma fma_5_5 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_5_4),
        .float_1_busy_in    (busy_4_5),
        .busy_out           (busy_5_5),

        .float_0_req_in     (float_0_req_5_5),
        .float_0_req_out    (float_0_req_5_4),
        .float_1_req_in     (float_1_req_5_5),
        .float_1_req_out    (float_1_req_4_5),

        .float_0_in         (float_0_data_5_5),
        .float_0_out        (float_0_data_5_4),
        .float_1_in         (float_1_data_5_5),
        .float_1_out        (float_1_data_4_5),

        .float_answer_out   (result_5_5),
        .ready_answer_out   (ready_5_5),
        .error_out          (error_5_5)
    );

endmodule : fma_cluster
