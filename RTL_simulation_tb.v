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
		
		// Simulating clock with frequncy ~2.048MHz
		// Orignal frequncy = 1GHz; Hence 1GHz/488 = 2.049MHz
		always 
		begin
			#244 clk = ~clk;     
		end
		
		integer bit_idx;
		reg [0:39] multi_peak_sine_pdm;
		
		initial 
			begin
			multi_peak_sine_pdm[0:7]   = 8'b10101010; 
			multi_peak_sine_pdm[8:15]  = 8'b1111_1101; 
			multi_peak_sine_pdm[16:23]  = 8'b1100_1000; 
			multi_peak_sine_pdm[24:31]  = 8'b00001000; 
			multi_peak_sine_pdm[32:39]  = 8'b10101100; 
		
		
		// System Initialization
			clk = 1'b0;
			rst = 1'b1;
			PDM = 1'b0;

		// Hold reset 
			#1000;
			@ (posedge clk)
			rst = 1'b0;

		$display("START SIMULATION");
		
		for (bit_idx = 0; bit_idx < 40; bit_idx = bit_idx + 1) begin
				@(negedge clk);
				PDM = multi_peak_sine_pdm[bit_idx];
				
				// log first sample after 8 cycles
				// thereafter log sample afterevery 8 cycles
				if (((bit_idx + 1) % 8) == 0) begin
					@(posedge clk);   // let integrators + comb fire
					#5;
					$display("Time: %0t ns | Sample Index: %0d | PCM Decimal Array Value: %d", $time, bit_idx, $signed(PCM));
				end
			end

			$display("SIMULATION COMPLETE");
			$finish;
		end

	endmodule