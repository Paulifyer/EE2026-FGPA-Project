module ScoreDisplay #(
    parameter SCORE_VOFFSET = 20,  // Vertical offset
    parameter SCORE_HOFFSET = 20   // Horizontal offset
) (
    input clk,
    input [9:0] x_in,
    input [9:0] y_in,
    input [3:0] s0,
    input [3:0] s1,
    input [3:0] s2,
    input [3:0] s3,
    input is_high_score,  // Input to indicate high score
    output reg in_score_region,
    output reg [11:0] pixel_color  // Output color directly
);

  parameter CHAR_WIDTH = 8;  // ASCII character width
  parameter CHAR_HEIGHT = 16;  // ASCII character height
  parameter SCORE_SCALE_2N = 1;  // Scale factor as 2^n for better visibility
  parameter SCORE_NUM_DIGITS = 4;  // Number of score digits
  parameter PREFIX_LENGTH    = 6;  // Length of prefix "SCORE:"
  parameter TOTAL_CHARS      = PREFIX_LENGTH + SCORE_NUM_DIGITS;
  parameter SCREEN_WIDTH = 640;  // Total screen width
  parameter SCREEN_HEIGHT = 480;  // Total screen height
  parameter SCORE_REGION_WIDTH = TOTAL_CHARS * CHAR_STRIDE;
  
  // Color constants for high score indication
  parameter [11:0] COLOR_WHITE = 12'hFFF;
  parameter [11:0] COLOR_GOLD = 12'hFD0;   // Gold/yellow for high score
  parameter [11:0] COLOR_BLACK = 12'h000;  // Black/transparent
  
  // High score effects
  reg [3:0] highlight_counter = 0;
  reg [23:0] effect_timer = 0;
  parameter EFFECT_SPEED = 24'd10000000;  // Controls speed of the highlight effect
  
  // Pre-calculate constants for efficiency
  localparam EFFECTIVE_CHAR_WIDTH = CHAR_WIDTH << SCORE_SCALE_2N;
  localparam EFFECTIVE_CHAR_HEIGHT = CHAR_HEIGHT << SCORE_SCALE_2N;
  localparam CHAR_STRIDE = EFFECTIVE_CHAR_WIDTH;
  localparam SHIFT = $clog2(CHAR_STRIDE);

  // Registers for internal processing
  reg [9:0] x_pos, y_pos;
  reg [ 3:0] char_value;
  reg [ 3:0] char_row;
  reg [ 2:0] bit_pos;
  reg [ 6:0] char_code;
  reg [10:0] rom_addr;
  reg in_region, in_char_area;
  reg [3:0] digit_index;

  // ASCII ROM signals
  wire [7:0] rom_data;

  // Add pipeline registers
  reg stage1_in_region;
  reg [9:0] x_pos_stage1, y_pos_stage1;
  reg  [ 3:0] digit_index_stage1;
  reg  [ 9:0] rem_x_stage1;

  reg  [ 3:0] char_value_stage2;
  reg  [ 6:0] char_code_stage2;
  reg  [ 3:0] char_row_stage2;
  reg  [ 2:0] bit_pos_stage2;
  reg         in_char_area_stage2;
  reg  [10:0] rom_addr_stage2;

  // High score visual effect - moving highlight across digits
  always @(posedge clk) begin
    if (is_high_score) begin
      if (effect_timer >= EFFECT_SPEED) begin
        effect_timer <= 0;
        if (highlight_counter >= TOTAL_CHARS - 1)
          highlight_counter <= 0;
        else
          highlight_counter <= highlight_counter + 1;
      end else begin
        effect_timer <= effect_timer + 1;
      end
    end else begin
      highlight_counter <= 0;
      effect_timer <= 0;
    end
  end

  // Instantiate ASCII ROM
  ascii_rom rom (
      .clk (clk),
      .addr(rom_addr_stage2),
      .data(rom_data)
  );

  // Stage 1: Region detection and coordinate calculation
  always @(posedge clk) begin
    // Normal (non-animated) display
    stage1_in_region <= (x_in < SCREEN_WIDTH) && (y_in < SCREEN_HEIGHT) &&
                      (y_in >= SCORE_VOFFSET) && 
                      (y_in < SCORE_VOFFSET + EFFECTIVE_CHAR_HEIGHT) &&
                      (x_in >= SCORE_HOFFSET) && 
                      (x_in < SCORE_HOFFSET + SCORE_REGION_WIDTH);
    y_pos_stage1 <= y_in - SCORE_VOFFSET;
    
    x_pos_stage1 <= x_in - SCORE_HOFFSET;
    digit_index_stage1 <= (x_in - SCORE_HOFFSET) >> SHIFT;
    rem_x_stage1 <= (x_in - SCORE_HOFFSET) & (CHAR_STRIDE - 1);
    in_score_region <= stage1_in_region;
  end

  // Stage 2: Digit selection and ROM address calculation
  always @(posedge clk) begin
    if (stage1_in_region) begin
      if (digit_index_stage1 < PREFIX_LENGTH) begin
        case (digit_index_stage1)
           4'd0: char_code_stage2 <= 7'h53; // 'S'
           4'd1: char_code_stage2 <= 7'h43; // 'C'
           4'd2: char_code_stage2 <= 7'h4F; // 'O'
           4'd3: char_code_stage2 <= 7'h52; // 'R'
           4'd4: char_code_stage2 <= 7'h45; // 'E'
           4'd5: char_code_stage2 <= 7'h3A; // ':'
           default: char_code_stage2 <= 0;
        endcase
      end else begin
        // Use current score values
        case (digit_index_stage1 - PREFIX_LENGTH)
           4'd0: char_value_stage2 <= s3;
           4'd1: char_value_stage2 <= s2;
           4'd2: char_value_stage2 <= s1;
           4'd3: char_value_stage2 <= s0;
           default: char_value_stage2 <= 0;
        endcase
        char_code_stage2 <= 7'h30 + char_value_stage2;
      end
      char_row_stage2 <= (y_pos_stage1 >> SCORE_SCALE_2N) & (CHAR_HEIGHT - 1);
      bit_pos_stage2  <= (rem_x_stage1 - 1) >> SCORE_SCALE_2N;
      in_char_area_stage2 <= (rem_x_stage1 < EFFECTIVE_CHAR_WIDTH);
      rom_addr_stage2 <= {char_code_stage2, char_row_stage2};
    end
  end

  // Stage 3: Generate pixel output based on ROM data with color
  always @(posedge clk) begin
    if (stage1_in_region && in_char_area_stage2 && (bit_pos_stage2 < CHAR_WIDTH) && rom_data[7-bit_pos_stage2]) begin
      if (is_high_score) begin
        // For high score, determine if this digit should be highlighted
        if (digit_index_stage1 == highlight_counter)
          pixel_color <= COLOR_GOLD;  // Highlight current digit
        else
          pixel_color <= COLOR_WHITE; // Normal color for other digits
      end else
        pixel_color <= COLOR_WHITE;   // White for normal score
    end else
      pixel_color <= COLOR_BLACK;     // Black/transparent
  end
endmodule
