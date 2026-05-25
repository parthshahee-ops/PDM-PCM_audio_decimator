`timescale 1ns/1ns

module PDMtoPCM (
    input  wire PDM, clk, rst,
    output reg  [15:0] PCM
);
	// STAGE-1: Integrator 
    reg  [18:0] A1, A2, A3;
    wire [18:0] A1_next = A1 + PDM; 
    wire [18:0] A2_next = A2 + A1_next; 
    wire [18:0] A3_next = A3 + A2_next; 

    always @(posedge clk or posedge rst) begin 
        if (rst) begin
            A1 <= 19'b0; 
            A2 <= 19'b0; 
            A3 <= 19'b0; 
        end else begin
            A1 <= A1_next; 
            A2 <= A2_next; 
            A3 <= A3_next; 
        end
    end

    // STAGE-2: Decimator/Sampling at every 64th cycle
    reg [3:0] count;
    wire wait_ack = (count == 7'd7); 

    always @(negedge clk or posedge rst) begin 
        if (rst) 
            count <= 3'd0; 
        else     
			count <= wait_ack ? 3'd0 : count + 1'b1; 
    end
    
    // STAGE-3: Differentiator
    reg [18:0] C1_z1, C2_z2, C3_z3;
    
    wire [18:0] C1_wire = A3_next - C1_z1;
    wire [18:0] C2_wire = C1_wire - C2_z2;
    wire [18:0] C3_wire = C2_wire - C3_z3;

    always @(posedge clk or posedge rst) begin 
        if (rst) begin
            C1_z1 <= 19'b0; 
            C2_z2 <= 19'b0; 
            C3_z3 <= 19'b0; 
            PCM   <= 16'b0; 
        end else if (wait_ack) begin 
			C1_z1 <= A3_next; 
            C2_z2 <= C1_wire;
            C3_z3 <= C2_wire;
            
            PCM   <= C3_wire[18:3]; 
        end
    end
endmodule