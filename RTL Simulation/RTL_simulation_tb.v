`timescale 1ns/1ns

module PDMtoPCM_tb;

    reg         clk, rst, PDM;
    wire [15:0] PCM;

    PDMtoPCM uut (
        .clk(clk), .rst(rst), .PDM(PDM),
        .PCM(PCM)
    );

    initial clk = 1'b0;
    always  #244 clk = ~clk;

    integer     bit_idx;
    reg [0:199] pdm_stream;

    initial begin
        pdm_stream[0:63]   = 64'hAAAA_AAAA_FFFF_FFFF;
        pdm_stream[64:127]  = 64'hFFFF_FFFF_AAAA_AAAA;
        pdm_stream[128:191] = 64'h0000_0000_5555_5555;
        pdm_stream[192:255] = 64'h5555_5555_0000_0000;
        rst = 1'b1; clk = 1'b0; PDM = 1'b0;
        #1000;
        rst = 1'b0;


        for (bit_idx = 0; bit_idx < 200; bit_idx = bit_idx + 1) begin
            @(negedge clk);
            PDM = pdm_stream[bit_idx];

            if (((bit_idx + 1) % 8) == 0) begin
                @(posedge clk); 
                #1;             // let non-blocking assignments settle
                $display("  W%-5d       %-7d  %0d",
                    (bit_idx+1)/8, bit_idx, $signed(PCM));
            end
        end
        $display(" SIMULATION COMPLETE");
        $finish;
    end

    initial begin #500000; $display("TIMEOUT"); $finish; end

endmodule
