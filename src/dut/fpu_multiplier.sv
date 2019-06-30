// fpu_multiplier.sv
// ----------------------------------------------------------------------------
//   Author: Jonathan P Dawson 2013
// Modified: Alex Olson
//     Date: June 2019
//   Source: https://github.com/dawsonjon/fpu
//
// Description:
// ----------------------------------------------------------------------------
// Synthesizable method of IEEE 754 single-precision multiplication with
// automatic normalization of numbers.

import global_defs::*;

module fpu_multiplier
(
    input         clk,
    input         rst,
    input  [31:0] input_a,
    input  [31:0] input_b,
    input         input_stb,
    input         output_ack,
    output [31:0] output_z,
    output        output_stb,
    output        input_ack
);

    typedef enum logic [3:0] {
        get_input,
        unpack,
        special_cases,
        normalize_in,
        multiply_0,
        multiply_1,
        normalize_1,
        normalize_2,
        round,
        pack,
        put_z
    } state_t;

    state_t state=get_input;

    logic        s_output_stb;
    logic [31:0] s_output_z;
    logic        s_input_ack;

    logic [31:0] a, b, z;
    logic [23:0] a_m, b_m, z_m;
    logic [9:0]  a_e, b_e, z_e;
    logic        a_s, b_s, z_s;
    logic        guard, round_bit, sticky;
    logic [49:0] product;

    always @(posedge clk) begin
    
        if (rst) begin
            state <= get_input;
            s_input_ack <= 0;
            s_output_stb <= 0;
        end

        else begin
            unique case(state)
        
                get_input: begin
                    s_input_ack <= 1;
                    if (input_stb) begin
                        a <= input_a;
                        b <= input_b;
                        s_input_ack <= 0;
                        state <= unpack;
                    end
                end

                unpack: begin
                    a_m <= a[22:0];
                    b_m <= b[22:0];
                    a_e <= a[30:23] - 127;
                    b_e <= b[30:23] - 127;
                    a_s <= a[31];
                    b_s <= b[31];
                    state <= special_cases;
                end

                special_cases: begin
                    // If a is NaN or b is NaN return NaN 
                    if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
                        z[31] <= 1;
                        z[30:23] <= 255;
                        z[22] <= 1;
                        z[21:0] <= 0;
                        state <= put_z;
                    end
                    
                    // If a is inf return inf
                    else if (a_e == 128) begin
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 255;
                        z[22:0] <= 0;
                        // If b is zero return NaN
                        if (($signed(b_e) == -127) && (b_m == 0)) begin
                            z[31] <= 1;
                            z[30:23] <= 255;
                            z[22] <= 1;
                            z[21:0] <= 0;
                        end
                        state <= put_z;
                    end
                    
                    // If b is inf return inf
                    else if (b_e == 128) begin
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 255;
                        z[22:0] <= 0;
                        // If a is zero return NaN
                        if (($signed(a_e) == -127) && (a_m == 0)) begin
                            z[31] <= 1;
                            z[30:23] <= 255;
                            z[22] <= 1;
                            z[21:0] <= 0;
                        end
                        state <= put_z;
                    end
                    
                    // If a is zero return zero
                    else if (($signed(a_e) == -127) && (a_m == 0)) begin
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 0;
                        z[22:0] <= 0;
                        state <= put_z;
                    end
                    
                    // If b is zero return zero
                    else if (($signed(b_e) == -127) && (b_m == 0)) begin
                        z[31] <= a_s ^ b_s;
                        z[30:23] <= 0;
                        z[22:0] <= 0;
                        state <= put_z;
                    end
                    
                    // Denormalised Number          
                    else begin
                        // Check a
                        if ($signed(a_e) == -127) begin
                            a_e <= -126;
                        end else begin
                            a_m[23] <= 1;
                        end
                        
                        // Check b
                        if ($signed(b_e) == -127) begin
                            b_e <= -126;
                        end else begin
                            b_m[23] <= 1;
                        end
                        state <= normalize_in;
                    end
                end

                normalize_in: begin
                    if (a_m[23] | b_m[23]) begin
                        state <= multiply_0;
                    end 
                    
                    else begin
                        a_m <= a_m << 1;
                        b_m <= b_m << 1;
                        a_e <= a_e - 1;
                        b_e <= b_e - 1;
                    end
                end

                multiply_0: begin
                    z_s <= a_s ^ b_s;
                    z_e <= a_e + b_e + 1;
                    product <= a_m * b_m * 4;
                    state <= multiply_1;
                end

                multiply_1: begin
                    z_m <= product[49:26];
                    guard <= product[25];
                    round_bit <= product[24];
                    sticky <= (product[23:0] != 0);
                    state <= normalize_1;
                end

                normalize_1: begin
                    if (z_m[23] == 0) begin
                        z_e <= z_e - 1;
                        z_m <= z_m << 1;
                        z_m[0] <= guard;
                        guard <= round_bit;
                        round_bit <= 0;
                    end
                    else begin
                        state <= normalize_2;
                    end
                end

                normalize_2: begin
                    if ($signed(z_e) < -126) begin
                        z_e <= z_e + 1;
                        z_m <= z_m >> 1;
                        guard <= z_m[0];
                        round_bit <= guard;
                        sticky <= sticky | round_bit;
                    end 
                    else begin
                        state <= round;
                    end
                end

                round: begin
                    if (guard && (round_bit | sticky | z_m[0])) begin
                        z_m <= z_m + 1;
                        if (z_m == 24'hffffff) begin
                            z_e <=z_e + 1;
                        end
                    end
                    state <= pack;
                end

                pack: begin
                    z[22:0] <= z_m[22:0];
                    z[30:23] <= z_e[7:0] + 127;
                    z[31] <= z_s;
                    if ($signed(z_e) == -126 && z_m[23] == 0) begin
                        z[30:23] <= 0;
                    end
                    // If overflow occurs, return inf
                    if ($signed(z_e) > 127) begin
                        z[22:0] <= 0;
                        z[30:23] <= 255;
                        z[31] <= z_s;
                    end
                    state <= put_z;
                end

                put_z: begin
                    s_output_stb <= 1;
                    s_output_z <= z;
                    if (output_ack) begin
                        s_output_stb <= 0;
                        state <= get_input;
                    end
                end
            endcase
        end
    end

    assign input_ack = s_input_ack;
    assign output_stb = s_output_stb;
    assign output_z = s_output_z;

endmodule
