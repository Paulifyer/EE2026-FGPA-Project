`timescale 1ns / 1ps

module Score_Tracker(
    input clk_1s,
    input en,
    output reg [15:0] score
    );

    initial begin
        score <= 0;
    end
    
    always @(posedge clk_1s)
    begin
        if(en) begin
            score <= score + 1;
        end
    end

endmodule
