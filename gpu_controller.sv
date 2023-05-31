`timescale 1ns / 1ps

module gpu_controller#(

    //===========================
    // Parameter widths
    //===========================
    parameter PIXEL_WIDTH           = 8,
    parameter ADDR_WIDTH            = 18,
    parameter FILTER_WIDTH          = 2,
    parameter ZP_IMAGE_WIDTH        = 482,
    parameter ZP_IMAGE_HEIGHT       = 362,
    parameter IMAGE_WIDTH           = ZP_IMAGE_WIDTH  - 2,
    parameter IMAGE_HEIGHT          = ZP_IMAGE_HEIGHT - 2,
    parameter PIXEL_COUNT           = IMAGE_HEIGHT*IMAGE_WIDTH,
    parameter BUFFER_WIDTH          = 3,
    parameter BUFFER_COUNT          = ZP_IMAGE_WIDTH*BUFFER_WIDTH,

    //===========================
    // State parameters
    //===========================
    
    parameter S_idle                = 3'd0,
    parameter S_init_buffer         = 3'd1,
    parameter S_filter              = 3'd2,
    parameter S_shift               = 3'd3,
    parameter S_load_buffer         = 3'd4,
    parameter S_done                = 3'd5

)(
    //===========================
    // Clocks and resets
    //===========================
    input                          i_clk,
    input                          i_nrst,
    
    //===========================
    // Raw image ports
    //===========================
    output reg  [ADDR_WIDTH-1 :0]  o_mem_addr,
    
    //===========================
    // Microcontroller ports
    //===========================
    input                          i_start_pulse,
    output reg                     o_finish_pulse,
    
    //===========================
    // Control signals
    //===========================
    output                         o_load_pixel,
    output                         o_init,
    output                         o_filter_en,
    output                         o_shift,

    //===========================
    // Output data
    //===========================

    output                         o_filtered_wstb,     // Produces a pulse when the processing is done, to be used as control signal for loading
    output reg [ADDR_WIDTH-1 :0]   o_filtered_addr

);

    //===========================
    // Variable declarations
    //===========================
    
    reg [2:0] state;                // Holds current state of the controller
    reg       init;                 // Initializes registers and counters
    reg       load_addr;            // Moves on to the next pixel address to read from memory when asserted
    reg       load_pixel;           // Loads the current selected pixel to the buffer when asserted
    reg       filter_en;            // Enables the operation of the filter when asserted
    reg       shift;                // Shifts the input buffer up when asserted
    reg       shift_ctr_incr;       // Increments shift_ctr when asserted
    reg       buffer_ctr_incr;      // Increments buffer_ctr when asserted
    reg       filtered_addr_incr;   // Increments filtered_addr when asserted
    int       shift_ctr;            // Asserts shift when shift_ctr == IMAGE_WIDTH
    int       buffer_ctr;           // Determines when to stop loading the buffer
    
    assign o_load_pixel     = load_pixel;
    assign o_init           = init;
    assign o_filter_en      = filter_en;
    assign o_shift          = shift;
    assign o_filtered_wstb  = filter_en;
    
    always@(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            o_mem_addr <= 0;
        end else begin
            if (init) begin
                o_mem_addr <= 0;
            end else begin
                if (load_addr) begin
                    o_mem_addr <= o_mem_addr + 1;
                end
            end
        end
    end
    
    always@(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            buffer_ctr <= 0;
        end else begin
            if (filter_en) begin
                buffer_ctr <= 0;
            end else begin
                if (buffer_ctr_incr) begin
                    buffer_ctr <= buffer_ctr + 1;
                end
            end
        end
    end
    
    always@(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            o_filtered_addr <= 0;
        end else begin
            if (init) begin
                o_filtered_addr <= 0;
            end else begin
                if (filtered_addr_incr) begin
                    o_filtered_addr <= o_filtered_addr + 1;
                end
            end
        end
    end
    
    always@(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            shift_ctr <= 0;
        end else begin
            if (init) begin
                shift_ctr <= 0;
            end else begin
                if (shift_ctr_incr) begin
                    shift_ctr <= shift_ctr + 1;
                end else begin
                    if (shift) begin
                        shift_ctr <= 0;
                    end
                end
            end
        end
    end
    
    always@(posedge i_clk or negedge i_nrst) begin
        if (!i_nrst) begin
            state <= S_idle;
        end else begin
            case (state)
                S_idle: begin 
                    if (i_start_pulse) begin
                        state <= S_init_buffer;
                    end else begin
                        state <= S_idle;
                    end
                end
                S_init_buffer: begin
                    if (o_mem_addr < BUFFER_COUNT - 1) begin
                        state <= S_init_buffer;
                    end else begin
                        state <= S_filter;
                    end
                end
                S_filter: begin
                    if (o_filtered_addr == PIXEL_COUNT - 1) begin
                        state <= S_done;
                    end else begin
                        if (shift_ctr < IMAGE_WIDTH - 1) begin
                            state <= S_filter;
                        end else begin
                            state <= S_shift;
                        end
                    end
                end
                S_shift: begin
                    state <= S_load_buffer;
                end
                S_load_buffer: begin
                    if (buffer_ctr < ZP_IMAGE_WIDTH - 1) begin
                        state <= S_load_buffer;
                    end else begin
                        state <= S_filter;
                    end
                end
                default: begin
                    state <= S_idle;
                end
            endcase
        end
    end
    
    always@(*)begin
        init = 0;
        load_addr = 0;
        load_pixel = 0;
        filter_en = 0;
        filtered_addr_incr = 0;
        shift_ctr_incr = 0;
        shift = 0;
        buffer_ctr_incr = 0;
        load_addr = 0;
        o_finish_pulse = 0;
        case (state)
            S_idle: begin
                if (i_start_pulse) begin
                    init = 1;
                end
            end
            S_init_buffer: begin
                load_pixel = 1;
                load_addr = 1;
            end
            S_filter: begin
                filter_en = 1;
                if (o_filtered_addr < PIXEL_COUNT - 1) begin
                    filtered_addr_incr = 1;
                    if (shift_ctr < IMAGE_WIDTH - 1) begin
                        shift_ctr_incr = 1;
                    end
                end
            end
            S_shift: begin
                shift = 1;
            end
            S_load_buffer: begin
                load_pixel = 1;
                load_addr = 1;
                if (buffer_ctr < ZP_IMAGE_WIDTH - 1) begin
                    buffer_ctr_incr = 1;
                end
            end
            S_done: begin
                o_finish_pulse = 1;
            end
        endcase
    end

endmodule