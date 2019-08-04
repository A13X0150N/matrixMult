// top_exp.sv

localparam CLOCK_PERIOD = 10;
localparam CYCLES = 12;
localparam FPBITS = 31;
localparam x = 23;
localparam y = 23;
localparam num1 = 1.75;
localparam num2 = 1.5;
localparam num3 = 1.0;

// Data types
typedef enum bit [2:0] {
    IDLE,
    LOAD,
    MULTIPLY,
    ALIGN,
    ACCUMULATE,
    NORMALIZE,
    OUTPUT,
    ERROR
} state_t;

typedef struct packed {
    bit sign;
    bit [7:0]  exponent;
    bit [22:0] mantissa;
} float_t;

typedef struct packed {
    bit sign;
    bit [7:0]  exponent;
    bit [49:0] mantissa;
} internal_float_t;


// Testbench
module top_exp;
    initial $display("\n\n\t *** Starting Tests *** \n");
    initial #(CLOCK_PERIOD * CYCLES) $finish;

    // Clock Generator
    bit clk;
    initial begin : clock_generator
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end : clock_generator

    // Synchronous Reset Generator
    bit rst;
    task reset();
        rst = 0;
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);
    endtask : reset

    // Test variables
    float_t float_in, float_in1, float_in2, float_in3, calc_float, float_out;
    bit error, start, ready;

    // Unit Under Test
    fma uut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .float_in(float_in),
        .float_out(float_out),
        .error(error),
        .ready(ready)
    );

    // Main Test Sequence
    initial begin
        reset();
        start = 0;
        $display("\n * * * FMA test begin * * * \n");
        start = 1;
        float_in1 = $shortrealtobits(num1);
        float_in = float_in1;
        @(posedge clk);
        start = 0;

        float_in2 = $shortrealtobits(num2);
        float_in = float_in2;
        @(posedge clk);

        float_in3 = $shortrealtobits(num3);
        float_in = float_in3;
        @(posedge clk);

        calc_float = $shortrealtobits(num1 * num2 + num3);
        $display("float_in1: %f  %x\t\t\t\tfloat_in2: %f  %x\t\t\t\tfloat_in3: %f  %x", $bitstoshortreal(float_in1), float_in1, $bitstoshortreal(float_in2), float_in2, $bitstoshortreal(float_in3), float_in3);
        $display("float_in1.exp: %d   float_in1.man: %d\t\tfloat_in2.exp: %d   float_in2.man: %d\t\tfloat_in3.exp: %d   float_in3.man: %d", float_in1.exponent, float_in1.mantissa, $signed(float_in2.exponent), float_in2.mantissa, $signed(float_in3.exponent), float_in3.mantissa);
        $display("\n ---- PREDICTED VALUES ----\ncalc_float: %f\n\tcalc_float.exp: %d\n\tcalc_float.man: %d \n\n", $bitstoshortreal(calc_float), calc_float.exponent, calc_float.mantissa);
    
        do begin
            @(posedge clk);
        end while (!ready);
        $display("\n ---- OUTPUT VALUES ----\nfloat_out: %f\n\tfloat_out.exp: %d\n\tfloat_out.man: %d\n\n", $bitstoshortreal(float_out), float_out.exponent, float_out.mantissa);

    end
    final $display("\n\n\t *** End of Tests *** \n");
endmodule: top_exp


// IEEE-754 floating point Fused Multiply Accumulate
module fma
(
    input           clk, rst, start,
    input  float_t  float_in,
    output float_t  float_out,
    output bit      error,
    output bit      ready
);

    bit error_in;
    internal_float_t a, b, c, y;         // a * b + c = y
    state_t state=IDLE, next_state;

    // Check for input errors (denormalized numbers, +infinity, -infinity, NaN)
    assign error_in = ((float_in && !float_in.exponent) || float_in.exponent == 8'hFF) ? 1 : 0;

    // State machine driver
    always_ff @(posedge clk) begin
        state <= rst ? IDLE : next_state;
        $strobe(($time/CLOCK_PERIOD), " clock cycles \t%s", state);
    end

    // Next state logic
    always_comb begin
        unique case (state)
            IDLE: begin
                if (error_in) begin
                    next_state <= ERROR;
                end
                else if (start) begin
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
                if (($signed(float_out.exponent) > 127) || ($signed(float_out.exponent) < -128)) begin
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
                ready <= 0;
                if (start) begin
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
                ready <= 0;
                a <= a;
                b.sign <= float_in.sign;
                b.exponent <= float_in.exponent;
                b.mantissa <= float_in.mantissa;
                c <= '0;
                y <= '0;
                float_out <= '0;
            end
            MULTIPLY: begin
                ready <= 0;
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
                    y.exponent <= ($signed(a.exponent)-127) + ($signed(b.exponent)-127) + 127;
                    y.mantissa <= (a.mantissa | (1<<23)) * (b.mantissa | (1<<23));
                end
                float_out <= '0;
            end
            ALIGN: begin
                ready <= 0;
                a <= a;
                b <= b;
                // If the product is denormalized
                if (y.mantissa[47]) begin
                    if (c.exponent < (y.exponent+1)) begin
                        c.sign <= c.sign;
                        c.exponent <= $signed(c.exponent) + ((y.exponent+1)-c.exponent);
                        c.mantissa <= (c.mantissa | (1<<23)) >> ((y.exponent+1)-c.exponent);
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
                        c.mantissa <= (c.mantissa | (1<<23)) >> (y.exponent-c.exponent);
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
                ready <= 0;
                a <= a;
                b <= b;
                c <= c;
                y.sign <= y.sign;
                y.exponent <= y.exponent;
                if (c.sign == y.sign) begin
                    y.mantissa <= y.mantissa + (c.mantissa<<23);
                end
                else begin
                    if (y.mantissa >= (c.mantissa<<23)) begin
                        y.mantissa <= y.mantissa - (c.mantissa<<23);
                    end
                    else begin
                        y.mantissa <= (c.mantissa<<23) - y.mantissa;
                    end
                end
                float_out <= '0;
            end
            NORMALIZE: begin
                ready <= 0;
                a <= a;
                b <= b;
                c <= c;
                if (y.mantissa[47]) begin                   
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
                ready <= 1;
                a <= a;
                b <= b;
                c <= c;
                y <= y;
                if (($signed(float_out.exponent) > 127) || ($signed(float_out.exponent) < -128)) begin
                    float_out <= '1;
                end
                else begin
                    float_out.sign <= y.sign;
                    float_out.exponent <= y.exponent;
                    float_out.mantissa <= y.mantissa[45:23];
                end
            end
            ERROR: begin
                ready <= 0;
                a <= '0;
                b <= '0;
                c <= '0;
                y <= '0;
                float_out <= '1;
            end
        endcase
    end

endmodule : fma




















