`timescale 1ns / 1ps

module input_buffer #(
 
    //===========================
    // Parameter widths
    //===========================
    parameter PIXEL_WIDTH           = 8,
    parameter ADDR_WIDTH            = 18,
    parameter ZP_IMAGE_WIDTH        = 482,
    parameter ZP_IMAGE_HEIGHT       = 362,
    parameter BUFFER_WIDTH          = 3,
    parameter BUFFER_COUNT          = ZP_IMAGE_WIDTH*BUFFER_WIDTH

    
)(
    //===========================
    // Clocks and resets
    //===========================
    input                         i_clk,
    input                         i_nrst,
    
    //===========================
    // Raw image ports
    //===========================    
    input      [PIXEL_WIDTH-1:0]  i_mem_pixel,
    input      [ADDR_WIDTH-1 :0]  i_mem_addr,

    //===========================
    // Control signals
    //===========================
    input                         i_en,
    input                         i_shift,

    //===========================
    // Output data
    //===========================
    output reg [PIXEL_WIDTH-1:0]  o_pixel_buffer [0:BUFFER_WIDTH-1][0:ZP_IMAGE_WIDTH-1]
    
);
    reg [1:0]  pixel_i;
    reg [8:0]  pixel_j;
    
    
    always@(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            pixel_j <= 0;
        end else begin
            if (i_en) begin
                if (pixel_j < ZP_IMAGE_WIDTH - 1) begin
                    pixel_j <= pixel_j + 1;
                end else begin
                    pixel_j <= 0;
                end
            end
        end
    end
    
    always@(*) begin
        case (i_mem_addr) inside
            [0:ZP_IMAGE_WIDTH-1]: pixel_i = 0;
            [ZP_IMAGE_WIDTH:BUFFER_COUNT-ZP_IMAGE_WIDTH-1]: pixel_i = 1;
            default: pixel_i = 2;
        endcase
    end
    
    always@(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            foreach (o_pixel_buffer[i,j]) begin
                o_pixel_buffer[i][j] <= 0;
            end
        end else begin
            if (i_en) begin
                o_pixel_buffer[pixel_i][pixel_j] <= i_mem_pixel;
            end else begin
                if (i_shift) begin
                    foreach (o_pixel_buffer[i,j]) begin
                        if (i < 2) begin
                            o_pixel_buffer[i][j] <= o_pixel_buffer[i+1][j];
                        end
                    end
                end
            end
        end
    end
            
endmodule