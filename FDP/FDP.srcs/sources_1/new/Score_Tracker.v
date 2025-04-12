`timescale 1ns / 1ps

module Score_Tracker(
    input clk_1s,
    input [3:0] en,
    input is_game_in_progress,
    output reg [15:0] score,
    output reg is_high_score
    );

    reg [15:0] high_score;

    initial begin
        score <= 0;
        high_score <= 30;
        is_high_score <= 0;
    end
    
    always @(posedge clk_1s)
    begin
        if (~is_game_in_progress) begin
            score <= 0;
        end
        else if (en == 2) begin
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
