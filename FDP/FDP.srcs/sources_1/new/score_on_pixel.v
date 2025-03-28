module ScoreOnPixel (
    input clk,
    input [9:0] x_in,
    input [9:0] y_in,
    input [3:0] s0,
    input [3:0] s1,
    input [3:0] s2,
    input [3:0] s3,
    output in_score_region,
    output reg pixel_on
);
  // Score display parameters
  parameter SCORE_VOFFSET = 0;
  parameter SCORE_SCALE = 1;       // Scale factor for ASCII characters
  parameter SCORE_NUM_DIGITS = 4;
  parameter SCORE_HOFFSET = 2; 
  
  // ASCII character dimensions (standard 8x16 font)
  parameter CHAR_WIDTH = 8;
  parameter CHAR_HEIGHT = 16;
  
  localparam EFFECTIVE_CHAR_WIDTH = CHAR_WIDTH * SCORE_SCALE;
  localparam EFFECTIVE_CHAR_HEIGHT = CHAR_HEIGHT * SCORE_SCALE;
  localparam CHAR_GAP = 2;         // Gap between characters

  // Variables for digit calculation
  wire [1:0] digit_index;
  reg [3:0] digit_val;
  
  // ASCII ROM signals
  wire [10:0] rom_addr;
  wire [7:0] rom_data;
  reg [6:0] char_code;
  wire [3:0] char_row;
  wire [2:0] bit_addr;
  wire ascii_bit;
  wire in_char_area;
  
  // Instantiate ASCII ROM
  ascii_rom rom (
    .clk(clk),
    .addr(rom_addr),
    .data(rom_data)
  );
  
  // Region and position calculations
  assign in_score_region = (y_in >= SCORE_VOFFSET) && 
                          (y_in < SCORE_VOFFSET + EFFECTIVE_CHAR_HEIGHT) &&
                          (x_in >= SCORE_HOFFSET) && 
                          (x_in < SCORE_HOFFSET + SCORE_NUM_DIGITS * (EFFECTIVE_CHAR_WIDTH + CHAR_GAP));
                          
  assign digit_index = (x_in - SCORE_HOFFSET) / (EFFECTIVE_CHAR_WIDTH + CHAR_GAP);
  assign char_row = (y_in - SCORE_VOFFSET) / SCORE_SCALE;
  assign bit_addr = ((x_in - SCORE_HOFFSET) % (EFFECTIVE_CHAR_WIDTH + CHAR_GAP)) / SCORE_SCALE;
  assign in_char_area = ((x_in - SCORE_HOFFSET) % (EFFECTIVE_CHAR_WIDTH + CHAR_GAP)) < EFFECTIVE_CHAR_WIDTH;
  
  // ASCII ROM interface
  assign rom_addr = {char_code, char_row};     // ROM address = ASCII code + row
  assign ascii_bit = rom_data[~bit_addr];      // Reverse bit order for proper display
  
  // Select digit value based on index
  always @* begin
    case (digit_index)
      0: digit_val = s3;
      1: digit_val = s2;
      2: digit_val = s1;
      3: digit_val = s0;
      default: digit_val = 0;
    endcase
    
    // Convert digit value to ASCII code (ASCII '0' is 48 or 8'h30)
    if (in_score_region)
      char_code = 7'h30 + digit_val;
    else
      char_code = 7'h20; // Space character
  end

  // Output pixel value - registered
  always @(posedge clk) begin
    if (in_score_region && in_char_area)
      pixel_on <= ascii_bit;
    else
      pixel_on <= 1'b0;
  end
endmodule