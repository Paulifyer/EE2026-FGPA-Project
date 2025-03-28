`timescale 1ns / 1ps

module Score_Display(
    input clk,
    input [15:0] score,
    output [7:0] seg,
    output [3:0] an
    );

    import segment::*;

    reg [1:0] digit_counter = 0;
    reg [7:0] chars [3:0];
    reg [3:0] bcd_chars [3:0];

    segment_display s1 (
        .clk(clk),
        .chars(chars),
        .seg(seg),
        .an(an)
    );

    BcdConverter bcd (
        .score(score),
        .digit0(bcd_chars[3]),
        .digit1(bcd_chars[2]),
        .digit2(bcd_chars[1]),
        .digit3(bcd_chars[0])
    );

    always @(posedge clk) begin
        digit_counter <= digit_counter + 1;
        case (digit_counter)
            2'b00: begin
                chars[0] <= get_segment(bcd_chars[0]);
            end
            2'b01: begin
                chars[1] <= get_segment(bcd_chars[1]);
            end
            2'b10: begin
                chars[2] <= get_segment(bcd_chars[2]);
            end
            2'b11: begin
                chars[3] <= get_segment(bcd_chars[3]);
            end
        endcase
    end

    function [7:0] get_segment([3:0] num);
        case (num)
            4'b0000: return SEG_0;
            4'b0001: return SEG_1;
            4'b0010: return SEG_2;
            4'b0011: return SEG_3;
            4'b0100: return SEG_4;
            4'b0101: return SEG_5;
            4'b0110: return SEG_6;
            4'b0111: return SEG_7;
            4'b1000: return SEG_8;
            4'b1001: return SEG_9;
            4'b1010: return SEG_CHAR_A;
            4'b1011: return SEG_CHAR_B;
            4'b1100: return SEG_CHAR_C;
            4'b1101: return SEG_CHAR_D;
            4'b1110: return SEG_CHAR_E;
            4'b1111: return SEG_CHAR_F;
            default: return SEG_EMPTY;
        endcase
    endfunction
endmodule
