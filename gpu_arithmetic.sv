`timescale 1ns / 1ps

module gpu_arithmetic #(
 
    //===========================
    // Parameter widths
    //===========================
    parameter PIXEL_WIDTH           = 8,
    parameter ADDR_WIDTH            = 18,
    parameter FILTER_WIDTH          = 2,
    parameter ZP_IMAGE_WIDTH        = 482,
    parameter ZP_IMAGE_HEIGHT       = 362,
    parameter BUFFER_WIDTH          = 3,
    parameter BUFFER_COUNT          = ZP_IMAGE_WIDTH*BUFFER_WIDTH
    
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
    input   [ADDR_WIDTH-1 :0]  i_mem_addr,
    
    //===========================
    // Control signals
    //===========================
    input                      i_init,
    input                      i_load_pixel,
    input                      i_filter_en,
    input                      i_shift,
    input   [FILTER_WIDTH-1:0] i_filter_type,
    
    //===========================
    // Output data
    //===========================
    output  [PIXEL_WIDTH-1:0]  o_filtered_pixel
);
    
    //===========================
    // Wire and reg declarations
    //===========================

    reg  [FILTER_WIDTH-1:0] filter_type;
    wire [PIXEL_WIDTH-1:0]  pixel_buffer [0:BUFFER_WIDTH-1][0:ZP_IMAGE_WIDTH-1];
    
    input_buffer i_input_buffer (
        
        .i_clk              (i_clk              ),
        .i_nrst             (i_nrst             ),
        .i_mem_pixel        (i_mem_pixel        ),
        .i_mem_addr         (i_mem_addr         ),
        .i_en               (i_load_pixel       ),
        .i_shift            (i_shift            ),
        .o_pixel_buffer     (pixel_buffer       )       // 3 x 482 Pixel Buffer

    );

    image_filter i_image_filter (
        
        .i_clk              (i_clk              ),
        .i_nrst             (i_nrst             ),
        .i_en               (i_filter_en        ),
        .i_filter_type      (filter_type        ),
        .i_pixel_buffer     (pixel_buffer       ),
        .o_filtered_pixel   (o_filtered_pixel   )
    
    );

    always@(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            filter_type <= 0;
        end else begin
            if (i_init) begin
                filter_type <= i_filter_type;
            end
        end
    end
    
endmodule