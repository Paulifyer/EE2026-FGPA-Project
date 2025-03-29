module ScoreOnPixel #(
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
  localparam EFFECTIVE_CHAR_WIDTH = CHAR_WIDTH << SCORE_SCALE_2N;  // 8 << 1 = 16
  localparam EFFECTIVE_CHAR_HEIGHT = CHAR_HEIGHT << SCORE_SCALE_2N;  // 16 << 1 = 32
  localparam CHAR_STRIDE = EFFECTIVE_CHAR_WIDTH;
  localparam LOG2_CHAR_STRIDE = 4;  // log2(16) = 4
  localparam CHAR_STRIDE_MASK = CHAR_STRIDE - 1;  // 16 - 1 = 15 (4'b1111)

  localparam SCORE_REGION_WIDTH = SCORE_NUM_DIGITS * CHAR_STRIDE;

  localparam LOG2_CHAR_HEIGHT = 4;  // log2(16) = 4
  localparam CHAR_HEIGHT_MASK = CHAR_HEIGHT - 1;  // 16 - 1 = 15 (4'b1111)



  // Pipeline registers
  reg        stage1_in_region;
  reg [ 9:0] x_pos_stage1;  // Relative X within the score region
  reg [ 9:0] y_pos_stage1;  // Relative Y within the score region
  reg [ 1:0] digit_index_stage1;
  reg [ 3:0] rem_x_scaled_stage1;  // Remainder X scaled down (pixel column within scaled char)

  reg [ 3:0] char_value_stage2;
  reg [ 6:0] char_code_stage2;
  reg [ 3:0] char_row_stage2;  // Row within the original 8x16 character
  reg [ 2:0] bit_pos_stage2;  // Column within the original 8x16 character
  reg        in_char_area_stage2;  // Is the pixel within the width of a (scaled) character?
  reg [10:0] rom_addr_stage2;
  reg [ 9:0] x_temp;  // Temporary variable for x relative position
  // Stage 1: Region detection and coordinate calculation (Optimized)
  always @(posedge clk) begin


    // Calculate relative coordinates first
    x_temp = x_in - SCORE_HOFFSET;
    y_pos_stage1 = y_in - SCORE_VOFFSET;  // Relative Y needed in stage 2

    // Region check (uses x_in, y_in directly for clarity)
    stage1_in_region  <= (x_in < SCREEN_WIDTH) && (y_in < SCREEN_HEIGHT) &&
                         (y_in >= SCORE_VOFFSET) &&
                         (y_in < SCORE_VOFFSET + EFFECTIVE_CHAR_HEIGHT) &&
                         (x_in >= SCORE_HOFFSET) &&
                         (x_in < SCORE_HOFFSET + SCORE_REGION_WIDTH);

    // OPTIMIZED Calculation using shifts and ANDs
    digit_index_stage1 <= x_temp >> LOG2_CHAR_STRIDE;  // Equivalent to x_temp / 16
    rem_x_scaled_stage1 <= x_temp & CHAR_STRIDE_MASK;  // Equivalent to x_temp % 16

    // Output region status (one cycle latency)
    in_score_region <= stage1_in_region;
  end

  // Stage 2: Digit selection and ROM address calculation (Optimized Modulo)
  always @(posedge clk) begin
    if (stage1_in_region) begin
      case (digit_index_stage1)  // Use the calculated digit index
        2'd0: char_value_stage2 <= s3;  // Display leftmost digit (thousands)
        2'd1: char_value_stage2 <= s2;  // Hundreds
        2'd2: char_value_stage2 <= s1;  // Tens
        2'd3: char_value_stage2 <= s0;  // Ones
        default: char_value_stage2 <= 4'b0;  // Should not happen if width/digits match
      endcase
      char_code_stage2    <= 7'h30 + char_value_stage2;  // ASCII for '0' + digit value

      // OPTIMIZED: Use shift and AND for modulo
      // Calculate row within the original 8x16 char
      char_row_stage2 <= (y_pos_stage1 >> SCORE_SCALE_2N) & CHAR_HEIGHT_MASK; // (y/scale) % 16

      // Calculate column within the original 8x16 char
      bit_pos_stage2 <= rem_x_scaled_stage1 >> SCORE_SCALE_2N; // (x%stride) / scale

      // Check if the scaled remainder X is within the scaled character width
      in_char_area_stage2 <= (rem_x_scaled_stage1 < EFFECTIVE_CHAR_WIDTH);

      // Form ROM address
      rom_addr_stage2 <= {char_code_stage2, char_row_stage2};
    end else begin
      // Default values when not in region to avoid latches (optional but good practice)
      char_value_stage2 <= 4'b0;
      char_code_stage2 <= 7'h0;
      char_row_stage2 <= 4'b0;
      bit_pos_stage2 <= 3'b0;
      in_char_area_stage2 <= 1'b0;
      rom_addr_stage2 <= 11'b0;
    end
  end

  // Instantiate ASCII ROM
  wire [7:0] rom_data;
  ascii_rom rom (
      .clk (clk),
      .addr(rom_addr_stage2),  // Use registered address
      .data(rom_data)
  );

  // Stage 3: Generate pixel output based on ROM data
  always @(posedge clk) begin
    // Use stage 2 registered values
    if (stage1_in_region && in_char_area_stage2 && (bit_pos_stage2 < CHAR_WIDTH)) begin
      // Select the correct bit from the ROM output
      // Note: bit_pos_stage2 is 0..7, rom_data is indexed [7..0]
      pixel_on <= rom_data[CHAR_WIDTH-1-bit_pos_stage2];  // e.g., rom_data[7 - bit_pos]
    end else begin
      pixel_on <= 1'b0;  // Pixel off if outside region or character area
    end
  end

endmodule
