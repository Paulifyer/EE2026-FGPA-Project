`timescale 1ns / 1ps

module clock_generator_freq #(
    parameter FREQ_HZ = 1_000_000    // Default 1MHz output frequency
)(
    input wire clk_in,      // Input clock
    output reg clk_out      // Output clock
);

    // Calculate the divisor based on the input and output frequencies
    // Division by 2 because we toggle the output clock (each toggle is half a period)
    localparam DIVISOR = 100_000_000 / (2 * FREQ_HZ);
    
    
    // Internal counter
    reg [31:0] counter;
    initial begin
        counter = 0;
        clk_out = 0;
    end
    
    // Clock division logic
    always @(posedge clk_in) begin
        counter <= (counter >= (DIVISOR - 1)) ? 0 : counter + 1;
        clk_out <= (counter == (DIVISOR - 1)) ? ~clk_out : clk_out;
        end
endmodule
