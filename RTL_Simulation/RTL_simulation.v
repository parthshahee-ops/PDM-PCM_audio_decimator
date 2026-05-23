`timescale 1ns/1ns
module PDMtoPCM (
    input  wire PDM, clk, rst,
    output reg  [15:0] PCM
);

	// STAGE-1 Integrator
    reg  [18:0] A1, A2, A3;
    wire [18:0] A1_next = A1 + PDM;      						// using combinational logic, so that A2 uses upadated value of A1 in the same cycle;
    wire [18:0] A2_next = A2 + A1_next;	 						// blocking assignment can also be used inside always block
    wire [18:0] A3_next = A3 + A2_next;
	
	always @(posedge clk or posedge rst) begin
        if (rst)
		begin 
		A1 <= 1'b0; A2 <= 1'b0; A3 <= 1'b0;             		// initializing to 1'b0
		end else 
		begin 
		A1 <= A1_next; A2 <= A2_next; A3 <= A3_next; 			// on positive edge, accumulator gets updated
		end
    end

	// STAGE-2 Decimator\Clock Divider
    reg [2:0] count;
    wire wait_ack = (count == 3'd7);							// to avoid extra 1 cycle delay, initialize wait_ack as wire				

    always @(posedge clk or posedge rst) 
	begin
        if (rst) count <= 3'd0;
        else     count <= wait_ack ? 3'd0 : count + 1;
    end
    
	// STAGE-3 Differentiator
	reg [18:0] C1_z1, C2_z2, C3_z3;

    always @(posedge clk or posedge rst) 
	begin
        if (rst) 
		begin
            C1_z1<=0; C2_z2<=0; C3_z3<=0; PCM<=0;
        end else 
		if (wait_ack) 
		begin
            C1_z1 <= A3_next;
            C2_z2 <= A3_next - C1_z1;
            C3_z3 <= (A3_next - C1_z1) - C2_z2;
            
			PCM   <= ((A3_next - C1_z1 - C2_z2 - C3_z3)) >> 3;	// truncating 3 LSB bits	
        end
    end
endmodule