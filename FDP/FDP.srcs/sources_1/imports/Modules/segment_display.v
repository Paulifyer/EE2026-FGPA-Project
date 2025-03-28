module segment_display(
    input wire clk,
    input wire [7:0] chars [3:0], // Array of 4 characters to display
    output reg [7:0] seg,
    output reg [3:0] an
);
    reg [1:0] digit_counter = 0;

    always @(posedge clk) begin
        digit_counter <= digit_counter + 1;
        case (digit_counter)
            2'b11: begin
                seg <= chars[0];
                an <= 4'b0111;
            end
            2'b10: begin
                seg <= chars[1];
                an <= 4'b1011;
            end
            2'b01: begin
                seg <= chars[2];
                an <= 4'b1101;
            end
            2'b00: begin
                seg <= chars[3];
                an <= 4'b1110;
            end
        endcase
    end
endmodule