`timescale 1ns/1ns

(* top *) 
module top ( 
    (* iopad_external_pin, clkbuf_inhibit *) input clk,     // Master System Clock (50MHz)
    (* iopad_external_pin *) output clk_en, 
    (* iopad_external_pin *) input rst_n,                   // Active-Low Reset (PIN 9)
    
    // Physical Audio Stream Input Trace
    (* iopad_external_pin *) input PDM,                     // Isolated during loopback test
    
    // Physical SPI Pins mapped directly to your validated board tracks
    (* iopad_external_pin *) input spi_ss_n,                // CS  (PIN 17)
    (* iopad_external_pin *) input spi_sck,                 // SCK (PIN 16)
    (* iopad_external_pin *) input spi_mosi,                // MOSI (PIN 18)
    (* iopad_external_pin *) output spi_miso,               // MISO (PIN 19)
    (* iopad_external_pin *) output spi_miso_en             // MISO OE Pad Link
);

    assign clk_en = 1'b1; // Power up core oscillator module

    // Internal data routing pipelines
    reg  [15:0] tx_data_reg; 
    wire [15:0] rx_data_wire;   
    wire        rx_valid_pulse; 
    wire        rst = ~rst_n; 

    //---------------------------------------------------------
    // STAGE 1: 3-Stage Pipelined High-Speed Integrators
    //---------------------------------------------------------
    // Expanded to 25 bits to handle the theoretical maximum bit growth of R=8 safely
    reg signed [24:0] A1, A2, A3;
    
    // Sign-extend the incoming 16-bit test word up to 25 bits safely
    wire signed [24:0] extended_rx_data = {{9{rx_data_wire[15]}}, rx_data_wire};

    // BREAK CRITICAL TIMING PATH: Every integrator accumulates its own registered history 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A1 <= 25'sh0;
            A2 <= 25'sh0;
            A3 <= 25'sh0;
        end else begin
            A1 <= A1 + extended_rx_data;
            A2 <= A2 + A1;
            A3 <= A3 + A2;
        end
    end

    //---------------------------------------------------------
    // STAGE 2: Decimation/Sampling (R = 8 Downsampling)
    //---------------------------------------------------------
    reg [2:0] count;
    reg       first_cycle;
    wire      wait_ack = (count == 3'd7);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count       <= 3'd0;
            first_cycle <= 1'b1;
        end else begin
            first_cycle <= 1'b0;
            if (!first_cycle) begin
                count <= wait_ack ? 3'd0 : count + 1'b1;
            end
        end
    end

    //---------------------------------------------------------
    // STAGE 3: 3-Stage Differentiators & SPI Output Register
    //---------------------------------------------------------
    reg signed [24:0] C1_z1, C2_z2, C3_z3;
    wire signed [24:0] C1_wire = A3 - C1_z1;
    wire signed [24:0] C2_wire = C1_wire - C2_z2;
    wire signed [24:0] C3_wire = C2_wire - C3_z3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            C1_z1       <= 25'sh0;
            C2_z2       <= 25'sh0;
            C3_z3       <= 25'sh0;
            tx_data_reg <= 16'h0000;
        end else if (wait_ack && !first_cycle) begin
            C1_z1 <= A3;
            C2_z2 <= C1_wire;
            C3_z3 <= C2_wire;
            
            // Map the stabilized filtered 16-bit PCM data segment back to the output register
			tx_data_reg <= C3_wire[15:0];
        end
    end

    //---------------------------------------------------------
    // FACTORY SPI TARGET TRANSCEIVER CORE INSTANTIATION
    //---------------------------------------------------------
    spi_target #(
        .CPOL(1'b0),   
        .CPHA(1'b0),   
        .WIDTH(16),     // Native 16-bit width
        .LSB(1'b0)     
    ) u_spi_target (
        .i_clk(clk),
        .i_rst_n(rst_n),
        .i_enable(1'b1), 

        .i_ss_n(spi_ss_n),
        .i_sck(spi_sck),
        .i_mosi(spi_mosi),
        .o_miso(spi_miso),
        .o_miso_oe(spi_miso_en),

        .o_rx_data(rx_data_wire),          
        .o_rx_data_valid(rx_valid_pulse),
        .i_tx_data(tx_data_reg), 
        .o_tx_data_hold()        
    );

endmodule


//---------------------------------------------------------
// REPAIRED SPI TARGET TRANSCEIVER IP CORE MODULE
//---------------------------------------------------------
module spi_target #(
  parameter CPOL   = 1'b0,  
  parameter CPHA   = 1'b0,  
  parameter WIDTH  = 16,     
  parameter LSB    = 1'b0   
) (
  input                  i_clk,           
  input                  i_rst_n,         
  input                  i_enable,        
  input                  i_ss_n,          
  input                  i_sck,           
  input                  i_mosi,          
  output                 o_miso,          
  output                 o_miso_oe,       
  output reg [WIDTH-1:0] o_rx_data,       
  output reg             o_rx_data_valid, 
  input      [WIDTH-1:0] i_tx_data,       
  output                 o_tx_data_hold   
);

  reg               [2:0] r_ss_n_sync, r_sck_sync;
  
  //Secure 4-bit accurate hardware register layout (counts index 0 to 15 perfectly)
  reg [$clog2(WIDTH)-1:0] r_transmision_count;
  reg         [WIDTH-1:0] r_miso_data;
  wire                    w_sck_r_edge, w_sck_f_edge, w_sck_edge, w_sck_edge_op;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_ss_n_sync <= 'b111;
    end else if (i_enable) begin
      r_ss_n_sync <= {r_ss_n_sync[1:0], i_ss_n};
    end else begin
      r_ss_n_sync <= 'b111;
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_sck_sync <= 'h0;
    end else if (i_enable) begin
      r_sck_sync <= {r_sck_sync[1:0], i_sck};
    end else begin
      r_sck_sync <= 'h0;
    end
  end

  assign w_sck_r_edge  = ~r_sck_sync[2] & r_sck_sync[1];
  assign w_sck_f_edge  = r_sck_sync[2] & ~r_sck_sync[1];
  assign w_sck_edge    = (CPHA^CPOL) ? w_sck_f_edge : w_sck_r_edge;
  assign w_sck_edge_op = (CPHA^CPOL) ? w_sck_r_edge : w_sck_f_edge;

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_transmision_count <= 'h0;
    end else if (!i_enable || r_ss_n_sync[1]) begin
      r_transmision_count <= 'h0;
    end else if (w_sck_edge) begin
      if (r_transmision_count == WIDTH-1) begin
        r_transmision_count <= 'h0;
      end else begin
        r_transmision_count <= r_transmision_count + 1'b1;
      end
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      o_rx_data <= 'h0;
    end else if (w_sck_edge) begin
      if (LSB) begin
        o_rx_data <= {i_mosi, o_rx_data[WIDTH-1:1]};
      end else begin
        o_rx_data <= {o_rx_data[WIDTH-2:0], i_mosi};
      end
    end
  end

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      o_rx_data_valid <= 1'b0;
    end else if (r_ss_n_sync[1] || (r_transmision_count == 0 && w_sck_edge)) begin
      o_rx_data_valid <= 1'b0;
    end else if (w_sck_edge && r_transmision_count == WIDTH-1) begin
      o_rx_data_valid <= 1'b1;
    end
  end

  assign o_tx_data_hold = (~CPHA & r_ss_n_sync[2] & ~r_ss_n_sync[1]) | (r_transmision_count == 0 & w_sck_edge_op);

  always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
      r_miso_data <= 'h0;
    end else if (o_tx_data_hold) begin
      r_miso_data <= i_tx_data;
    end else if (w_sck_edge_op) begin
      if (LSB) begin
        r_miso_data <= r_miso_data >> 1;
      end else begin
        r_miso_data <= r_miso_data << 1;
      end
    end
  end

  assign o_miso    = (LSB) ? r_miso_data[0] : r_miso_data[WIDTH-1];
  assign o_miso_oe = ~r_ss_n_sync[2];

endmodule