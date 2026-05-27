`timescale 1ns/1ns

(* top *) module top ( 
    (* iopad_external_pin, clkbuf_inhibit *) input clk,     // System Clock (50MHz) 
    (* iopad_external_pin *) output clk_en, 
    (* iopad_external_pin *) input rst_n,                   // System Reset (Active Low)
    
    (* iopad_external_pin *) input spi_ss_n,               
    (* iopad_external_pin *) input spi_sck,                
    (* iopad_external_pin *) input spi_mosi,               
    (* iopad_external_pin *) output spi_miso,               
    (* iopad_external_pin *) output spi_miso_en,            
    
    (* iopad_external_pin *) input PDM                      
);

    assign clk_en = 1'b1; // powering oscillator block 

    wire [7:0] rx_data_wire;   // Data bus coming out of receiver 
    wire       rx_valid_pulse; // High for 1 cycle when an 8-bit frame completes 
    reg  [7:0] tx_data_reg;    // Register feeding the transmitter buffer 

    // Standard Echo Loopback Pipeline Logic    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_data_reg <= 8'h00; // Reset register to clear bus memory 
        end else if (rx_valid_pulse) begin
            tx_data_reg <= rx_data_wire; // Latch incoming data straight to output 
        end
    end
    
    // Instantiating SPI interface
    spi_target #(
        .CPOL(1'b0),   
        .CPHA(1'b0),   
        .WIDTH(8),     
        .LSB(1'b0)     
    ) u_spi_target (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_enable(1'b1),        // Permanently activate the peripheral block 

        // Connect physical SPI bus tracks 
        .i_ss_n(spi_ss_n),
        .i_sck(spi_sck),
        .i_mosi(spi_mosi),
        .o_miso(spi_miso),
        .o_miso_oe(spi_miso_en),

        // Connect internal logic data lanes 
        .o_rx_data(rx_data_wire),
        .o_rx_data_valid(rx_valid_pulse),
        .i_tx_data(tx_data_reg), 
        .o_tx_data_hold()        
    );

endmodule