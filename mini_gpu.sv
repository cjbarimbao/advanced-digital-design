`timescale 1ns / 1ps

//===========================
// Mini GPU Core
//===========================

module mini_gpu #(

    parameter PIXEL_WIDTH           = 8,
    parameter ADDR_WIDTH            = 18,
    parameter FILTER_WIDTH          = 2,
    parameter ARRAY_WIDTH           = 4
    
)(
    //===========================
    // Clocks and resets
    //===========================
    input                      i_clk,
    input                      i_nrst,
    
    //===========================
    // Raw image ports
    //===========================    
    input   [PIXEL_WIDTH-1:0]  i_mem_pixel,
    output  [ADDR_WIDTH-1 :0]  o_mem_addr,
    
    //===========================
    // Microcontroller ports
    //===========================
    input                      i_start_pulse,
    input   [FILTER_WIDTH-1:0] i_filter_type,
    output                     o_finish_pulse,
    
    //===========================
    // Output data
    //===========================
    output                     o_filtered_wstb,     // Produces a pulse when the processing is done, to be used as control signal for loading
    output  [ADDR_WIDTH-1 :0]  o_filtered_addr,
    output  [PIXEL_WIDTH-1:0]  o_filtered_pixel
);
    //===========================
    // Wire declarations
    //===========================
    wire load_pixel, init, filter_en, shift;

    //===========================
    // Instantiating GPU controller
    //===========================
    gpu_controller i_gpu_controller (
    
        .i_clk              (i_clk              ),      // Clock
        .i_nrst             (i_nrst             ),      // Reset
        .i_start_pulse      (i_start_pulse      ),      // Starts processing when asserted for 1 clock cycle
        .o_mem_addr         (o_mem_addr         ),      // Selects wnich pixel to read from memory
        .o_finish_pulse     (o_finish_pulse     ),      // Indicates processing is done when asserted for 1 clock cycle
        .o_load_pixel       (load_pixel         ),      // Loads the selected pixel to the buffer
        .o_init             (init               ),      // Initializes all registers and counters
        .o_filter_en        (filter_en          ),      // Enables filter operation
        .o_shift            (shift              ),      // Shifts the elements of the buffer upwards
        .o_filtered_wstb    (o_filtered_wstb    ),      // Writes the filtered pixel to the memory when asserted
        .o_filtered_addr    (o_filtered_addr    )       // Address where the gpu will write the filtered pixel
        
    );
    
    //===========================
    // Instantiating GPU arithmetic
    //===========================
    gpu_arithmetic i_gpu_arithmetic (
    
        .i_clk              (i_clk              ),      // Clock
        .i_nrst             (i_nrst             ),      // Reset
        .i_mem_pixel        (i_mem_pixel        ),      // Pixel data from memory
        .i_mem_addr         (o_mem_addr         ),      // Address of the pixel to read from memory
        .i_init             (init               ),      // Initializes all registers and counters
        .i_load_pixel       (load_pixel         ),      // Loads the selected pixel to the buffer
        .i_filter_en        (filter_en          ),      // Enables filter operation
        .i_shift            (shift              ),      // Shifts the elements of the buffer upwards
        .i_filter_type      (i_filter_type      ),      // Determines which filter to use
        .o_filtered_pixel   (o_filtered_pixel   )       // Filtered pixel data
        
    );
    
    

endmodule