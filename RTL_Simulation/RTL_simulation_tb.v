`timescale 1ns/1ns

module PDMtoPCM_tb;
    reg clk, rst, PDM; 
    wire [15:0] PCM; 

    PDMtoPCM uut (
        .clk(clk),
        .rst(rst),
        .PDM(PDM),
        .PCM(PCM)
    ); 

    // Native 2.048 MHz Clock Synthesis
    always begin
		#244 clk = ~clk;    
    end
	
    integer bit_idx;
    reg [0:199] multi_peak_sine_pdm; 
	
    initial begin
        // Your 40-bit test pattern vector
        multi_peak_sine_pdm[0:7]   = 8'b10101010; 
        multi_peak_sine_pdm[8:15]  = 8'b1111_1101; 
        multi_peak_sine_pdm[16:23] = 8'b1100_1000; 
        multi_peak_sine_pdm[24:31] = 8'b00001000;  
        multi_peak_sine_pdm[32:39] = 8'b10101100;  
		multi_peak_sine_pdm[40:47]   = 8'b10101010; 
        multi_peak_sine_pdm[48:55]  = 8'b1111_1101; 
        multi_peak_sine_pdm[56:63] = 8'b1100_1000; 
        multi_peak_sine_pdm[64:71] = 8'b00001000;  
        multi_peak_sine_pdm[72:79] = 8'b10101100;  
		multi_peak_sine_pdm[80:87]   = 8'b10101010; 
        multi_peak_sine_pdm[88:95]  = 8'b1111_1101; 
        multi_peak_sine_pdm[96:103] = 8'b1100_1000; 
        multi_peak_sine_pdm[104:111] = 8'b00001000;  
        multi_peak_sine_pdm[112:119] = 8'b10101100;  
		multi_peak_sine_pdm[120:127]   = 8'b10101010; 
        multi_peak_sine_pdm[128:135]  = 8'b1111_1101; 
        multi_peak_sine_pdm[136:143] = 8'b1100_1000; 
        multi_peak_sine_pdm[144:151] = 8'b00001000;  
        multi_peak_sine_pdm[152:159] = 8'b10101100; 
		multi_peak_sine_pdm[160:167]   = 8'b10101010; 
        multi_peak_sine_pdm[168:175]  = 8'b1111_1101; 
        multi_peak_sine_pdm[176:183] = 8'b1100_1000; 
        multi_peak_sine_pdm[184:191] = 8'b00001000;  
        multi_peak_sine_pdm[192:199] = 8'b10101100; 
	
        // System Boot Sequence
		rst = 1'b1; #1 clk = 1'b0; #1 PDM = 1'b0; 
        #1000
		rst = 1'b0;
        $display("START SIMULATION"); 
	
        for (bit_idx = 0; bit_idx < 200; bit_idx = bit_idx + 1) begin 
            @(negedge clk); 
            PDM = multi_peak_sine_pdm[bit_idx]; 
            
            if (((bit_idx + 1) % 8) == 0) begin 
                $display("Time: %0t ns | Sample Index: %0d | PCM Decimal Array Value: %d", $time, bit_idx, $signed(PCM));
            end
        end

        $display("SIMULATION COMPLETE"); 
        $finish; 
    end
endmodule