`timescale 1ns/1ns

module PDMtoPCM (
    input  wire        PDM,
    input  wire        clk,
    input  wire        rst,
    output reg  [15:0] PCM
);

    // STAGE 1 Integrators
    reg  [18:0] A1, A2, A3;
    wire [18:0] A1_next = A1 + PDM;
    wire [18:0] A2_next = A2 + A1_next;
    wire [18:0] A3_next = A3 + A2_next;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A1 <= 19'd0; A2 <= 19'd0; A3 <= 19'd0;
        end else begin
            A1 <= A1_next; A2 <= A2_next; A3 <= A3_next;
        end
    end

    // STAGE 2 Decimation/Sampling
    reg [2:0] count;
    reg       first_cycle;
    wire      wait_ack = (count == 3'd7);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count       <= 3'd0;
            first_cycle <= 1'b1;   // arm the one-shot hold
        end else begin
            first_cycle <= 1'b0;   // clear after first posedge
            if (!first_cycle)      // skip increment on first posedge
                count <= wait_ack ? 3'd0 : count + 1'b1;
        end
    end

    // STAGE 3 Differentiators
    reg [18:0] C1_z1, C2_z2, C3_z3;

    wire [18:0] C1_wire = A3_next - C1_z1;
    wire [18:0] C2_wire = C1_wire  - C2_z2;
    wire [18:0] C3_wire = C2_wire  - C3_z3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            C1_z1   <= 19'd0; C2_z2  <= 19'd0; C3_z3 <= 19'd0;
            PCM     <= 16'd0;
        end else if (wait_ack && !first_cycle) begin
            C1_z1   <= A3_next;
            C2_z2   <= C1_wire;
            C3_z3   <= C2_wire;
            PCM     <= C3_wire[18:3];
        end
    end


endmodule
