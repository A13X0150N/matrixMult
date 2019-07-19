// top_exp.sv

localparam CLOCK_PERIOD = 10;
localparam CYCLES = 35;
localparam FPBITS = 31;
localparam x = 23;
localparam y = 23;
//localparam num1 = 1.0000002;  // man = 2   32'h3f800002
//localparam num2 = 1.0000007;  // man = 6   32'h3f800006
localparam num1 = 10.5;
localparam num2 = 2.5;

// Data types
typedef enum bit [2:0] {
    IDLE,
    LOAD1,
    LOAD2,
    MULTIPLY,
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
    bit [8:0]  exponent;
    bit [23:0] mantissa;
} internal_float_t;


// Testbench
module top_exp;
    initial $display("\n\n\t *** Starting Tests *** \n");

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
        repeat (3) @(posedge clk);
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
        $display("\n\t *** FMA test *** \n");
        $monitor($time/CLOCK_PERIOD, " clock cycles\n\t float_in: %f   ready: %b   error: %b \n\t float_out: %f   float_out.exp: %d   float_out.man: %d \n\n",
                    $bitstoshortreal(float_in), ready, error,  $bitstoshortreal(float_out), float_out.exponent, float_out.mantissa);
        start = 1;
        float_in1 = $shortrealtobits(num1);
        float_in = float_in1;
        @(posedge clk);
        start = 0;

        float_in2 = $shortrealtobits(num2);
        float_in = float_in2;
        @(posedge clk);

        calc_float = $shortrealtobits(num1*num2);
        $display("float_in1: %f  %x    float_in2: %f  %x", $bitstoshortreal(float_in1), float_in1, $bitstoshortreal(float_in2), float_in2);
        $display("float_in1.exp: %d   float_in1.man: %d   float_in2.exp: %d   float_in2.man: %d", float_in1.exponent, float_in1.mantissa, float_in2.exponent, float_in2.mantissa);
        $display("\n*** PREDICTED VALUES ***\n\t calc_float: %f   calc_float.exp: %d   calc_float.man: %d \n\n", 
                    $bitstoshortreal(calc_float), calc_float.exponent, calc_float.mantissa);
        
        float_in3 = $shortrealtobits(2.2);
        float_in = float_in3;
        @(posedge clk);

    end
    initial #(CLOCK_PERIOD * CYCLES) $finish;
    final $display("\n\n\t *** End of Tests *** \n");
endmodule: top_exp




// IEEE-754 floating point Fused Multiply Accumulate
module fma
(
    input           clk, rst, start,
    input  float_t  float_in,
    output float_t  float_out,
    output logic    error,
    output logic    ready
);

    float_t a, b, c;
    //internal_float_t a, b, c;         // a * b + c = y
    state_t state=IDLE, next_state;
    logic [$clog2(x)-1:0] mult_counter;

    logic [x+y:0] booth_var;
    logic [x-1:0] sum;
    logic [x+y-1:0] product;

    // Check for input errors (denormalized numbers, +infinity, -infinity, NaN)
    assign error = (!float_in.exponent || float_in.exponent == 8'hFF) ? 1 : 0;

    // State machine driver
    always_ff @(posedge clk) begin
        state <= rst ? IDLE : next_state;
        //$strobe("%s", state);
        //$strobe("float.exp: %d", float_out.exponent);
        //$strobe($time/CLOCK_PERIOD, " clock cycles   booth_var: %b", booth_var);
        //$strobe($time/CLOCK_PERIOD, " clock cycles     product:  %b \n", product);
    end

    // Next state logic
    always_comb begin
        unique case (state)
            IDLE:       next_state = (!error && start) ? LOAD1 : start ? ERROR : IDLE;
            LOAD1:      next_state = error ? ERROR : LOAD2;
            LOAD2:      next_state = error ? ERROR : MULTIPLY;
            MULTIPLY:   next_state = error ? ERROR : (mult_counter == (y - 1)) ? NORMALIZE : MULTIPLY;
            NORMALIZE:  next_state = OUTPUT;
            OUTPUT:     next_state = IDLE;
            ERROR:      next_state = IDLE;
        endcase
    end

    // Clocked logic and I/O
    always_ff @(posedge clk) begin
        unique case (state)
    
            IDLE: begin
                mult_counter <= '0;
                product <= '0;
                ready <= 0;
                if (start) begin
                    booth_var <= {{x{1'b0}}, float_in.mantissa, 1'b0};
                    a.sign <= float_in.sign;
                    a.exponent <= float_in.exponent;
                    a.mantissa <= float_in.mantissa;
                end
                else begin
                    booth_var <= '0;
                    a <= '0;
                end
                b <= '0;
                c <= '0;
                float_out <= '0;
            end
            
            LOAD1: begin
                mult_counter <= '0;
                booth_var <= booth_var;
                product <= '0;
                ready <= 0;
                a <= a;
                b.sign <= float_in.sign;
                b.exponent <= float_in.exponent;
                b.mantissa <= float_in.mantissa;
                c <= '0;
                float_out <= float_out;
            end

            LOAD2: begin
                mult_counter <= '0;
                booth_var <= booth_var;
                product <= '0;
                ready <= 0;
                a <= a;
                b <= b;
                c.sign <= float_in.sign;
                c.exponent <= float_in.exponent;
                c.mantissa <= float_in.mantissa;
                float_out <= float_out;
            end

            MULTIPLY: begin
                mult_counter <= mult_counter + 1'b1;
                booth_var[x+y:x+1] <= {sum[x-1], sum[x-1:1]};
                booth_var[x:0] <= {sum[0], booth_var[x:1]};
                product <= product;
                ready <= 0;
                a <= a;
                b <= b;
                c <= c;
                float_out.sign <= a.sign ^ b.sign;
                float_out.exponent <= $signed(a.exponent) + $signed(b.exponent) - 127;
                float_out.mantissa <= product;
                //$strobe("float_out.exponent: %d", float_out.exponent);
            end

            NORMALIZE: begin
                mult_counter <= mult_counter;
                booth_var <= booth_var;
                ready <= 0;
                a <= a;
                b <= b;
                c <= c;
                if (!booth_var[x+y]) begin
                    $display("NORMALIZE!!!");
                    product <= booth_var[x+y:1] << 1;
                    float_out.sign <= float_out.sign;
                    float_out.exponent <= $signed(float_out.exponent) - 1;
                    float_out.mantissa <= float_out.mantissa;
                end
                else begin
                    product <= booth_var[x+y:1];
                    float_out.sign <= float_out.sign;
                    float_out.exponent <= float_out.exponent;
                    float_out.mantissa <= float_out.mantissa;
                end
            end

            OUTPUT: begin
                mult_counter <= mult_counter;
                booth_var <= booth_var;
                product <= product;
                ready <= 1;
                a <= a;
                b <= b;
                c <= c;
                if ($signed(float_out.exponent) > 127) begin
                    $display("!!! ERROR !!!: output exponent overflow");
                    float_out <= '1;
                end
                else begin
                    $display("*** OUTPUT VALUES ***");
                    float_out.sign <= float_out.sign;
                    float_out.exponent <= float_out.exponent;
                    float_out.mantissa <= product[x+y:23];   // ??????
                end

                //$strobe("*** OUTPUT VALUES *** \n\t float_out: %f   float_out.exp: %d   float_out.man: %d \n\n", $bitstoshortreal(float_out), float_out.exponent, float_out.mantissa);
            end

            ERROR: begin
                mult_counter <= '0;
                booth_var <= '0;
                product <= '0;
                ready <= 0;
                a <= '0;
                b <= '0;
                c <= '0;
                float_out <= '1;
            end

        endcase
    end

    // Booth Encoding Logic 
    always_comb begin
        case (booth_var[1:0])
            2'b00:  sum = booth_var[x+y:x+1];                       // No change
            2'b01:  sum = booth_var[x+y:x+1] + b.mantissa;          // Add 
            2'b10:  sum = booth_var[x+y:x+1] + (~b.mantissa + 1);   // Subtract (2's complement)
            2'b11:  sum = booth_var[x+y:x+1];                       // No change
        endcase
    end

endmodule : fma




















