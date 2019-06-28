// fpu_adder.sv
// modified from original source:  https://github.com/dawsonjon/fpu

import global_defs::*;

module fpu_adder
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
        align,
        add_0,
        add_1,
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
    logic [26:0] a_m, b_m;
    logic [23:0] z_m;
    logic [9:0]  a_e, b_e, z_e;
    logic        a_s, b_s, z_s;
    logic        guard, round_bit, sticky;
    logic [27:0] sum;

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
                    a_m <= {a[22:0], 3'd0};
                    b_m <= {b[22:0], 3'd0};
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
                        z[31] <= a_s;
                        z[30:23] <= 255;
                        z[22:0] <= 0;
                        // If a is inf and signs don't match return nan
                        if ((b_e == 128) && (a_s != b_s)) begin
                            z[31] <= b_s;
                            z[30:23] <= 255;
                            z[22] <= 1;
                            z[21:0] <= 0;
                        end
                        state <= put_z;
                    end
            
                    // If b is inf return inf
                    else if (b_e == 128) begin
                        z[31] <= b_s;
                        z[30:23] <= 255;
                        z[22:0] <= 0;
                        state <= put_z;
                    end

                    // If a is zero return b
                    else if ((($signed(a_e) == -127) && (a_m == 0)) && (($signed(b_e) == -127) && (b_m == 0))) begin
                        z[31] <= a_s & b_s;
                        z[30:23] <= b_e[7:0] + 127;
                        z[22:0] <= b_m[26:3];
                        state <= put_z;
                    end

                    // If a is zero return b
                    else if (($signed(a_e) == -127) && (a_m == 0)) begin
                        z[31] <= b_s;
                        z[30:23] <= b_e[7:0] + 127;
                        z[22:0] <= b_m[26:3];
                        state <= put_z;
                    end

                    // If b is zero return a
                    else if (($signed(b_e) == -127) && (b_m == 0)) begin
                        z[31] <= a_s;
                        z[30:23] <= a_e[7:0] + 127;
                        z[22:0] <= a_m[26:3];
                        state <= put_z;
                    end

                    // Denormalized Number          
                    else begin
                        // Check a
                        if ($signed(a_e) == -127) begin
                        a_e <= -126;
                        end
                        else begin
                            a_m[26] <= 1;
                        end
                        // Check b
                        if ($signed(b_e) == -127) begin
                            b_e <= -126;
                        end
                        else begin
                            b_m[26] <= 1;
                        end
                        state <= align;
                    end
                end

                align: begin
                    if ($signed(a_e) > $signed(b_e)) begin
                        b_e <= b_e + 1;
                        b_m <= b_m >> 1;
                        b_m[0] <= b_m[0] | b_m[1];
                    end
                    else if ($signed(a_e) < $signed(b_e)) begin
                        a_e <= a_e + 1;
                        a_m <= a_m >> 1;
                        a_m[0] <= a_m[0] | a_m[1];
                    end 
                    else begin
                        state <= add_0;
                    end
                end

                add_0: begin
                    z_e <= a_e;
                    if (a_s == b_s) begin
                        sum <= a_m + b_m;
                        z_s <= a_s;
                    end
                    else begin
                        if (a_m >= b_m) begin
                            sum <= a_m - b_m;
                            z_s <= a_s;
                        end 
                        else begin
                            sum <= b_m - a_m;
                            z_s <= b_s;
                        end
                    end
                    state <= add_1;
                end

                add_1: begin
                    if (sum[27]) begin
                        z_m <= sum[27:4];
                        guard <= sum[3];
                        round_bit <= sum[2];
                        sticky <= sum[1] | sum[0];
                        z_e <= z_e + 1;
                    end 
                    else begin
                        z_m <= sum[26:3];
                        guard <= sum[2];
                        round_bit <= sum[1];
                        sticky <= sum[0];
                    end
                    state <= normalize_1;
                end

                normalize_1: begin
                    if (z_m[23] == 0 && $signed(z_e) > -126) begin
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
                        z[30 : 23] <= 0;
                    end
                    if ($signed(z_e) == -126 && z_m[23:0] == 24'h0) begin
                        z[31] <= 1'b0; // FIX SIGN BUG: -a + a = +0.
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

endmodule : fpu_adder