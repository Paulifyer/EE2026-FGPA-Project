`timescale 1ns / 1ps

module Score_Tracker(
    input clk_1s,
    input en,
    input reset,
    output reg [15:0] score,
    output reg is_high_score
    );

    reg [15:0] high_score;

    initial begin
        score <= 0;
        high_score <= 80;
        is_high_score <= 0;
    end
    
    always @(posedge clk_1s)
    begin
        if (reset) begin
            score <= 0;
            is_high_score <= 0;
        end
        else if(en) begin
            score <= score + 1;
            
            // Update high score when current score exceeds it
            if (score + 1 > high_score) begin
                high_score <= score + 1;
                is_high_score <= 1;
            end
            else begin
                is_high_score <= 0;
            end
        end
        else begin
            is_high_score <= 0;
        end
    end

endmodule
