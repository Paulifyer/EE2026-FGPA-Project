`timescale 1ns / 1ps

module ascii_rom (
    input clk,
    input [10:0] addr,
    output reg [7:0] data
);
    // Simplified ASCII ROM implementation for testing
    // This will generate simple patterns based on character codes
    
    reg [7:0] ascii_patterns [0:127][0:15];
    
    // Extract character code and row from address
    wire [6:0] char_code;
    wire [3:0] char_row;
    
    assign char_code = addr[10:4];
    assign char_row = addr[3:0];
    
    initial begin
        // Initialize with simple patterns for testing
        
        // Pattern for digit '0' (0x30)
        ascii_patterns[7'h30][0] = 8'b00111100;
        ascii_patterns[7'h30][1] = 8'b01100110;
        ascii_patterns[7'h30][2] = 8'b01100110;
        ascii_patterns[7'h30][3] = 8'b01100110;
        ascii_patterns[7'h30][4] = 8'b01100110;
        ascii_patterns[7'h30][5] = 8'b01100110;
        ascii_patterns[7'h30][6] = 8'b01100110;
        ascii_patterns[7'h30][7] = 8'b00111100;
        ascii_patterns[7'h30][8:15] = {8{8'h00}};
        
        // Pattern for digit '1' (0x31)
        ascii_patterns[7'h31][0] = 8'b00011000;
        ascii_patterns[7'h31][1] = 8'b00111000;
        ascii_patterns[7'h31][2] = 8'b01111000;
        ascii_patterns[7'h31][3] = 8'b00011000;
        ascii_patterns[7'h31][4] = 8'b00011000;
        ascii_patterns[7'h31][5] = 8'b00011000;
        ascii_patterns[7'h31][6] = 8'b00011000;
        ascii_patterns[7'h31][7] = 8'b01111110;
        ascii_patterns[7'h31][8:15] = {8{8'h00}};
        
        // Pattern for digit '3' (0x33)
        ascii_patterns[7'h33][0] = 8'b01111100;
        ascii_patterns[7'h33][1] = 8'b00000110;
        ascii_patterns[7'h33][2] = 8'b00000110;
        ascii_patterns[7'h33][3] = 8'b01111100;
        ascii_patterns[7'h33][4] = 8'b00000110;
        ascii_patterns[7'h33][5] = 8'b00000110;
        ascii_patterns[7'h33][6] = 8'b00000110;
        ascii_patterns[7'h33][7] = 8'b01111100;
        ascii_patterns[7'h33][8:15] = {8{8'h00}};
        
        // Pattern for digit '5' (0x35)
        ascii_patterns[7'h35][0] = 8'b01111110;
        ascii_patterns[7'h35][1] = 8'b01100000;
        ascii_patterns[7'h35][2] = 8'b01100000;
        ascii_patterns[7'h35][3] = 8'b01111100;
        ascii_patterns[7'h35][4] = 8'b00000110;
        ascii_patterns[7'h35][5] = 8'b00000110;
        ascii_patterns[7'h35][6] = 8'b01100110;
        ascii_patterns[7'h35][7] = 8'b00111100;
        ascii_patterns[7'h35][8:15] = {8{8'h00}};
        
        // Pattern for digit '7' (0x37)
        ascii_patterns[7'h37][0] = 8'b01111110;
        ascii_patterns[7'h37][1] = 8'b00000110;
        ascii_patterns[7'h37][2] = 8'b00000110;
        ascii_patterns[7'h37][3] = 8'b00001100;
        ascii_patterns[7'h37][4] = 8'b00011000;
        ascii_patterns[7'h37][5] = 8'b00110000;
        ascii_patterns[7'h37][6] = 8'b00110000;
        ascii_patterns[7'h37][7] = 8'b00110000;
        ascii_patterns[7'h37][8:15] = {8{8'h00}};
        
        // Add more digit patterns (6, 8, 9) for complete testing
        // Pattern for digit '6' (0x36)
        ascii_patterns[7'h36][0] = 8'b00111100;
        ascii_patterns[7'h36][1] = 8'b01100000;
        ascii_patterns[7'h36][2] = 8'b01100000;
        ascii_patterns[7'h36][3] = 8'b01111100;
        ascii_patterns[7'h36][4] = 8'b01100110;
        ascii_patterns[7'h36][5] = 8'b01100110;
        ascii_patterns[7'h36][6] = 8'b01100110;
        ascii_patterns[7'h36][7] = 8'b00111100;
        ascii_patterns[7'h36][8:15] = {8{8'h00}};
        
        // Pattern for digit '8' (0x38)
        ascii_patterns[7'h38][0] = 8'b00111100;
        ascii_patterns[7'h38][1] = 8'b01100110;
        ascii_patterns[7'h38][2] = 8'b01100110;
        ascii_patterns[7'h38][3] = 8'b00111100;
        ascii_patterns[7'h38][4] = 8'b01100110;
        ascii_patterns[7'h38][5] = 8'b01100110;
        ascii_patterns[7'h38][6] = 8'b01100110;
        ascii_patterns[7'h38][7] = 8'b00111100;
        ascii_patterns[7'h38][8:15] = {8{8'h00}};
        
        // Pattern for digit '9' (0x39)
        ascii_patterns[7'h39][0] = 8'b00111100;
        ascii_patterns[7'h39][1] = 8'b01100110;
        ascii_patterns[7'h39][2] = 8'b01100110;
        ascii_patterns[7'h39][3] = 8'b00111110;
        ascii_patterns[7'h39][4] = 8'b00000110;
        ascii_patterns[7'h39][5] = 8'b00000110;
        ascii_patterns[7'h39][6] = 8'b00001100;
        ascii_patterns[7'h39][7] = 8'b01111000;
        ascii_patterns[7'h39][8:15] = {8{8'h00}};
    end
    
    always @(posedge clk) begin
        data <= ascii_patterns[char_code][char_row];
    end
endmodule
