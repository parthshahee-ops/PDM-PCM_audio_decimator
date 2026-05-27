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
        pdm_stream[0:7]    = 8'b10101010;
        pdm_stream[8:15]   = 8'b11111101;
        pdm_stream[16:23]  = 8'b11001000;
        pdm_stream[24:31]  = 8'b00001000;
        pdm_stream[32:39]  = 8'b10101100;
        pdm_stream[40:47]  = 8'b10101010;
        pdm_stream[48:55]  = 8'b11111101;
        pdm_stream[56:63]  = 8'b11001000;
        pdm_stream[64:71]  = 8'b00001000;
        pdm_stream[72:79]  = 8'b10101100;
        pdm_stream[80:87]  = 8'b10101010;
        pdm_stream[88:95]  = 8'b11111101;
        pdm_stream[96:103] = 8'b11001000;
        pdm_stream[104:111]= 8'b00001000;
        pdm_stream[112:119]= 8'b10101100;
        pdm_stream[120:127]= 8'b10101010;
        pdm_stream[128:135]= 8'b11111101;
        pdm_stream[136:143]= 8'b11001000;
        pdm_stream[144:151]= 8'b00001000;
        pdm_stream[152:159]= 8'b10101100;
        pdm_stream[160:167]= 8'b10101010;
        pdm_stream[168:175]= 8'b11111101;
        pdm_stream[176:183]= 8'b11001000;
        pdm_stream[184:191]= 8'b00001000;
        pdm_stream[192:199]= 8'b10101100;
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
