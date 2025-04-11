`timescale 1ns / 1ps

module StateManager(
    input btnC,
    input clk,
    output reg state = 1'b0
    );
    reg lastInput = 1'b0;
       always @ (posedge clk) begin
           if ((btnC & ~lastInput) && state == 1'b0)
              state = 1'b1;
           lastInput = btnC;
       end
endmodule
