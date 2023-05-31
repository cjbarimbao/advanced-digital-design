`timescale 1ns / 1ps

module image_filter #(
 
    //===========================
    // Parameter widths
    //===========================
    parameter FILTER_WIDTH          = 2,
    parameter ZP_IMAGE_WIDTH        = 482,
    parameter ZP_IMAGE_HEIGHT       = 362,
    parameter BUFFER_WIDTH          = 3,
    parameter PIXEL_WIDTH           = 8,
    parameter IMAGE_WIDTH           = ZP_IMAGE_WIDTH - 2
    
)(

    input                            i_clk,
    input                            i_nrst,
    input                            i_en,
    input       [FILTER_WIDTH-1:0]   i_filter_type,
    input       [PIXEL_WIDTH-1:0]    i_pixel_buffer [0:BUFFER_WIDTH-1][0:ZP_IMAGE_WIDTH-1],
    output reg  [PIXEL_WIDTH-1:0]    o_filtered_pixel

);
    int a;
    reg [31:0] temp_3by3 [0:2][0:2];
    wire [PIXEL_WIDTH-1:0] w_identity_kernel, w_sharpen_kernel, w_edge_detection_kernel, w_blur_kernel;
    
    
    
    identity_kernel i_identity_kernel (
        .i_3by3(temp_3by3),
        .o_filtered_pixel(w_identity_kernel)
    );
    
    sharpen_kernel i_sharpen_kernel (
        .i_3by3(temp_3by3),
        .o_filtered_pixel(w_sharpen_kernel)
    );
    
    edge_detection_kernel i_edge_detection_kernel (
        .i_3by3(temp_3by3),
        .o_filtered_pixel(w_edge_detection_kernel)
    );
    
    blur_kernel i_blur_kernel (
        .i_3by3(temp_3by3),
        .o_filtered_pixel(w_blur_kernel)
    );
    
    always@(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            a <= 0;
        end else begin
            if (i_en) begin
                if (a < IMAGE_WIDTH - 1) begin
                    a <= a + 1;
                end
            end else begin
                a <= 0;
            end
        end
    end
    
    always@(*) begin
        foreach (temp_3by3[i,j]) begin
            temp_3by3[i][j] <= {24'h0, i_pixel_buffer[i][j+a]};
        end
    end
    
    always@(*) begin
        case (i_filter_type)
            2'b01:   begin o_filtered_pixel = w_sharpen_kernel;        end
            2'b10:   begin o_filtered_pixel = w_edge_detection_kernel; end
            2'b11:   begin o_filtered_pixel = w_blur_kernel;           end
            default: begin o_filtered_pixel = w_identity_kernel;       end
        endcase
    end

endmodule

module identity_kernel(
    input  [31:0] i_3by3 [0:2][0:2],
    output [7:0]  o_filtered_pixel
);
    int filtered_image [0:2][0:2];
    int sum;
    
    assign o_filtered_pixel = sum[7:0];
    
    always@(*) begin
        foreach (i_3by3[i,j]) begin
            if ((i == 1) && (j == 1)) begin
                filtered_image[i][j] = i_3by3[i][j];
            end else begin
                filtered_image[i][j] = 0;
            end
        end
    end
    
    always@(*) begin
        sum = 0;
        foreach (filtered_image[i,j]) begin
            sum = sum + filtered_image[i][j];
        end
        if (sum < 0) begin
            sum = 0;
        end else begin
            if (sum > 255) begin
                sum = 255;
            end
        end
    end
    
endmodule


module sharpen_kernel(
    input [31:0] i_3by3 [0:2][0:2],
    output [7:0]  o_filtered_pixel
);
    int filtered_image [0:2][0:2];
    int sum;
    
    assign o_filtered_pixel = sum[7:0];

    always@(*) begin
        filtered_image[0][0] = 0;
        filtered_image[0][1] = -i_3by3[0][1];
        filtered_image[0][2] = 0;
        filtered_image[1][0] = -i_3by3[1][0];
        filtered_image[1][1] = (i_3by3[1][1] << 2) + (i_3by3[1][1]);
        filtered_image[1][2] = -i_3by3[1][2];
        filtered_image[2][0] = 0;
        filtered_image[2][1] = -i_3by3[2][1];
        filtered_image[2][2] = 0;
    end
    
    always@(*) begin
        sum = 0;
        foreach (filtered_image[i,j]) begin
            sum = sum + filtered_image[i][j];
        end
        if (sum < 0) begin
            sum = 0;
        end else begin
            if (sum > 255) begin
                sum = 255;
            end
        end
    end
    
endmodule

module edge_detection_kernel(
    input [31:0] i_3by3 [0:2][0:2],
    output [7:0]  o_filtered_pixel
);
    int filtered_image [0:2][0:2];
    int sum;
    
    assign o_filtered_pixel = sum[7:0];

    always@(*) begin
        foreach (i_3by3[i,j]) begin
            if ((i == 1) && (j == 1)) begin
                filtered_image[i][j] = (i_3by3[i][j] << 3);
            end else begin
                filtered_image[i][j] = -i_3by3[i][j];
            end
        end
    end
    
    always@(*) begin
        sum = 0;
        foreach (filtered_image[i,j]) begin
            sum = sum + filtered_image[i][j];
        end
        if (sum < 0) begin
            sum = 0;
        end else begin
            if (sum > 255) begin
                sum = 255;
            end
        end
    end
    
endmodule

module blur_kernel(
    input [31:0] i_3by3 [0:2][0:2],
    output [7:0]  o_filtered_pixel
);
    int filtered_image [0:2][0:2];
    int sum;
    
    assign o_filtered_pixel = sum[7:0];
    
    always@(*) begin
        filtered_image[0][0] = i_3by3[0][0];
        filtered_image[0][1] = (i_3by3[0][1] << 1);
        filtered_image[0][2] = i_3by3[0][2];
        filtered_image[1][0] = (i_3by3[1][0] << 1);
        filtered_image[1][1] = (i_3by3[1][1] << 3);
        filtered_image[1][2] = (i_3by3[1][2] << 1);
        filtered_image[2][0] = i_3by3[2][0];
        filtered_image[2][1] = (i_3by3[2][1] << 1);
        filtered_image[2][2] = (i_3by3[2][2]);
    end
    
    always@(*) begin
        sum = 0;
        foreach (filtered_image[i,j]) begin
            sum = sum + filtered_image[i][j];
        end
        sum = (sum[3:0] >= 4'b1000) ? ((sum >> 4) + 1) : (sum >> 4);       // Round up if fractional part is >= 0.5
        if (sum < 0) begin
            sum = 0;
        end else begin
            if (sum > 255) begin
                sum = 255;
            end
        end
    end
    
endmodule