`timescale 1ns / 1ps

module tb_spi_target;

    // Parameters 
    parameter CPOL  = 1'b0;
    parameter CPHA  = 1'b0;
    parameter WIDTH = 8;
    parameter LSB   = 1'b0;

    localparam CLK_PERIOD = 10;      // 100 MHz system clock
    localparam SCK_PERIOD = 100;     // 10 MHz SPI clock

    reg                i_clk;
    reg                i_rst_n;
    reg                i_enable;
    reg                i_ss_n;
    reg                i_sck;
    reg                i_mosi;
    wire               o_miso;
    wire               o_miso_oe;
    wire [WIDTH-1:0]   o_rx_data;
    wire               o_rx_data_valid;
    reg  [WIDTH-1:0]   i_tx_data;
    wire               o_tx_data_hold;

    spi_target #(
        .CPOL(CPOL),
        .CPHA(CPHA),
        .WIDTH(WIDTH),
        .LSB(LSB)
    ) uut (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_enable(i_enable),
        .i_ss_n(i_ss_n),
        .i_sck(i_sck),
        .i_mosi(i_mosi),
        .o_miso(o_miso),
        .o_miso_oe(o_miso_oe),
        .o_rx_data(o_rx_data),
        .o_rx_data_valid(o_rx_data_valid),
        .i_tx_data(i_tx_data),
        .o_tx_data_hold(o_tx_data_hold)
    );

    // Clock Generator 100 MHz
    always begin
        i_clk = 1'b0;
        #(CLK_PERIOD/2);
        i_clk = 1'b1;
        #(CLK_PERIOD/2);
    end

    task spi_controller_tx_rx(
        input  [WIDTH-1:0] data_to_send,
        output [WIDTH-1:0] data_received
    );
        integer i;
        reg [WIDTH-1:0] rx_shifter;
        begin
            // 1. Activate Slave Select
            i_ss_n = 1'b0;
            
            if (LSB) begin
                i_mosi = data_to_send[0];
            end else begin
                i_mosi = data_to_send[WIDTH - 1];
            end
            
            #(SCK_PERIOD/2);

            // 2. Loop through all bits
            for (i = 0; i < WIDTH; i = i + 1) begin
                
                // First half of SCK cycle: Drive clock to its active state
                if (CPOL) i_sck = 1'b0; 
                else      i_sck = 1'b1; 
                
                #(SCK_PERIOD/2);

                // Sample MISO from the Target on the active edge
                if (LSB) begin
                    rx_shifter = {o_miso, rx_shifter[WIDTH-1:1]};
                end else begin
                    rx_shifter = {rx_shifter[WIDTH-2:0], o_miso};
                end

                // Pre-drive the NEXT MOSI data bit ahead of the next cycle
                if (i < WIDTH - 1) begin
                    if (LSB) begin
                        i_mosi = data_to_send[i + 1];
                    end else begin
                        i_mosi = data_to_send[WIDTH - 1 - (i + 1)];
                    end
                end

                // Second half of SCK cycle: Return clock line to its idle state
                if (CPOL) i_sck = 1'b1; 
                else      i_sck = 1'b0; 
                
                #(SCK_PERIOD/2);
            end

            // 3. Deactivate Slave Select
            i_ss_n = 1'b1;
            data_received = rx_shifter;
            #(SCK_PERIOD);
        end
    endtask

    // Stimulus Process
    initial begin
        // Initialize Inputs
        i_rst_n   = 1'b0;
        i_enable  = 1'b0;
        i_ss_n    = 1'b1;
        i_sck     = CPOL; // IDLE clock state determined by CPOL
        i_mosi    = 1'b0;
        i_tx_data = 'h0;

        // Reset Sequence
        #(CLK_PERIOD * 5);
        i_rst_n = 1'b1;
        #(CLK_PERIOD * 2);
        i_enable = 1'b1;
        #(CLK_PERIOD * 2);

        $display("------ Starting Corrected SPI Verification ------");

        // --- Transaction 1 ---
        i_tx_data = 8'h5A; 
        $display("[Time %0t] Controller sending: 0xA5, Target preparing response: 0x5A", $time);
        
        begin : rx_block1
            reg [WIDTH-1:0] controller_rx;
            spi_controller_tx_rx(8'hA5, controller_rx);
            $display("[Time %0t] Controller received back: 0x%h", $time, controller_rx);
        end

        #(CLK_PERIOD * 10);

        // --- Transaction 2 ---
        i_tx_data = 8'hC3;
        $display("[Time %0t] Controller sending: 0x3C, Target preparing response: 0xC3", $time);
        
        begin : rx_block2
            reg [WIDTH-1:0] controller_rx;
            spi_controller_tx_rx(8'h3C, controller_rx);
            $display("[Time %0t] Controller received back: 0x%h", $time, controller_rx);
        end

        #(CLK_PERIOD * 10);
        $display("------ SPI Target Verification Finished ------");
        $finish;
    end

endmodule