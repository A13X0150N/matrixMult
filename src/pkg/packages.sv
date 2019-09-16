// packages.sv
// ----------------------------------------------------------------------------
//   Author: Alex Olson
//     Date: June 2019
//
// Desciption:
// ----------------------------------------------------------------------------
// Contains packages with definitions for design and testbench.
//
// ----------------------------------------------------------------------------

 
// Definitions for global space
package global_defs;

    //////////////////////////// * * *  ADJUSTABLE TOP-LEVEL PARAMETERS  * * * ////////////////////////////

    parameter FP = 32;                      // Floating point bit selection
    parameter M = 3;                        // Maximum register row size
    parameter N = 3;                        // Maximum register column size
    parameter MATRIX_REGISTERS = 8;         // Size of matrix register file

    ///////////////////////////////////////////////////////////////////////////////////////////////////////

    // Single-precision floating point
    //if (FP == 32) begin
        parameter MIN_EXP = -126;
        parameter MAX_EXP = 127;
        parameter EXP_OFFSET = 127;
        parameter EXPBITS = 8;
        parameter MANBITS = 23;
    //end
    // Double-precision floating point
    /*else if (FP == 64) begin
        parameter MIN_EXP = -1022;
        parameter MAX_EXP = 1023;
        parameter EXP_OFFSET = 1023;
        parameter EXPBITS = 11;
        parameter MANBITS = 52;
    end
    // Invalid selection
    else begin
        parameter MIN_EXP = 0;
        parameter MAX_EXP = 0;
        parameter EXP_OFFSET = 0;
        parameter EXPBITS = 0;
        parameter MANBITS = 0;
    end*/

    // Maximum working matrix dimensions
    parameter FPBITS = FP-1;                // Floating point bit number
    parameter MBITS = $clog2(M)-1;          // Register row bits
    parameter NBITS = $clog2(N)-1;          // Register column bits
    parameter MATRIX_REG_BITS = $clog2(MATRIX_REGISTERS)-1;  // Register address bits

    parameter POS_ONE_32BIT = 32'h3f800000;
    parameter NEG_ONE_32BIT = 32'hbf800000;

endpackage : global_defs


// MPU BFM interface definitions
package mpu_data_types;
    import global_defs::FPBITS;
    import global_defs::MBITS;
    import global_defs::NBITS;
    import global_defs::MATRIX_REG_BITS;
    import global_defs::EXPBITS;
    import global_defs::MANBITS;

    // Boolean data type
    typedef enum bit {
        FALSE, 
        TRUE
    } bool_e;

    // Test status data type
    typedef enum bit {
        FAIL,
        PASS
    } test_e;

    // MPU instructions
    typedef enum bit [1:0] {
        MPU_NOP,
        MPU_LOAD,
        MPU_STORE,
        MPU_MULT
    } mpu_instruction_e;

    // FPU instructions
    typedef enum bit [1:0] {
        FPU_NOP,
        FPU_FMA,
        FPU_MULTIPLY,
        FPU_ADD
    } fpu_instruction_e;

    // Load states
    typedef enum bit [1:0] {
        LOAD_IDLE,
        LOAD_REQUEST,
        LOAD_MATRIX
    } load_state_e;

    // Store states
    typedef enum bit [1:0] {
        STORE_IDLE,
        STORE_REQUEST,
        STORE_MATRIX
    } store_state_e;

    // Dispatcher states
    typedef enum bit [1:0] {
        DISP_IDLE,
        DISP_MATRIX,
        DISP_WAIT
    } disp_state_e;

    // Collector states
    typedef enum bit {
        COLLECTOR_IDLE,
        COLLECTOR_WRITE
    } collector_state_e;

    // FMA states
    typedef enum bit [2:0] {
        IDLE,
        LOAD,
        MULTIPLY,
        ALIGN,
        ACCUMULATE,
        NORMALIZE,
        OUTPUT,
        ERROR
    } fma_state_e;

    // Floating point data type
    typedef struct packed {
        bit sign;
        bit [EXPBITS-1:0] exponent;
        bit [MANBITS-1:0] mantissa;
    } float_sp;

    // Internal floating point data type
    typedef struct packed {
        bit sign;
        bit [EXPBITS-1:0]   exponent;
        bit [2*MANBITS+3:0] mantissa;
    } internal_float_sp;

    // MPU bus sequence item struct
    typedef struct packed {
        // Request fields
        mpu_instruction_e op;
        float_sp [0:8] matrix_in;
        bit [MBITS:0] m_in;
        bit [NBITS:0] n_in;
        bit [MATRIX_REG_BITS:0] src_addr_0;
        bit [MATRIX_REG_BITS:0] src_addr_1;
        bit [MATRIX_REG_BITS:0] dest_addr;
      
        // Response fields
        float_sp [0:8] matrix_out;
    } mpu_data_sp;

endpackage : mpu_data_types


// Testbench functions and tasks
package testbench_utilities;

    import global_defs::FPBITS;
    import global_defs::MATRIX_REGISTERS;
    import global_defs::M;
    import global_defs::N;
    import mpu_data_types::mpu_data_sp;
    import mpu_data_types::float_sp;

    parameter CLOCK_PERIOD = 10;                // Clock Perid
    parameter MAX_CYCLES = 500;                 // Maximum clock cycles
    parameter M_MEM = 3;                        // Testbench input matrix rows     MUST BE <=M
    parameter N_MEM = 3;                        // Testbench input matrix columns  MUST BE <=N
    parameter NUM_ELEMENTS = M_MEM * N_MEM;     // Number of input elements per matrix for testbench
    parameter BIG_FLOAT_32 = 32'h7f7fffff;      // Very large number to force overflow
    parameter SMALL_FLOAT_32 = 32'h00800000;    // Very small number to force underflow
    parameter MAX_ERROR = 10.0;                 // Maximux tolerated error accumulated across a matrix
    parameter NUM_TESTS = 500000;               // Scalable number of tests to perform

    // Matrix generator, incremental order
    task automatic generate_matrix(input shortreal seed, input shortreal scale, ref mpu_data_sp genmat);
        for (int i = 0; i < NUM_ELEMENTS; ++i) begin
            genmat.matrix_in = {(genmat.matrix_in), $shortrealtobits(seed + i * scale)};
        end
    endtask : generate_matrix

    // Matrix generator, decremental order
    task automatic generate_matrix_reverse(input shortreal seed, input shortreal scale, ref mpu_data_sp genmat);
        for (int i = NUM_ELEMENTS; i; --i) begin
            genmat.matrix_in = {(genmat.matrix_in), $shortrealtobits(seed + i * scale)};
        end
    endtask : generate_matrix_reverse

    // Matrix Output
    task show_matrix(input float_sp [0:NUM_ELEMENTS-1] matrix_in);
        float_sp matrix [NUM_ELEMENTS];
        {>>{matrix}} = matrix_in;
        if (NUM_ELEMENTS == 4) begin
            $display("\t2x2 MATRIX REGISTER\n\t %f\t%f \n\t %f\t%f \n", 
                        $bitstoshortreal(matrix[0]),
                        $bitstoshortreal(matrix[1]),
                        $bitstoshortreal(matrix[2]),
                        $bitstoshortreal(matrix[3]));
        end
        else if (NUM_ELEMENTS == 9) begin
            $display("\t3x3 MATRIX REGISTER\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                        $bitstoshortreal(matrix[0]),
                        $bitstoshortreal(matrix[1]),
                        $bitstoshortreal(matrix[2]),
                        $bitstoshortreal(matrix[3]),
                        $bitstoshortreal(matrix[4]),
                        $bitstoshortreal(matrix[5]),
                        $bitstoshortreal(matrix[6]),
                        $bitstoshortreal(matrix[7]),
                        $bitstoshortreal(matrix[8]));
        end
    endtask : show_matrix

    // Display a message with a border
    function void display_message(input string message);
        static int number_of_dashes, i;
        number_of_dashes = message.len() + 2;
        $write("\n");
        $write("\t ");
        for (i = 0; i < number_of_dashes; ++i) 
            $write("-");
        $write("\n\t| %s |\n", message);
        $write("\t ");
        for (i = 0; i < number_of_dashes; ++i) 
            $write("-");
        $write("\n");
    endfunction : display_message

    // Internal Register Dump   SIMULATION ONLY
    task simulation_register_dump(float_sp matrix_register_array [MATRIX_REGISTERS][M][N]);
        display_message("REGISTER DUMP");
        $display("\t3x3 MATRIX REGISTER[0]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[0][0][0]),
                    $bitstoshortreal(matrix_register_array[0][0][1]),
                    $bitstoshortreal(matrix_register_array[0][0][2]),
                    $bitstoshortreal(matrix_register_array[0][1][0]),
                    $bitstoshortreal(matrix_register_array[0][1][1]),
                    $bitstoshortreal(matrix_register_array[0][1][2]),
                    $bitstoshortreal(matrix_register_array[0][2][0]),
                    $bitstoshortreal(matrix_register_array[0][2][1]),
                    $bitstoshortreal(matrix_register_array[0][2][2]));
        $display("\t3x3 MATRIX REGISTER[1]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[1][0][0]),
                    $bitstoshortreal(matrix_register_array[1][0][1]),
                    $bitstoshortreal(matrix_register_array[1][0][2]),
                    $bitstoshortreal(matrix_register_array[1][1][0]),
                    $bitstoshortreal(matrix_register_array[1][1][1]),
                    $bitstoshortreal(matrix_register_array[1][1][2]),
                    $bitstoshortreal(matrix_register_array[1][2][0]),
                    $bitstoshortreal(matrix_register_array[1][2][1]),
                    $bitstoshortreal(matrix_register_array[1][2][2]));
        $display("\t3x3 MATRIX REGISTER[2]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[2][0][0]),
                    $bitstoshortreal(matrix_register_array[2][0][1]),
                    $bitstoshortreal(matrix_register_array[2][0][2]),
                    $bitstoshortreal(matrix_register_array[2][1][0]),
                    $bitstoshortreal(matrix_register_array[2][1][1]),
                    $bitstoshortreal(matrix_register_array[2][1][2]),
                    $bitstoshortreal(matrix_register_array[2][2][0]),
                    $bitstoshortreal(matrix_register_array[2][2][1]),
                    $bitstoshortreal(matrix_register_array[2][2][2]));
        $display("\t3x3 MATRIX REGISTER[3]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[3][0][0]),
                    $bitstoshortreal(matrix_register_array[3][0][1]),
                    $bitstoshortreal(matrix_register_array[3][0][2]),
                    $bitstoshortreal(matrix_register_array[3][1][0]),
                    $bitstoshortreal(matrix_register_array[3][1][1]),
                    $bitstoshortreal(matrix_register_array[3][1][2]),
                    $bitstoshortreal(matrix_register_array[3][2][0]),
                    $bitstoshortreal(matrix_register_array[3][2][1]),
                    $bitstoshortreal(matrix_register_array[3][2][2]));
        $display("\t3x3 MATRIX REGISTER[4]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[4][0][0]),
                    $bitstoshortreal(matrix_register_array[4][0][1]),
                    $bitstoshortreal(matrix_register_array[4][0][2]),
                    $bitstoshortreal(matrix_register_array[4][1][0]),
                    $bitstoshortreal(matrix_register_array[4][1][1]),
                    $bitstoshortreal(matrix_register_array[4][1][2]),
                    $bitstoshortreal(matrix_register_array[4][2][0]),
                    $bitstoshortreal(matrix_register_array[4][2][1]),
                    $bitstoshortreal(matrix_register_array[4][2][2]));
        $display("\t3x3 MATRIX REGISTER[5]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[5][0][0]),
                    $bitstoshortreal(matrix_register_array[5][0][1]),
                    $bitstoshortreal(matrix_register_array[5][0][2]),
                    $bitstoshortreal(matrix_register_array[5][1][0]),
                    $bitstoshortreal(matrix_register_array[5][1][1]),
                    $bitstoshortreal(matrix_register_array[5][1][2]),
                    $bitstoshortreal(matrix_register_array[5][2][0]),
                    $bitstoshortreal(matrix_register_array[5][2][1]),
                    $bitstoshortreal(matrix_register_array[5][2][2]));
        $display("\t3x3 MATRIX REGISTER[6]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[6][0][0]),
                    $bitstoshortreal(matrix_register_array[6][0][1]),
                    $bitstoshortreal(matrix_register_array[6][0][2]),
                    $bitstoshortreal(matrix_register_array[6][1][0]),
                    $bitstoshortreal(matrix_register_array[6][1][1]),
                    $bitstoshortreal(matrix_register_array[6][1][2]),
                    $bitstoshortreal(matrix_register_array[6][2][0]),
                    $bitstoshortreal(matrix_register_array[6][2][1]),
                    $bitstoshortreal(matrix_register_array[6][2][2]));
        $display("\t3x3 MATRIX REGISTER[7]\n\t %f\t%f\t%f \n\t %f\t%f\t%f \n\t %f\t%f\t%f \n", 
                    $bitstoshortreal(matrix_register_array[7][0][0]),
                    $bitstoshortreal(matrix_register_array[7][0][1]),
                    $bitstoshortreal(matrix_register_array[7][0][2]),
                    $bitstoshortreal(matrix_register_array[7][1][0]),
                    $bitstoshortreal(matrix_register_array[7][1][1]),
                    $bitstoshortreal(matrix_register_array[7][1][2]),
                    $bitstoshortreal(matrix_register_array[7][2][0]),
                    $bitstoshortreal(matrix_register_array[7][2][1]),
                    $bitstoshortreal(matrix_register_array[7][2][2]));
    endtask : simulation_register_dump

endpackage : testbench_utilities
