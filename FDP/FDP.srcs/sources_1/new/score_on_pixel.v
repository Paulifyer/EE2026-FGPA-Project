module ScoreOnPixel #(
    parameter SCORE_VOFFSET    = 20,   // Vertical offset
    parameter SCORE_HOFFSET    = 20,   // Horizontal offset
    parameter CHAR_GAP         = 2,    // Gap between characters
    parameter CHAR_WIDTH       = 8,    // ASCII character width
    parameter CHAR_HEIGHT      = 16,   // ASCII character height
    parameter SCORE_SCALE_2N   = 1,    // Scale factor as 2^n for better visibility
    parameter SCORE_NUM_DIGITS = 4,    // Number of digits to display
    parameter SCREEN_WIDTH     = 640,  // Total screen width
    parameter SCREEN_HEIGHT    = 480   // Total screen height
) (
    input clk,
    input [9:0] x_in,
    input [9:0] y_in,
    input [3:0] s0,
    input [3:0] s1,
    input [3:0] s2,
    input [3:0] s3,
    output reg in_score_region,
    output reg pixel_on
);

  parameter CHAR_WIDTH = 8;  // ASCII character width
  parameter CHAR_HEIGHT = 16;  // ASCII character height
  parameter SCORE_SCALE_2N = 1;  // Scale factor as 2^n for better visibility (scale = 2)
  parameter SCORE_NUM_DIGITS = 4;  // Number of digits to display
  parameter SCREEN_WIDTH = 640;  // Total screen width
  parameter SCREEN_HEIGHT = 480;  // Total screen height

  // Pre-calculate constants for efficiency
  localparam EFFECTIVE_CHAR_WIDTH = CHAR_WIDTH << SCORE_SCALE_2N;
  localparam EFFECTIVE_CHAR_HEIGHT = CHAR_HEIGHT << SCORE_SCALE_2N;
  localparam CHAR_STRIDE = EFFECTIVE_CHAR_WIDTH + CHAR_GAP;
  localparam SCORE_REGION_WIDTH = SCORE_NUM_DIGITS * CHAR_STRIDE - CHAR_GAP;
  
  // Registers for internal processing
  reg [9:0] x_pos, y_pos;
  reg [3:0] char_value;
  reg [3:0] char_row;
  reg [2:0] bit_pos;
  reg [6:0] char_code;
  reg [10:0] rom_addr;
  reg in_region, in_char_area;
  reg [1:0] digit_index;
  
  // ASCII ROM signals
  wire [7:0] rom_data;
  
  // Add pipeline registers
  reg stage1_in_region;
  reg [9:0] x_pos_stage1, y_pos_stage1;
  reg [1:0] digit_index_stage1;
  reg [9:0] rem_x_stage1;

  reg [ 3:0] char_value_stage2;
  reg [ 6:0] char_code_stage2;
  reg [ 3:0] char_row_stage2;  // Row within the original 8x16 character
  reg [ 2:0] bit_pos_stage2;  // Column within the original 8x16 character
  reg        in_char_area_stage2;  // Is the pixel within the width of a (scaled) character?
  reg [10:0] rom_addr_stage2;
  reg [ 9:0] x_temp;  // Temporary variable for x relative position
  // Stage 1: Region detection and coordinate calculation (Optimized)
  always @(posedge clk) begin
      stage1_in_region  <= (x_in < SCREEN_WIDTH) && (y_in < SCREEN_HEIGHT) &&
                           (y_in >= SCORE_VOFFSET) && 
                           (y_in < SCORE_VOFFSET + EFFECTIVE_CHAR_HEIGHT) &&
                           (x_in >= SCORE_HOFFSET) && 
                           (x_in < SCORE_HOFFSET + SCORE_REGION_WIDTH);
      x_pos_stage1      <= x_in - SCORE_HOFFSET;
      y_pos_stage1      <= y_in - SCORE_VOFFSET;
      digit_index_stage1<= (x_in - SCORE_HOFFSET) / CHAR_STRIDE;
      rem_x_stage1      <= (x_in - SCORE_HOFFSET) % CHAR_STRIDE;
      // Output region status (one cycle latency)
      in_score_region   <= stage1_in_region;
  end

  // Stage 2: Digit selection and ROM address calculation (Optimized Modulo)
  always @(posedge clk) begin
      if (stage1_in_region) begin
          case(digit_index_stage1)
              2'd0: char_value_stage2 <= s3;
              2'd1: char_value_stage2 <= s2;
              2'd2: char_value_stage2 <= s1;
              2'd3: char_value_stage2 <= s0;
              default: char_value_stage2 <= 0;
          endcase
          char_code_stage2   <= 7'h30 + char_value_stage2;
          char_row_stage2    <= (y_pos_stage1 >> SCORE_SCALE_2N) % CHAR_HEIGHT;
          bit_pos_stage2     <= rem_x_stage1 >> SCORE_SCALE_2N;
          in_char_area_stage2<= (rem_x_stage1 < EFFECTIVE_CHAR_WIDTH);
          rom_addr_stage2    <= {char_code_stage2, char_row_stage2};
      end
  end

  // Instantiate ASCII ROM
  wire [7:0] rom_data;
  ascii_rom rom (
      .clk(clk),
      .addr(rom_addr_stage2),
      .data(rom_data)
  );

  // Stage 3: Generate pixel output based on ROM data
  always @(posedge clk) begin
      if (stage1_in_region && in_char_area_stage2 && (bit_pos_stage2 < CHAR_WIDTH))
          pixel_on <= rom_data[7 - bit_pos_stage2];
      else
          pixel_on <= 0;
  end
endmodule
