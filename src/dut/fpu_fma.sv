// fpu_fma.sv
// IEEE-754 floating point Fused Multiply Accumulate

import global_defs::*;
import mpu_data_types::*;

module fma
(
    input           clk, rst, start_in,
    input  float_sp float_in,
    output float_sp float_out,
    output bit      error_out,
    output bit      ready_out
);

    bit error_in;
    internal_float_sp a, b, c, y;         // a * b + c = y
    fma_state_t state, next_state;

    // Check for input errors (denormalized numbers, +infinity, -infinity, NaN)
    assign error_in = ((float_in && !float_in.exponent) || float_in.exponent == '1) ? TRUE : FALSE;

    // State machine driver
    always_ff @(posedge clk) begin
        state <= rst ? IDLE : next_state;
        $strobe(($time/10), " clock cycles \t%s  start: %b  error_in: %b  rst: %b", state, start_in, error_in, rst);
    end

    // Next state logic
    always_comb begin
        unique case (state)
            IDLE: begin
                if (error_in) begin
                    next_state <= ERROR;
                end
                else if (start_in) begin
                    next_state <= LOAD;
                end
                else begin
                    next_state <= IDLE;
                end
            end
            LOAD: begin
                if (error_in) begin
                    next_state <= ERROR;
                end
                else begin
                    next_state <= MULTIPLY;
                end
            end
            MULTIPLY: begin
                if (error_in) begin
                    next_state <= ERROR;
                end
                else begin
                    next_state <= ALIGN;
                end
            end
            ALIGN: begin
                if (!c.exponent && !c.mantissa) begin
                    next_state <= OUTPUT;
                end
                else begin
                    next_state <= ACCUMULATE;
                end
            end
            ACCUMULATE: begin
                next_state <= NORMALIZE;
            end
            NORMALIZE: begin
                next_state <= OUTPUT;
            end
            OUTPUT: begin
                if (($signed(float_out.exponent) > MAX_EXP) || ($signed(float_out.exponent) < MIN_EXP)) begin
                    next_state <= ERROR;
                end
                else begin 
                    next_state <= IDLE;
                end
            end
            ERROR: begin 
                next_state <= IDLE;
            end
        endcase
    end

    // Clocked logic and I/O
    always_ff @(posedge clk) begin
        unique case (state)
            IDLE: begin
                ready_out <= FALSE;
                error_out <= FALSE;
                if (start_in) begin
                    a.sign <= float_in.sign;
                    a.exponent <= float_in.exponent;
                    a.mantissa <= float_in.mantissa;
                end
                else begin
                    a <= '0;
                end
                b <= '0;
                c <= '0;
                y <= '0;
                float_out <= '0;
            end
            LOAD: begin
                ready_out <= FALSE;
                error_out <= FALSE;
                a <= a;
                b.sign <= float_in.sign;
                b.exponent <= float_in.exponent;
                b.mantissa <= float_in.mantissa;
                c <= '0;
                y <= '0;
                float_out <= '0;
            end
            MULTIPLY: begin
                ready_out <= FALSE;
                error_out <= FALSE;
                a <= a;
                b <= b;
                c.sign <= float_in.sign;
                c.exponent <= float_in.exponent;
                c.mantissa <= float_in.mantissa;
                if ((!a.exponent && !a.mantissa) || (!b.exponent && !b.mantissa)) begin
                    y <= '0;
                end
                else begin
                    y.sign <= a.sign ^ b.sign;
                    y.exponent <= ($signed(a.exponent)-EXP_OFFSET) + ($signed(b.exponent)-EXP_OFFSET) + EXP_OFFSET;
                    y.mantissa <= (a.mantissa | (1<<MANBITS)) * (b.mantissa | (1<<MANBITS));
                end
                float_out <= '0;
            end
            ALIGN: begin
                ready_out <= FALSE;
                error_out <= FALSE;
                a <= a;
                b <= b;
                // If the product is denormalized
                if (y.mantissa[2*MANBITS+1]) begin
                    if (c.exponent < (y.exponent+1)) begin
                        c.sign <= c.sign;
                        c.exponent <= $signed(c.exponent) + ((y.exponent+1)-c.exponent);
                        c.mantissa <= (c.mantissa | (1<<MANBITS)) >> ((y.exponent+1)-c.exponent);
                        y.sign <= y.sign;
                        y.exponent <= $signed(y.exponent) + 1;
                        y.mantissa <= y.mantissa >> 1;
                    end
                    else begin
                        c <= c;
                        y.sign <= y.sign;
                        y.exponent <= $signed(y.exponent) + 2;
                        y.mantissa <= y.mantissa >> 2;
                    end
                end
                // Else the product is normalized
                else begin
                    if (c.exponent < y.exponent) begin
                        c.sign <= c.sign;
                        c.exponent <= $signed(c.exponent) + (y.exponent-c.exponent);
                        c.mantissa <= (c.mantissa | (1<<MANBITS)) >> (y.exponent-c.exponent);
                        y <= y;
                    end
                    else begin
                        c <= c;
                        y.sign <= y.sign;
                        y.exponent <= $signed(y.exponent) + (c.exponent-y.exponent);
                        y.mantissa <= y.mantissa >> (c.exponent-y.exponent);
                    end
                end
                float_out <= '0;
            end
            ACCUMULATE: begin
                ready_out <= FALSE;
                error_out <= FALSE;
                a <= a;
                b <= b;
                c <= c;
                y.sign <= y.sign;
                y.exponent <= y.exponent;
                if (c.sign == y.sign) begin
                    y.mantissa <= y.mantissa + (c.mantissa<<MANBITS);
                end
                else begin
                    if (y.mantissa >= (c.mantissa<<MANBITS)) begin
                        y.mantissa <= y.mantissa - (c.mantissa<<MANBITS);
                    end
                    else begin
                        y.mantissa <= (c.mantissa<<MANBITS) - y.mantissa;
                    end
                end
                float_out <= '0;
            end
            NORMALIZE: begin
                ready_out <= FALSE;
                error_out <= FALSE;
                a <= a;
                b <= b;
                c <= c;
                if (y.mantissa[2*MANBITS+1]) begin                   
                    y.sign <= y.sign;
                    y.exponent <= $signed(y.exponent) + 1;
                    y.mantissa <= y.mantissa >> 1;
                end
                else begin
                    y <= y;
                end
                float_out <= '0;
            end
            OUTPUT: begin
                ready_out <= TRUE;
                error_out <= FALSE;
                a <= a;
                b <= b;
                c <= c;
                y <= y;
                if (($signed(float_out.exponent) > MAX_EXP) || ($signed(float_out.exponent) < MIN_EXP)) begin
                    float_out <= '1;
                end
                else begin
                    float_out.sign <= y.sign;
                    float_out.exponent <= y.exponent;
                    float_out.mantissa <= y.mantissa[2*MANBITS-1:MANBITS];
                end
            end
            ERROR: begin
                ready_out <= FALSE;
                error_out <= TRUE;
                a <= '0;
                b <= '0;
                c <= '0;
                y <= '0;
                float_out <= '1;
            end
        endcase
    end

endmodule : fma
