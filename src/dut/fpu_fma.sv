// fpu_fma.sv
// IEEE-754 floating point Fused Multiply Accumulate
//
//                       Matrix B flows down  and up
//                               |                 ^
//                               |                 |
//   Matrix A flows right --->   v                 |
//               and left <---
// 
//                3x3 Grid                      Single FMA unit
//         FMA ---- FMA ---- FMA                      Up
//          | \      | \      | \                     |
//          |  ans   |  ans   |  ans                  v
//         FMA ---- FMA ---- FMA           Left ---> FMA ---> Right
//          | \      | \      | \                     | \
//          |  ans   |  ans   |  ans                  v  ans
//         FMA ---- FMA ---- FMA                     Down
//            \        \        \
//             ans      ans      ans
//     

import global_defs::*;
import mpu_data_types::*;

module fma
(
    // Control Signals
    input           clk,                // Clock
    input           rst,                // Synchronous reset active high

    // Busy Signals
    input  bit      float_0_busy_in,    // float 0 neighbor busy state
    input  bit      float_1_busy_in,    // float 1 neighbor busy state
    output bit      busy_out,           // Output busy state to neighbors

    // Data request signals
    input  bit      float_0_req_in,     // float 0 input request
    output bit      float_0_req_out,    // float 0 output request
    input  bit      float_1_req_in,     // float 1 input request
    output bit      float_1_req_out,    // float 1 output request

    // Float I/O
    input  float_sp float_0_in,         // float 0 input
    output float_sp float_0_out,        // float 0 output
    input  float_sp float_1_in,         // float 1 input
    output float_sp float_1_out,        // float 1 output

    // Answer output
    output float_sp float_answer_out,   // Answer float output
    output bit      ready_answer_out,   // Signal answer output ready
    output bit      error_out           // Signal error detection output
);

    bit [NBITS:0] count;
    bit error_in;
    bit error_generated;
    bit busy;
    float_sp float_0;          
    float_sp float_1;                   //  1)   product = float_0 * float_1
    internal_float_sp accum;            //  2)   accum = accum + product
    internal_float_sp product;
    fma_state_e state, next_state;

    // Broadcast busy state to neighbors
    assign busy_out = busy;

    // Check for input errors (denormalized numbers, +infinity, -infinity, NaN)
    assign error_in = ((float_0_in.mantissa && !float_0_in.exponent) || float_0_in.exponent == '1) ||
                      ((float_1_in.mantissa && !float_1_in.exponent) || float_1_in.exponent == '1);

    assign error_generated = ((float_0_in != POS_ONE_32BIT) && (float_0_in != NEG_ONE_32BIT)) &&
                             ((float_1_in != POS_ONE_32BIT) && (float_1_in != NEG_ONE_32BIT)) &&
                             (($signed(product.exponent) > MAX_EXP) || ($signed(product.exponent) < MIN_EXP));

    // State machine driver
    always_ff @(posedge clk) begin
        state <= rst ? IDLE : next_state;
    end

    // Next state logic
    always_comb begin
        unique case (state)
            IDLE: begin
                // Check for input error
                if (error_in) begin
                    next_state <= ERROR;
                end
                else if (float_0_req_in & float_1_req_in) begin
                    next_state <= MULTIPLY;
                end
                else if (float_0_req_in | float_1_req_in) begin
                    next_state <= LOAD;
                end
                else begin
                    next_state <= IDLE;
                end
            end
            LOAD: begin
                // Check for input error
                if (error_in) begin
                    next_state <= ERROR;
                end
                else if (float_0_req_in | float_1_req_in) begin
                    next_state <= MULTIPLY;
                end
                else begin
                    next_state <= LOAD;
                end
            end
            MULTIPLY: begin
                next_state <= ALIGN;
            end
            ALIGN: begin
                next_state <= ACCUMULATE;
            end
            ACCUMULATE: begin
                next_state <= NORMALIZE;
            end
            NORMALIZE: begin
                next_state <= OUTPUT;
            end
            OUTPUT: begin
                // Check for overflow/underflow in the result
                if (error_generated) begin
                    next_state <= ERROR;
                end
                else begin
                    // Hold output until neighbors can receive next input signals
                    if (float_0_busy_in | float_1_busy_in) begin
                        next_state <= OUTPUT;
                    end
                    else begin
                        next_state <= IDLE;
                    end
               end
            end
            ERROR: begin 
                next_state <= IDLE;
            end
        endcase
    end

    // Clocked logic and I/O
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= '0;
            busy <= FALSE;
            error_out <= FALSE;
            float_0_req_out <= FALSE;
            float_1_req_out <= FALSE;
            float_0_out <= '0;
            float_1_out <= '0;
            float_0 <= '0;
            float_1 <= '0;
            accum <= '0;
            product <= '0;
            float_answer_out <= '0;
            ready_answer_out <= FALSE;
        end
        else begin
            unique case (state)
                IDLE: begin
                    count <= count;
                    error_out <= FALSE;
                    float_0_req_out <= FALSE;
                    float_1_req_out <= FALSE;
                    float_0_out <= '0;
                    float_1_out <= '0;
                    // If a start signal is recieved, capture the associated input
                    if (float_0_req_in & float_1_req_in) begin
                        busy <= TRUE;
                        float_0.sign <= float_0_in.sign;
                        float_0.exponent <= float_0_in.exponent;
                        float_0.mantissa <= float_0_in.mantissa;
                        float_1.sign <= float_1_in.sign;
                        float_1.exponent <= float_1_in.exponent;
                        float_1.mantissa <= float_1_in.mantissa;
                    end
                    else if (float_0_req_in) begin
                        busy <= FALSE;                      
                        float_0.sign <= float_0_in.sign;
                        float_0.exponent <= float_0_in.exponent;
                        float_0.mantissa <= float_0_in.mantissa;
                        float_1 <= '0;
                    end
                    else if (float_1_req_in) begin
                        busy <= FALSE;
                        float_0 <= '0;
                        float_1.sign <= float_1_in.sign;
                        float_1.exponent <= float_1_in.exponent;
                        float_1.mantissa <= float_1_in.mantissa;
                    end
                    else begin
                        busy <= FALSE;
                        float_0 <= float_0;
                        float_1 <= float_1;
                    end
                    accum <= accum;
                    product <= '0;
                    float_answer_out <= '0;
                    ready_answer_out <= FALSE;
                end
                LOAD: begin
                    count <= count;
                    error_out <= FALSE;
                    float_0_req_out <= FALSE;
                    float_1_req_out <= FALSE;
                    float_0_out <= '0;
                    float_1_out <= '0;
                    // float_1 gets priority now
                    if (float_1_req_in) begin
                        busy <= TRUE;
                        float_0 <= float_0;
                        float_1.sign <= float_1_in.sign;
                        float_1.exponent <= float_1_in.exponent;
                        float_1.mantissa <= float_1_in.mantissa;
                    end                    
                    else if (float_0_req_in) begin
                        busy <= TRUE;
                        float_0.sign <= float_0_in.sign;
                        float_0.exponent <= float_0_in.exponent;
                        float_0.mantissa <= float_0_in.mantissa;
                        float_1 <= float_1;
                    end
                    else begin
                        busy <= FALSE;
                        float_0 <= float_0;
                        float_1 <= float_1;
                    end
                    accum <= accum;
                    product <= '0;
                    float_answer_out <= '0;
                    ready_answer_out <= FALSE;
                end
                MULTIPLY: begin
                    count <= count;
                    busy <= TRUE;
                    error_out <= FALSE;
                    float_0_req_out <= FALSE;
                    float_1_req_out <= FALSE;
                    float_0_out <= '0;
                    float_1_out <= '0;
                    float_0 <= float_0;
                    float_1 <= float_1;
                    accum <= accum;
                    // Detect multiplication by zero shortcut
                    if ((!float_0.exponent && !float_0.mantissa) || (!float_1.exponent && !float_1.mantissa)) begin
                        product <= '0;
                    end
                    // Detect float_0 multiplication by 1 shortcut
                    else if ((float_0 == POS_ONE_32BIT) || (float_0 == NEG_ONE_32BIT)) begin
                        product.sign <= float_1.sign;
                        product.exponent <= float_1.exponent;
                        product.mantissa <= (float_1.mantissa | (1<<MANBITS)) << MANBITS; 
                    end
                    // Detect float_1 multiplication by 1 shortcut
                    else if ((float_1 == POS_ONE_32BIT) || (float_1 == NEG_ONE_32BIT)) begin
                        product.sign <= float_0.sign;
                        product.exponent <= float_0.exponent;
                        product.mantissa <= (float_0.mantissa | (1<<MANBITS)) << MANBITS; 
                    end
                    // Standard multiplication
                    else begin
                        product.sign <= float_0.sign ^ float_1.sign;
                        product.exponent <= ($signed(float_0.exponent)-EXP_OFFSET) + ($signed(float_1.exponent)-EXP_OFFSET) + EXP_OFFSET;
                        product.mantissa <= (float_0.mantissa | (1<<MANBITS)) * (float_1.mantissa | (1<<MANBITS));
                    end
                    float_answer_out <= '0;
                    ready_answer_out <= FALSE;
                end
                ALIGN: begin
                    count <= count;
                    busy <= TRUE;
                    error_out <= FALSE;
                    float_0_req_out <= FALSE;
                    float_1_req_out <= FALSE;
                    float_0_out <= '0;
                    float_1_out <= '0;
                    float_0 <= float_0;
                    float_1 <= float_1;
                    // If the product is denormalized
                    if (product.mantissa[2*MANBITS+1]) begin
                        if (accum.exponent < (product.exponent+1)) begin
                            accum.sign <= accum.sign;
                            accum.exponent <= $signed(accum.exponent) + ((product.exponent+1)-accum.exponent);
                            accum.mantissa <= (accum.mantissa | (1<<MANBITS)) >> ((product.exponent+1)-accum.exponent);
                            product.sign <= product.sign;
                            product.exponent <= $signed(product.exponent) + 1;
                            product.mantissa <= product.mantissa >> 1;
                        end
                        else begin
                            accum <= accum;
                            product.sign <= product.sign;
                            product.exponent <= $signed(product.exponent) + 1;
                            product.mantissa <= product.mantissa >> 1;
                        end
                    end
                    // Else the product is normalized
                    else begin
                        if (accum.exponent < product.exponent) begin
                            accum.sign <= accum.sign;
                            accum.exponent <= $signed(accum.exponent) + (product.exponent-accum.exponent);
                            accum.mantissa <= (accum.mantissa | (1<<MANBITS)) >> (product.exponent-accum.exponent);
                            product <= product;
                        end
                        else begin
                            accum <= accum;
                            product.sign <= product.sign;
                            product.exponent <= $signed(product.exponent) + (accum.exponent-product.exponent);
                            product.mantissa <= product.mantissa >> (accum.exponent-product.exponent);
                        end
                    end
                    float_answer_out <= '0;
                    ready_answer_out <= FALSE;
                end
                ACCUMULATE: begin
                    count <= count + 1;
                    busy <= TRUE;
                    error_out <= FALSE;
                    float_0_req_out <= FALSE;
                    float_1_req_out <= FALSE;
                    float_0_out <= '0;
                    float_1_out <= '0;
                    float_0 <= float_0;
                    float_1 <= float_1;
                    accum.sign <= accum.sign;
                    accum.exponent <= accum.exponent;
                    // Check if adding both positive or both negative numbers
                    if (accum.sign == product.sign) begin
                        accum.mantissa <= product.mantissa + accum.mantissa;
                    end
                    // Else there is a subtraction to perform
                    else begin
                        if (product.mantissa >= accum.mantissa) begin
                            accum.mantissa <= product.mantissa - accum.mantissa;
                        end
                        else begin
                            accum.mantissa <= accum.mantissa - product.mantissa;
                        end
                    end
                    product <= product;
                    float_answer_out <= '0;
                    ready_answer_out <= FALSE;
                end
                NORMALIZE: begin
                    count <= count;
                    busy <= TRUE;
                    error_out <= FALSE;
                    float_0_req_out <= FALSE;
                    float_1_req_out <= FALSE;
                    float_0_out <= '0;
                    float_1_out <= '0;
                    float_0 <= float_0;
                    float_1 <= float_1;
                    // Normalize if multiplying the mantissas produced a 2 (denormalized)
                    if (accum.mantissa[2*MANBITS+1]) begin
                        accum.sign <= accum.sign;
                        accum.exponent <= $signed(accum.exponent) + 1;
                        accum.mantissa <= accum.mantissa >> 1;
                    end
                    else begin
                        accum <= accum;
                    end
                    product <= product;
                    float_answer_out <= '0;
                    ready_answer_out <= FALSE;
                end
                OUTPUT: begin
                    busy <= TRUE;
                    float_0_req_out <= TRUE;
                    float_1_req_out <= TRUE;
                    float_0_out.sign <= float_0.sign;
                    float_0_out.exponent <= float_0.exponent;
                    float_0_out.mantissa <= float_0.mantissa;
                    float_1_out.sign <= float_1.sign;
                    float_1_out.exponent <= float_1.exponent;
                    float_1_out.mantissa <= float_1.mantissa;
                    float_0 <= float_0;
                    float_1 <= float_1;
                    accum <= accum;
                    product <= product;
                    // Check for overflow/underflow conditions from operation
                    if (error_generated) begin
                        count <= '0;
                        error_out <= TRUE;
                        float_answer_out <= '1;
                        ready_answer_out <= FALSE;
                    end
                    if (count == N) begin
                        count <= '0;
                        error_out <= FALSE;
                        float_answer_out.sign <= accum.sign;
                        float_answer_out.exponent <= accum.exponent;
                        float_answer_out.mantissa <= accum.mantissa[2*MANBITS-1:MANBITS];
                        accum <= '0;
                        ready_answer_out <= TRUE;
                    end 
                    else begin
                        count <= count;
                        error_out <= FALSE;
                        float_answer_out <= '0;
                        ready_answer_out <= FALSE;
                    end
                end
                ERROR: begin
                    count <= '0;
                    busy <= FALSE;
                    error_out <= TRUE;
                    float_0_req_out <= FALSE;
                    float_1_req_out <= FALSE;
                    float_0_out <= '0;
                    float_1_out <= '0;
                    float_0 <= '0;
                    float_1 <= '0;
                    accum <= '0;
                    product <= '0;
                    float_answer_out <= '1;
                    ready_answer_out <= FALSE;
                end
            endcase
        end
    end

endmodule : fma

