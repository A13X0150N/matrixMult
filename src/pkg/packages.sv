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
    parameter M = 6;                        // Maximum register row size
    parameter N = 6;                        // Maximum register column size
    parameter MATRIX_REGISTERS = 8;         // Size of matrix register file

    ///////////////////////////////////////////////////////////////////////////////////////////////////////

    // Single-precision floating point
    //if (FP == 32) begin
        parameter MIN_EXP = -128;
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
    import global_defs::M;
    import global_defs::N;
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
        bit [EXPBITS-1:0] exponent;
        bit [2*MANBITS+3:0] mantissa;
    } internal_float_sp;

    // Vectorized matrix data type
    typedef struct packed{
        float_sp [0:M*N-1] matrix;
    } vectorized_matrix_sp;

    // Stimulus item
    typedef struct packed {
        vectorized_matrix_sp generated_matrix;
        bool_e ready_to_load;
        bool_e ready_to_store;
        bool_e ready_to_multiply;
        bool_e ready_to_multiply_repeat;
        bit [MATRIX_REG_BITS:0] addr0;
        bit [MATRIX_REG_BITS:0] addr1;
        bit [MATRIX_REG_BITS:0] dest;
    } stim_data_sp;

    // MPU bus sequence item struct
    typedef struct packed {
        // Request fields
        mpu_instruction_e op;
        vectorized_matrix_sp matrix_in;
        bit [MBITS:0] m_in;
        bit [NBITS:0] n_in;
        bit [MATRIX_REG_BITS:0] src_addr_0;
        bit [MATRIX_REG_BITS:0] src_addr_1;
        bit [MATRIX_REG_BITS:0] dest_addr;
      
        // Response fields
        vectorized_matrix_sp matrix_out;
    } mpu_data_sp;

    typedef struct packed {
        vectorized_matrix_sp load_matrix;
        bit [MBITS:0] m;
        bit [NBITS:0] n;
        bit [MATRIX_REG_BITS:0] addr0;
    } mpu_load_sp;

    typedef struct packed {
        vectorized_matrix_sp store_matrix;    
        bit [MATRIX_REG_BITS:0] addr0;
    } mpu_store_sp;

    typedef struct packed {
        bit [MATRIX_REG_BITS:0] addr0;
        bit [MATRIX_REG_BITS:0] addr1;
        bit [MATRIX_REG_BITS:0] dest;
    } mpu_multiply_sp;
endpackage : mpu_data_types


// Testbench functions and tasks
package testbench_utilities;
    import global_defs::FPBITS;
    import global_defs::MATRIX_REGISTERS;
    import global_defs::M;
    import global_defs::N;
    import mpu_data_types::mpu_data_sp;
    import mpu_data_types::mpu_load_sp;
    import mpu_data_types::mpu_store_sp;
    import mpu_data_types::mpu_multiply_sp;
    import mpu_data_types::float_sp;
    import mpu_data_types::vectorized_matrix_sp;
    parameter CLOCK_PERIOD = 10;                // Clock Perid
    parameter MAX_CYCLES = 1000000;             // Maximum clock cycles
    parameter M_MEM = 6;                        // Testbench input matrix rows     MUST BE <=M
    parameter N_MEM = 6;                        // Testbench input matrix columns  MUST BE <=N
    parameter NUM_ELEMENTS = M_MEM * N_MEM;     // Number of input elements per matrix for testbench
    parameter BIG_FLOAT_32 = 32'h7f7fffff;      // Very large number to force overflow
    parameter SMALL_FLOAT_32 = 32'h00800000;    // Very small number to force underflow
    parameter MAX_ERROR = 10.0;                 // Maximum tolerated error accumulated across a matrix

    // Matrix generator, incremental order
    function vectorized_matrix_sp generate_matrix(input shortreal seed, input shortreal scale);
        vectorized_matrix_sp genmat;
        for (int i = 0; i < NUM_ELEMENTS; ++i) begin
            genmat = {genmat, $shortrealtobits(seed + i * scale)};
        end
        return genmat;
    endfunction : generate_matrix

    // Matrix generator, decremental order
    function vectorized_matrix_sp generate_matrix_reverse(input shortreal seed, input shortreal scale);
        vectorized_matrix_sp genmat;
        for (int i = NUM_ELEMENTS; i; --i) begin
            genmat = {genmat, $shortrealtobits(seed + i * scale)};
        end
        return genmat;
    endfunction : generate_matrix_reverse

    // Generate a 'random' 32-bit float
    function shortreal random_float();
        random_float = 1+($urandom%1000)/1000.0;
    endfunction : random_float

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
        else if (NUM_ELEMENTS == 36) begin
            $display("\t6x6 MATRIX REGISTER\n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n", 
                        $bitstoshortreal(matrix[0]),
                        $bitstoshortreal(matrix[1]),
                        $bitstoshortreal(matrix[2]),
                        $bitstoshortreal(matrix[3]),
                        $bitstoshortreal(matrix[4]),
                        $bitstoshortreal(matrix[5]),
                        $bitstoshortreal(matrix[6]),
                        $bitstoshortreal(matrix[7]),
                        $bitstoshortreal(matrix[8]),
                        $bitstoshortreal(matrix[9]),
                        $bitstoshortreal(matrix[10]),
                        $bitstoshortreal(matrix[11]),
                        $bitstoshortreal(matrix[12]),
                        $bitstoshortreal(matrix[13]),
                        $bitstoshortreal(matrix[14]),
                        $bitstoshortreal(matrix[15]),
                        $bitstoshortreal(matrix[16]),
                        $bitstoshortreal(matrix[17]),
                        $bitstoshortreal(matrix[18]),
                        $bitstoshortreal(matrix[19]),
                        $bitstoshortreal(matrix[20]),
                        $bitstoshortreal(matrix[21]),
                        $bitstoshortreal(matrix[22]),
                        $bitstoshortreal(matrix[23]),
                        $bitstoshortreal(matrix[24]),
                        $bitstoshortreal(matrix[25]),
                        $bitstoshortreal(matrix[26]),
                        $bitstoshortreal(matrix[27]),
                        $bitstoshortreal(matrix[28]),
                        $bitstoshortreal(matrix[29]),
                        $bitstoshortreal(matrix[30]),
                        $bitstoshortreal(matrix[31]),
                        $bitstoshortreal(matrix[32]),
                        $bitstoshortreal(matrix[33]),
                        $bitstoshortreal(matrix[34]),
                        $bitstoshortreal(matrix[35]));
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
        $display("\t6x6 MATRIX REGISTER[0]\n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n",
                    $bitstoshortreal(matrix_register_array[0][0][0]),
                    $bitstoshortreal(matrix_register_array[0][0][1]),
                    $bitstoshortreal(matrix_register_array[0][0][2]),
                    $bitstoshortreal(matrix_register_array[0][0][3]),
                    $bitstoshortreal(matrix_register_array[0][0][4]),
                    $bitstoshortreal(matrix_register_array[0][0][5]),
                    $bitstoshortreal(matrix_register_array[0][1][0]),
                    $bitstoshortreal(matrix_register_array[0][1][1]),
                    $bitstoshortreal(matrix_register_array[0][1][2]),
                    $bitstoshortreal(matrix_register_array[0][1][3]),
                    $bitstoshortreal(matrix_register_array[0][1][4]),
                    $bitstoshortreal(matrix_register_array[0][1][5]),
                    $bitstoshortreal(matrix_register_array[0][2][0]),
                    $bitstoshortreal(matrix_register_array[0][2][1]),
                    $bitstoshortreal(matrix_register_array[0][2][2]),
                    $bitstoshortreal(matrix_register_array[0][2][3]),
                    $bitstoshortreal(matrix_register_array[0][2][4]),
                    $bitstoshortreal(matrix_register_array[0][2][5]),   
                    $bitstoshortreal(matrix_register_array[0][3][0]),
                    $bitstoshortreal(matrix_register_array[0][3][1]),
                    $bitstoshortreal(matrix_register_array[0][3][2]),
                    $bitstoshortreal(matrix_register_array[0][3][3]),
                    $bitstoshortreal(matrix_register_array[0][3][4]),
                    $bitstoshortreal(matrix_register_array[0][3][5]),
                    $bitstoshortreal(matrix_register_array[0][4][0]),
                    $bitstoshortreal(matrix_register_array[0][4][1]),
                    $bitstoshortreal(matrix_register_array[0][4][2]),
                    $bitstoshortreal(matrix_register_array[0][4][3]),
                    $bitstoshortreal(matrix_register_array[0][4][4]),
                    $bitstoshortreal(matrix_register_array[0][4][5]),
                    $bitstoshortreal(matrix_register_array[0][5][0]),
                    $bitstoshortreal(matrix_register_array[0][5][1]),
                    $bitstoshortreal(matrix_register_array[0][5][2]),
                    $bitstoshortreal(matrix_register_array[0][5][3]),
                    $bitstoshortreal(matrix_register_array[0][5][4]),
                    $bitstoshortreal(matrix_register_array[0][5][5]));
        $display("\t6x6 MATRIX REGISTER[1]\n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n",
                    $bitstoshortreal(matrix_register_array[1][0][0]),
                    $bitstoshortreal(matrix_register_array[1][0][1]),
                    $bitstoshortreal(matrix_register_array[1][0][2]),
                    $bitstoshortreal(matrix_register_array[1][0][3]),
                    $bitstoshortreal(matrix_register_array[1][0][4]),
                    $bitstoshortreal(matrix_register_array[1][0][5]),
                    $bitstoshortreal(matrix_register_array[1][1][0]),
                    $bitstoshortreal(matrix_register_array[1][1][1]),
                    $bitstoshortreal(matrix_register_array[1][1][2]),
                    $bitstoshortreal(matrix_register_array[1][1][3]),
                    $bitstoshortreal(matrix_register_array[1][1][4]),
                    $bitstoshortreal(matrix_register_array[1][1][5]),
                    $bitstoshortreal(matrix_register_array[1][2][0]),
                    $bitstoshortreal(matrix_register_array[1][2][1]),
                    $bitstoshortreal(matrix_register_array[1][2][2]),
                    $bitstoshortreal(matrix_register_array[1][2][3]),
                    $bitstoshortreal(matrix_register_array[1][2][4]),
                    $bitstoshortreal(matrix_register_array[1][2][5]),   
                    $bitstoshortreal(matrix_register_array[1][3][0]),
                    $bitstoshortreal(matrix_register_array[1][3][1]),
                    $bitstoshortreal(matrix_register_array[1][3][2]),
                    $bitstoshortreal(matrix_register_array[1][3][3]),
                    $bitstoshortreal(matrix_register_array[1][3][4]),
                    $bitstoshortreal(matrix_register_array[1][3][5]),
                    $bitstoshortreal(matrix_register_array[1][4][0]),
                    $bitstoshortreal(matrix_register_array[1][4][1]),
                    $bitstoshortreal(matrix_register_array[1][4][2]),
                    $bitstoshortreal(matrix_register_array[1][4][3]),
                    $bitstoshortreal(matrix_register_array[1][4][4]),
                    $bitstoshortreal(matrix_register_array[1][4][5]),
                    $bitstoshortreal(matrix_register_array[1][5][0]),
                    $bitstoshortreal(matrix_register_array[1][5][1]),
                    $bitstoshortreal(matrix_register_array[1][5][2]),
                    $bitstoshortreal(matrix_register_array[1][5][3]),
                    $bitstoshortreal(matrix_register_array[1][5][4]),
                    $bitstoshortreal(matrix_register_array[1][5][5]));
        $display("\t6x6 MATRIX REGISTER[2]\n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n",
                    $bitstoshortreal(matrix_register_array[2][0][0]),
                    $bitstoshortreal(matrix_register_array[2][0][1]),
                    $bitstoshortreal(matrix_register_array[2][0][2]),
                    $bitstoshortreal(matrix_register_array[2][0][3]),
                    $bitstoshortreal(matrix_register_array[2][0][4]),
                    $bitstoshortreal(matrix_register_array[2][0][5]),
                    $bitstoshortreal(matrix_register_array[2][1][0]),
                    $bitstoshortreal(matrix_register_array[2][1][1]),
                    $bitstoshortreal(matrix_register_array[2][1][2]),
                    $bitstoshortreal(matrix_register_array[2][1][3]),
                    $bitstoshortreal(matrix_register_array[2][1][4]),
                    $bitstoshortreal(matrix_register_array[2][1][5]),
                    $bitstoshortreal(matrix_register_array[2][2][0]),
                    $bitstoshortreal(matrix_register_array[2][2][1]),
                    $bitstoshortreal(matrix_register_array[2][2][2]),
                    $bitstoshortreal(matrix_register_array[2][2][3]),
                    $bitstoshortreal(matrix_register_array[2][2][4]),
                    $bitstoshortreal(matrix_register_array[2][2][5]),   
                    $bitstoshortreal(matrix_register_array[2][3][0]),
                    $bitstoshortreal(matrix_register_array[2][3][1]),
                    $bitstoshortreal(matrix_register_array[2][3][2]),
                    $bitstoshortreal(matrix_register_array[2][3][3]),
                    $bitstoshortreal(matrix_register_array[2][3][4]),
                    $bitstoshortreal(matrix_register_array[2][3][5]),
                    $bitstoshortreal(matrix_register_array[2][4][0]),
                    $bitstoshortreal(matrix_register_array[2][4][1]),
                    $bitstoshortreal(matrix_register_array[2][4][2]),
                    $bitstoshortreal(matrix_register_array[2][4][3]),
                    $bitstoshortreal(matrix_register_array[2][4][4]),
                    $bitstoshortreal(matrix_register_array[2][4][5]),
                    $bitstoshortreal(matrix_register_array[2][5][0]),
                    $bitstoshortreal(matrix_register_array[2][5][1]),
                    $bitstoshortreal(matrix_register_array[2][5][2]),
                    $bitstoshortreal(matrix_register_array[2][5][3]),
                    $bitstoshortreal(matrix_register_array[2][5][4]),
                    $bitstoshortreal(matrix_register_array[2][5][5]));
        $display("\t6x6 MATRIX REGISTER[3]\n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n",
                    $bitstoshortreal(matrix_register_array[3][0][0]),
                    $bitstoshortreal(matrix_register_array[3][0][1]),
                    $bitstoshortreal(matrix_register_array[3][0][2]),
                    $bitstoshortreal(matrix_register_array[3][0][3]),
                    $bitstoshortreal(matrix_register_array[3][0][4]),
                    $bitstoshortreal(matrix_register_array[3][0][5]),
                    $bitstoshortreal(matrix_register_array[3][1][0]),
                    $bitstoshortreal(matrix_register_array[3][1][1]),
                    $bitstoshortreal(matrix_register_array[3][1][2]),
                    $bitstoshortreal(matrix_register_array[3][1][3]),
                    $bitstoshortreal(matrix_register_array[3][1][4]),
                    $bitstoshortreal(matrix_register_array[3][1][5]),
                    $bitstoshortreal(matrix_register_array[3][2][0]),
                    $bitstoshortreal(matrix_register_array[3][2][1]),
                    $bitstoshortreal(matrix_register_array[3][2][2]),
                    $bitstoshortreal(matrix_register_array[3][2][3]),
                    $bitstoshortreal(matrix_register_array[3][2][4]),
                    $bitstoshortreal(matrix_register_array[3][2][5]),   
                    $bitstoshortreal(matrix_register_array[3][3][0]),
                    $bitstoshortreal(matrix_register_array[3][3][1]),
                    $bitstoshortreal(matrix_register_array[3][3][2]),
                    $bitstoshortreal(matrix_register_array[3][3][3]),
                    $bitstoshortreal(matrix_register_array[3][3][4]),
                    $bitstoshortreal(matrix_register_array[3][3][5]),
                    $bitstoshortreal(matrix_register_array[3][4][0]),
                    $bitstoshortreal(matrix_register_array[3][4][1]),
                    $bitstoshortreal(matrix_register_array[3][4][2]),
                    $bitstoshortreal(matrix_register_array[3][4][3]),
                    $bitstoshortreal(matrix_register_array[3][4][4]),
                    $bitstoshortreal(matrix_register_array[3][4][5]),
                    $bitstoshortreal(matrix_register_array[3][5][0]),
                    $bitstoshortreal(matrix_register_array[3][5][1]),
                    $bitstoshortreal(matrix_register_array[3][5][2]),
                    $bitstoshortreal(matrix_register_array[3][5][3]),
                    $bitstoshortreal(matrix_register_array[3][5][4]),
                    $bitstoshortreal(matrix_register_array[3][5][5]));
        $display("\t6x6 MATRIX REGISTER[4]\n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n",
                    $bitstoshortreal(matrix_register_array[4][0][0]),
                    $bitstoshortreal(matrix_register_array[4][0][1]),
                    $bitstoshortreal(matrix_register_array[4][0][2]),
                    $bitstoshortreal(matrix_register_array[4][0][3]),
                    $bitstoshortreal(matrix_register_array[4][0][4]),
                    $bitstoshortreal(matrix_register_array[4][0][5]),
                    $bitstoshortreal(matrix_register_array[4][1][0]),
                    $bitstoshortreal(matrix_register_array[4][1][1]),
                    $bitstoshortreal(matrix_register_array[4][1][2]),
                    $bitstoshortreal(matrix_register_array[4][1][3]),
                    $bitstoshortreal(matrix_register_array[4][1][4]),
                    $bitstoshortreal(matrix_register_array[4][1][5]),
                    $bitstoshortreal(matrix_register_array[4][2][0]),
                    $bitstoshortreal(matrix_register_array[4][2][1]),
                    $bitstoshortreal(matrix_register_array[4][2][2]),
                    $bitstoshortreal(matrix_register_array[4][2][3]),
                    $bitstoshortreal(matrix_register_array[4][2][4]),
                    $bitstoshortreal(matrix_register_array[4][2][5]),   
                    $bitstoshortreal(matrix_register_array[4][3][0]),
                    $bitstoshortreal(matrix_register_array[4][3][1]),
                    $bitstoshortreal(matrix_register_array[4][3][2]),
                    $bitstoshortreal(matrix_register_array[4][3][3]),
                    $bitstoshortreal(matrix_register_array[4][3][4]),
                    $bitstoshortreal(matrix_register_array[4][3][5]),
                    $bitstoshortreal(matrix_register_array[4][4][0]),
                    $bitstoshortreal(matrix_register_array[4][4][1]),
                    $bitstoshortreal(matrix_register_array[4][4][2]),
                    $bitstoshortreal(matrix_register_array[4][4][3]),
                    $bitstoshortreal(matrix_register_array[4][4][4]),
                    $bitstoshortreal(matrix_register_array[4][4][5]),
                    $bitstoshortreal(matrix_register_array[4][5][0]),
                    $bitstoshortreal(matrix_register_array[4][5][1]),
                    $bitstoshortreal(matrix_register_array[4][5][2]),
                    $bitstoshortreal(matrix_register_array[4][5][3]),
                    $bitstoshortreal(matrix_register_array[4][5][4]),
                    $bitstoshortreal(matrix_register_array[4][5][5]));
        $display("\t6x6 MATRIX REGISTER[5]\n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n",
                    $bitstoshortreal(matrix_register_array[5][0][0]),
                    $bitstoshortreal(matrix_register_array[5][0][1]),
                    $bitstoshortreal(matrix_register_array[5][0][2]),
                    $bitstoshortreal(matrix_register_array[5][0][3]),
                    $bitstoshortreal(matrix_register_array[5][0][4]),
                    $bitstoshortreal(matrix_register_array[5][0][5]),
                    $bitstoshortreal(matrix_register_array[5][1][0]),
                    $bitstoshortreal(matrix_register_array[5][1][1]),
                    $bitstoshortreal(matrix_register_array[5][1][2]),
                    $bitstoshortreal(matrix_register_array[5][1][3]),
                    $bitstoshortreal(matrix_register_array[5][1][4]),
                    $bitstoshortreal(matrix_register_array[5][1][5]),
                    $bitstoshortreal(matrix_register_array[5][2][0]),
                    $bitstoshortreal(matrix_register_array[5][2][1]),
                    $bitstoshortreal(matrix_register_array[5][2][2]),
                    $bitstoshortreal(matrix_register_array[5][2][3]),
                    $bitstoshortreal(matrix_register_array[5][2][4]),
                    $bitstoshortreal(matrix_register_array[5][2][5]),   
                    $bitstoshortreal(matrix_register_array[5][3][0]),
                    $bitstoshortreal(matrix_register_array[5][3][1]),
                    $bitstoshortreal(matrix_register_array[5][3][2]),
                    $bitstoshortreal(matrix_register_array[5][3][3]),
                    $bitstoshortreal(matrix_register_array[5][3][4]),
                    $bitstoshortreal(matrix_register_array[5][3][5]),
                    $bitstoshortreal(matrix_register_array[5][4][0]),
                    $bitstoshortreal(matrix_register_array[5][4][1]),
                    $bitstoshortreal(matrix_register_array[5][4][2]),
                    $bitstoshortreal(matrix_register_array[5][4][3]),
                    $bitstoshortreal(matrix_register_array[5][4][4]),
                    $bitstoshortreal(matrix_register_array[5][4][5]),
                    $bitstoshortreal(matrix_register_array[5][5][0]),
                    $bitstoshortreal(matrix_register_array[5][5][1]),
                    $bitstoshortreal(matrix_register_array[5][5][2]),
                    $bitstoshortreal(matrix_register_array[5][5][3]),
                    $bitstoshortreal(matrix_register_array[5][5][4]),
                    $bitstoshortreal(matrix_register_array[5][5][5]));
        $display("\t6x6 MATRIX REGISTER[6]\n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n",
                    $bitstoshortreal(matrix_register_array[6][0][0]),
                    $bitstoshortreal(matrix_register_array[6][0][1]),
                    $bitstoshortreal(matrix_register_array[6][0][2]),
                    $bitstoshortreal(matrix_register_array[6][0][3]),
                    $bitstoshortreal(matrix_register_array[6][0][4]),
                    $bitstoshortreal(matrix_register_array[6][0][5]),
                    $bitstoshortreal(matrix_register_array[6][1][0]),
                    $bitstoshortreal(matrix_register_array[6][1][1]),
                    $bitstoshortreal(matrix_register_array[6][1][2]),
                    $bitstoshortreal(matrix_register_array[6][1][3]),
                    $bitstoshortreal(matrix_register_array[6][1][4]),
                    $bitstoshortreal(matrix_register_array[6][1][5]),
                    $bitstoshortreal(matrix_register_array[6][2][0]),
                    $bitstoshortreal(matrix_register_array[6][2][1]),
                    $bitstoshortreal(matrix_register_array[6][2][2]),
                    $bitstoshortreal(matrix_register_array[6][2][3]),
                    $bitstoshortreal(matrix_register_array[6][2][4]),
                    $bitstoshortreal(matrix_register_array[6][2][5]),   
                    $bitstoshortreal(matrix_register_array[6][3][0]),
                    $bitstoshortreal(matrix_register_array[6][3][1]),
                    $bitstoshortreal(matrix_register_array[6][3][2]),
                    $bitstoshortreal(matrix_register_array[6][3][3]),
                    $bitstoshortreal(matrix_register_array[6][3][4]),
                    $bitstoshortreal(matrix_register_array[6][3][5]),
                    $bitstoshortreal(matrix_register_array[6][4][0]),
                    $bitstoshortreal(matrix_register_array[6][4][1]),
                    $bitstoshortreal(matrix_register_array[6][4][2]),
                    $bitstoshortreal(matrix_register_array[6][4][3]),
                    $bitstoshortreal(matrix_register_array[6][4][4]),
                    $bitstoshortreal(matrix_register_array[6][4][5]),
                    $bitstoshortreal(matrix_register_array[6][5][0]),
                    $bitstoshortreal(matrix_register_array[6][5][1]),
                    $bitstoshortreal(matrix_register_array[6][5][2]),
                    $bitstoshortreal(matrix_register_array[6][5][3]),
                    $bitstoshortreal(matrix_register_array[6][5][4]),
                    $bitstoshortreal(matrix_register_array[6][5][5]));
        $display("\t6x6 MATRIX REGISTER[7]\n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n\t %f\t%f\t%f\t%f\t%f\t%f \n",
                    $bitstoshortreal(matrix_register_array[7][0][0]),
                    $bitstoshortreal(matrix_register_array[7][0][1]),
                    $bitstoshortreal(matrix_register_array[7][0][2]),
                    $bitstoshortreal(matrix_register_array[7][0][3]),
                    $bitstoshortreal(matrix_register_array[7][0][4]),
                    $bitstoshortreal(matrix_register_array[7][0][5]),
                    $bitstoshortreal(matrix_register_array[7][1][0]),
                    $bitstoshortreal(matrix_register_array[7][1][1]),
                    $bitstoshortreal(matrix_register_array[7][1][2]),
                    $bitstoshortreal(matrix_register_array[7][1][3]),
                    $bitstoshortreal(matrix_register_array[7][1][4]),
                    $bitstoshortreal(matrix_register_array[7][1][5]),
                    $bitstoshortreal(matrix_register_array[7][2][0]),
                    $bitstoshortreal(matrix_register_array[7][2][1]),
                    $bitstoshortreal(matrix_register_array[7][2][2]),
                    $bitstoshortreal(matrix_register_array[7][2][3]),
                    $bitstoshortreal(matrix_register_array[7][2][4]),
                    $bitstoshortreal(matrix_register_array[7][2][5]),   
                    $bitstoshortreal(matrix_register_array[7][3][0]),
                    $bitstoshortreal(matrix_register_array[7][3][1]),
                    $bitstoshortreal(matrix_register_array[7][3][2]),
                    $bitstoshortreal(matrix_register_array[7][3][3]),
                    $bitstoshortreal(matrix_register_array[7][3][4]),
                    $bitstoshortreal(matrix_register_array[7][3][5]),
                    $bitstoshortreal(matrix_register_array[7][4][0]),
                    $bitstoshortreal(matrix_register_array[7][4][1]),
                    $bitstoshortreal(matrix_register_array[7][4][2]),
                    $bitstoshortreal(matrix_register_array[7][4][3]),
                    $bitstoshortreal(matrix_register_array[7][4][4]),
                    $bitstoshortreal(matrix_register_array[7][4][5]),
                    $bitstoshortreal(matrix_register_array[7][5][0]),
                    $bitstoshortreal(matrix_register_array[7][5][1]),
                    $bitstoshortreal(matrix_register_array[7][5][2]),
                    $bitstoshortreal(matrix_register_array[7][5][3]),
                    $bitstoshortreal(matrix_register_array[7][5][4]),
                    $bitstoshortreal(matrix_register_array[7][5][5]));
    endtask : simulation_register_dump
endpackage : testbench_utilities


// Stimulus includes
package hvl_stimulus_includes;
    `include "src/hvl/stimulus_tb.sv"
    `include "src/hvl/tests/mpu_load_store.sv"
    `include "src/hvl/tests/mpu_cluster_unit.sv"
    `include "src/hvl/tests/mpu_mult_pos_one.sv"
    `include "src/hvl/tests/mpu_mult_neg_one.sv"
    `include "src/hvl/tests/mpu_mult_zero.sv"
    `include "src/hvl/tests/mpu_mult_inverse.sv"
    `include "src/hvl/tests/mpu_mult_random.sv"
    `include "src/hvl/tests/mpu_mult_repeat.sv"
    `include "src/hvl/tests/mpu_overflow_underflow.sv"
endpackage : hvl_stimulus_includes
