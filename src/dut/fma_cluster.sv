// fma_cluster.sv
//
//
//                                               MATRIX B (float_1)
//
//                          float_inB0          float_inB1         float_inB2
//
//             float_inA0      fma00 --- float0 --- fma01 --- float1 --- fma02
//                               | \                 | \                 | \
//                          float2  ans0        float3  ans1        float4  ans2                                  ans00   ans01   ans02
//                               |                   |                   |
//  MATRIX A   float_inA1      fma10 --- float5 --- fma11 --- float6 --- fma12            Matrix A * Matrix B  =  ans10   ans11   ans12
//  (float_0)                    | \                 | \                 | \
//                          float7  ans3        float8  ans4        float9  ams5                                  ans20   ans21   ans22
//                               |                   |                   |
//             float_inA2      fma20 --- float10 -- fma21 -- float11 --- fma22
//                                 \                   \                   \
//                                  ans6                ans7                ans8
//
//
// cluster naming convention:  label_i_j
//
//    3x3               4x4
//  x x   x            x x   x x
//  x x   x            x x   x x
//
//  x x   x            x x   x x
//                     x x   x x
//

import global_defs::*;
import mpu_data_types::*;

module fma_cluster (
    input           clk,        // Clock
    input           rst,        // Synchronous reset active high

    output bit      busy_0_0_out, busy_0_1_out, busy_0_2_out, 
                    busy_1_0_out,               busy_1_2_out,
                    busy_2_0_out, busy_2_1_out, busy_2_2_out,

    input  bit      float_0_req_0_0_in, float_0_req_0_2_in,
                    float_0_req_1_0_in, float_0_req_1_2_in,
                    float_0_req_2_0_in, float_0_req_2_2_in,

    input  bit      float_1_req_0_0_in, float_1_req_0_1_in, float_1_req_0_2_in,
                    float_1_req_2_0_in, float_1_req_2_1_in, float_1_req_2_2_in,

    input  float_sp float_0_data_0_0_in, float_0_data_0_2_in,
                    float_0_data_1_0_in, float_0_data_1_2_in,
                    float_0_data_2_0_in, float_0_data_2_2_in,

    input  float_sp float_1_data_0_0_in, float_1_data_0_1_in, float_1_data_0_2_in,
                    float_1_data_2_0_in, float_1_data_2_1_in, float_1_data_2_2_in,

    output float_sp result_0_0_out, result_0_1_out, result_0_2_out,
                    result_1_0_out, result_1_1_out, result_1_2_out,
                    result_2_0_out, result_2_1_out, result_2_2_out, 

    output bit      ready_0_0_out, ready_0_1_out, ready_0_2_out,
                    ready_1_0_out, ready_1_1_out, ready_1_2_out,
                    ready_2_0_out, ready_2_1_out, ready_2_2_out,

    output bit      error_detected_out
);

    // Busy signals
    bit busy_0_0, busy_0_1, busy_0_2, 
        busy_1_0, busy_1_1, busy_1_2,
        busy_2_0, busy_2_1, busy_2_2;

    // Request signals - float 0 direction
    bit float_0_req_0_0, float_0_req_0_1, float_0_req_0_2,
        float_0_req_1_0, float_0_req_1_1, float_0_req_1_2,
        float_0_req_2_0, float_0_req_2_1, float_0_req_2_2;

    // Request signals - float 1 direction
    bit float_1_req_0_0, float_1_req_0_1, float_1_req_0_2,
        float_1_req_1_0, float_1_req_1_1, float_1_req_1_2,
        float_1_req_2_0, float_1_req_2_1, float_1_req_2_2;

    // Data signals - float 0 direction
    float_sp float_0_data_0_0, float_0_data_0_1, float_0_data_0_2,
             float_0_data_1_0, float_0_data_1_1, float_0_data_1_2,
             float_0_data_2_0, float_0_data_2_1, float_0_data_2_2;

    // Data signals - float 1 direction
    float_sp float_1_data_0_0, float_1_data_0_1, float_1_data_0_2,
             float_1_data_1_0, float_1_data_1_1, float_1_data_1_2,
             float_1_data_2_0, float_1_data_2_1, float_1_data_2_2;

    // Individual unit results
    float_sp result_0_0, result_0_1, result_0_2,
             result_1_0, result_1_1, result_1_2,
             result_2_0, result_2_1, result_2_2; 

    // Output ready signals
    bit ready_0_0, ready_0_1, ready_0_2,
        ready_1_0, ready_1_1, ready_1_2,
        ready_2_0, ready_2_1, ready_2_2;

    // Error signals
    bit error_0_0, error_0_1, error_0_2,
        error_1_0, error_1_1, error_1_2,
        error_2_0, error_2_1, error_2_2;

    // Signal I/O
    assign busy_0_0_out = busy_0_0;
    assign busy_0_1_out = busy_0_1;
    assign busy_0_2_out = busy_0_2;
    assign busy_1_0_out = busy_1_0;
    assign busy_1_2_out = busy_1_2;
    assign busy_2_0_out = busy_2_0;
    assign busy_2_1_out = busy_2_1;
    assign busy_2_2_out = busy_2_2;

    assign float_0_req_0_0 = float_0_req_0_0_in;
    assign float_0_req_0_2 = float_0_req_0_2_in;
    assign float_0_req_1_0 = float_0_req_1_0_in;
    assign float_0_req_1_2 = float_0_req_1_2_in;
    assign float_0_req_2_0 = float_0_req_2_0_in;
    assign float_0_req_2_2 = float_0_req_2_2_in;

    assign float_1_req_0_0 = float_1_req_0_0_in;
    assign float_1_req_0_1 = float_1_req_0_1_in;
    assign float_1_req_0_2 = float_1_req_0_2_in;
    assign float_1_req_2_0 = float_1_req_2_0_in;
    assign float_1_req_2_1 = float_1_req_2_1_in;
    assign float_1_req_2_2 = float_1_req_2_2_in;

    assign float_0_data_0_0 = float_0_data_0_0_in;
    assign float_0_data_0_2 = float_0_data_0_2_in;
    assign float_0_data_1_0 = float_0_data_1_0_in;
    assign float_0_data_1_2 = float_0_data_1_2_in;
    assign float_0_data_2_0 = float_0_data_2_0_in;
    assign float_0_data_2_2 = float_0_data_2_2_in;

    assign float_1_data_0_0 = float_1_data_0_0_in;
    assign float_1_data_0_1 = float_1_data_0_1_in;
    assign float_1_data_0_2 = float_1_data_0_2_in;
    assign float_1_data_2_0 = float_1_data_2_0_in;
    assign float_1_data_2_1 = float_1_data_2_1_in;
    assign float_1_data_2_2 = float_1_data_2_2_in;

    assign result_0_0_out = result_0_0;
    assign result_0_1_out = result_0_1;
    assign result_0_2_out = result_0_2;
    assign result_1_0_out = result_1_0;
    assign result_1_1_out = result_1_1;
    assign result_1_2_out = result_1_2;
    assign result_2_0_out = result_2_0;
    assign result_2_1_out = result_2_1;
    assign result_2_2_out = result_2_2;

    assign ready_0_0_out = ready_0_0;
    assign ready_0_1_out = ready_0_1;
    assign ready_0_2_out = ready_0_2;
    assign ready_1_0_out = ready_1_0;
    assign ready_1_1_out = ready_1_1;
    assign ready_1_2_out = ready_1_2;
    assign ready_2_0_out = ready_2_0;
    assign ready_2_1_out = ready_2_1;
    assign ready_2_2_out = ready_2_2;

    assign error_detected = error_0_0 | error_0_1 | error_0_2 | 
                            error_1_0 | error_1_1 | error_1_2 | 
                            error_2_0 | error_2_1 | error_2_2;

    // FMA units
    fma fma_0_0 (
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

    fma fma_0_1 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_1_1),
        .busy_out           (busy_0_1),

        .float_0_req_in     (float_0_req_0_1),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_0_1),
        .float_1_req_out    (float_1_req_1_1),

        .float_0_in         (float_0_data_0_1),
        .float_0_out        (),
        .float_1_in         (float_1_data_0_1),
        .float_1_out        (float_1_data_1_1),

        .float_answer_out   (result_0_1),
        .ready_answer_out   (ready_0_1),
        .error_out          (error_0_1)
    );

    fma fma_0_2 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (busy_1_1),
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

    fma fma_1_0 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (busy_1_1),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_1_0),

        .float_0_req_in     (float_0_req_1_0),
        .float_0_req_out    (float_0_req_1_1),
        .float_1_req_in     (float_1_req_1_0),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_1_0),
        .float_0_out        (float_0_data_1_1),
        .float_1_in         (float_1_data_1_0),
        .float_1_out        (),

        .float_answer_out   (result_1_0),
        .ready_answer_out   (ready_1_0),
        .error_out          (error_1_0)
    );

    // FMA units
    fma fma_1_1 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_1_1),

        .float_0_req_in     (float_0_req_1_1),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_1_1),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_1_1),
        .float_0_out        (),
        .float_1_in         (float_1_data_1_1),
        .float_1_out        (),

        .float_answer_out   (result_1_1),
        .ready_answer_out   (ready_1_1),
        .error_out          (error_1_1)
    );

    fma fma_1_2 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_1_2),

        .float_0_req_in     (float_0_req_1_2),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_1_2),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_1_2),
        .float_0_out        (),
        .float_1_in         (float_1_data_1_2),
        .float_1_out        (),

        .float_answer_out   (result_1_2),
        .ready_answer_out   (ready_1_2),
        .error_out          (error_1_2)
    );

    fma fma_2_0 (
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

    fma fma_2_1 (
        .clk                (clk),
        .rst                (rst),

        .float_0_busy_in    (FALSE),
        .float_1_busy_in    (FALSE),
        .busy_out           (busy_2_1),

        .float_0_req_in     (float_0_req_2_1),
        .float_0_req_out    (),
        .float_1_req_in     (float_1_req_2_1),
        .float_1_req_out    (),

        .float_0_in         (float_0_data_2_1),
        .float_0_out        (),
        .float_1_in         (float_1_data_2_1),
        .float_1_out        (),

        .float_answer_out   (result_2_1),
        .ready_answer_out   (ready_2_1),
        .error_out          (error_2_1)
    );

    fma fma_2_2 (
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

endmodule : fma_cluster
