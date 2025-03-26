`timescale 1ns / 1ps

module clock_generator_period #(
    parameter PERIOD_NS = 1000       // Default 1000ns (1us) period
)(
    input wire clk_in,      // Input clock
    output reg clk_out      // Output clock
);

    // Calculate divisor based on period
    localparam DIVISOR = PERIOD_NS /10 /2;
   
    // Internal counter
    reg [31:0] counter;
    initial begin 
        counter <= 0;
        clk_out <= 0;
    end
    
    // Clock division logic
    always @(posedge clk_in) begin
        counter <= (counter >= DIVISOR) ? 0 : counter + 1;
        clk_out <= (counter == DIVISOR) ? ~clk_out : clk_out;
    end
    
endmodule