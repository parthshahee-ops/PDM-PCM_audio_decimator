`timescale 1ns/1ns

(* top *) 
module top ( 
    (* iopad_external_pin, clkbuf_inhibit *) input clk,    
    (* iopad_external_pin *) output clk_en, 
    (* iopad_external_pin *) input rst_n,                  
  
    (* iopad_external_pin *) input PDM,                    
    
    (* iopad_external_pin *) input spi_ss_n,                
    (* iopad_external_pin *) input spi_sck,                 
    (* iopad_external_pin *) input spi_mosi,                
    (* iopad_external_pin *) output spi_miso,               
    (* iopad_external_pin *) output spi_miso_en             
);

    assign clk_en = 1'b1; 

    reg  [7:0] tx_data_reg; 
    wire [7:0] rx_data_wire;   
    wire       rx_valid_pulse; 
    wire       rst = ~rst_n; 

    // STAGE 1: 3-Stage High-Speed Integrators
    reg  [18:0] A1, A2, A3;
    
    wire [18:0] A1_next = A1 + rx_data_wire; 
    wire [18:0] A2_next = A2 + A1_next;
    wire [18:0] A3_next = A3 + A2_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A1 <= 19'd0; A2 <= 19'd0; A3 <= 19'd0;
        end else begin
            A1 <= A1_next; A2 <= A2_next; A3 <= A3_next;
        end
    end

    // STAGE 2: Decimation/Sampling (R = 8 Downsampling)
    reg [2:0] count;
    wire      wait_ack = (count == 3'd7); 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 3'd0; 
        end else begin
            count <= wait_ack ? 3'd0 : count + 1'b1; 
        end
    end

    // STAGE 3: 3-Stage Differentiators & SPI Output Register
    reg [18:0] C1_z1, C2_z2, C3_z3;
    wire [18:0] C1_wire = A3_next - C1_z1;
    wire [18:0] C2_wire = C1_wire  - C2_z2;
    wire [18:0] C3_wire = C2_wire  - C3_z3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            C1_z1       <= 19'd0; C2_z2 <= 19'd0; C3_z3 <= 19'd0;
            tx_data_reg <= 8'h00;
        end else if (wait_ack) begin
            C1_z1 <= A3_next;
            C2_z2 <= C1_wire;
            C3_z3 <= C2_wire;
            
            tx_data_reg <= C3_wire[18:11];
        end
    end

    spi_target #(
        .CPOL(1'b0),   
        .CPHA(1'b0),   
        .WIDTH(8),     
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


module spi_target #(
  parameter CPOL   = 1'b0,  // When one, clock is low in idle, otherwise clock is high
  parameter CPHA   = 1'b0,  // When one, sampling occurs at falling edge, otherwise at rising edge of non-inverted clock
  parameter WIDTH  = 8,     // Determines the data width of SPI to the input and output data buses
  parameter LSB    = 1'b0   // When one, data starts from LSB, otherwise data starts from MSB 
) (
// common ports
  input                  i_clk,           // input clock signal
  input                  i_rst_n,         // input negative reset signal
// control signal
  input                  i_enable,        // input enable SPI target signal
// SPI interface ports
  input                  i_ss_n,          // input target select signal
  input                  i_sck,           // input spi clock signal
  input                  i_mosi,          // input controller output target input signal
  output                 o_miso,          // output controller input target output signal
  output                 o_miso_oe,       // output miso enable output signal
//RX internal ports
  output reg [WIDTH-1:0] o_rx_data,       // output data bus
  output reg             o_rx_data_valid, // output receive data valid signal
//TX internal ports
  input      [WIDTH-1:0] i_tx_data,       // input data bus
  output                 o_tx_data_hold   // output signal used to get tx data from i_tx_data input
);

  reg               [2:0] r_ss_n_sync, r_sck_sync;
  reg [$clog2(WIDTH-1):0] r_transmision_count;
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
        r_transmision_count <= r_transmision_count + 1;
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
