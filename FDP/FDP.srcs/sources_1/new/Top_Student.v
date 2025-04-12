`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
//
//  FILL IN THE FOLLOWING INFORMATION:
//  STUDENT A NAME: Ang Wei Bin
//  STUDENT B NAME: Ooi Wen Ree
//  STUDENT C NAME: Ethan Soh
//  STUDENT D NAME: Kwa Jian Quan
//
//////////////////////////////////////////////////////////////////////////////////

module Top_Student (
    input clk,
    btnC,
    btnU,
    btnL,
    btnR,
    btnD,
    JAin,
    input [15:0] sw,
    input PS2Data,
    input PS2Clk,
    output [7:0] JB,
    output [11:0] rgb,
    output [7:0] seg,
    output [15:0] led,
    output [3:0] an,
    output hsync,
    output vsync, JAout
);

  import Data_Item::*;

  wire clk_6p25MHz, clk_1ms, segClk;
  wire clkOneSec;
  wire [3:0] state;  //Ethan : stuff for the menu
  wire frame_begin, sending_pixels, sample_pixel;
  wire [12:0] pixel_index;
  wire [15:0] oled_data, oled_game_map, oled_data_menu, oled_data_sprite;
  wire [95:0] wall_tiles;
  wire [95:0] breakable_tiles;
  wire [95:0] powerup_tiles;

  reg  [15:0] score;
  wire is_high_score;
  reg  [ 7:0] current_key;

  //   assign led = current_key;
  assign led[11:4] = 12'h000;

  wire key_W, key_A, key_S, key_D, key_B, key_ENTER;

  // generte wall tiles 1 for wall 0 for no wall sparese
  assign breakable_tiles = 96'h000_0AA_004_6B0_012_200_094_000;
  assign wall_tiles         = 96'hFFF_945_C11_901_825_C81_829_FFF; // GAME MAP
  assign breakable_tiles    = 96'h000_0AA_004_6B0_012_200_094_000;
//  assign powerup_tiles      = 96'h000_082_0F4_420_002_278_010_000; //TESTING
  assign powerup_tiles      = 96'h000_082_004_420_002_200_010_000; // ACTUAL

  wire keyUP, keyDOWN, keyLEFT, keyRIGHT, keyBOMB, keySELECT;
  assign keyUP    = btnU | key_W;
  assign keyDOWN  = btnD | key_S;
  assign keyLEFT  = btnL | key_A;
  assign keyRIGHT = btnR | key_D;
  assign keyBOMB = btnC | key_B;
    assign keySELECT = btnC | key_ENTER;

  // CLOCK GENERATOR
  slow_clock c1 (
      clk,
      16,
      clk_6p25MHz
  );

  clock_generator_freq #(1) c3 (
      clk,
      clkOneSec
  );

  clock_generator_freq #(1000) c4 (
      clk,
      clk_1ms
  );

  keyboard k1 (
      .clk(clk),
      .PS2Data(PS2Data),
      .PS2Clk(PS2Clk),
      .pressed_key(current_key),
      .key_W(key_W),
      .key_A(key_A),
      .key_S(key_S),
      .key_D(key_D),
      .key_B(key_B),
      .key_ENTER(key_ENTER)
  );

  Score_Display s1 (
      clk_1ms,
      score,
      is_high_score,
      seg,
      an
  );

  StateManager sM (
      keySELECT,
      clk,
      state
  );

  MainMenu menu (
      pixel_index,
      clkOneSec,
      state,
      oled_data_menu
  );
  
  wire [1:0] sel;
  //THIS MENU NEEDS A WAY TO TELL THE OTHER MODULES TO CHANGE 
  //THE SPRITE OF THE PLAYER
  SpriteMenu sprMnu (
    .pixel_index(pixel_index),
    .state(state),
    .btnL(keyLEFT),
    .btnR(keyRIGHT),
    .clk(clk),
    .oled_data(oled_data_sprite),
    .sel(sel)
  );
  


  Oled_Display d1 (
      clk_6p25MHz,
      0,
      frame_begin,
      sending_pixels,
      sample_pixel,
      pixel_index,
      oled_data,
      JB[0],
      JB[1],
      JB[3],
      JB[4],
      JB[5],
      JB[6],
      JB[7]
  );

  Score_Tracker scoreTrack (
      clkOneSec,
      state,
      key_ENTER,
      score,
      is_high_score
  );

  Map map (
      .clk(clk),
      .keyDOWN(keyDOWN),
      .keyUP(keyUP),
      .keyLEFT(keyLEFT),
      .keyRIGHT(keyRIGHT),
      .keyBOMB(keyBOMB),
      .state(state),
      .sel(sel),
      .JAin(JAin),
      .pixel_index(pixel_index),
      .wall_tiles(wall_tiles),
      .JAout(JAout),
      .bombs(led[15:12]),
      .led(led[3:0]),
      .breakable_tiles(breakable_tiles),
      .powerup_tiles(powerup_tiles),
      .pixel_data(oled_game_map)
  );


  OLED_to_VGA game_to_vga (
      .clk(clk),
      .pixel_data(oled_data),
      .score(score),
      .is_high_score(is_high_score),
      .pixel_index(pixel_index),
      .bombs(led[15:12]),
      .hsync(hsync),
      .vsync(vsync),
      .rgb(rgb)
  );


  assign oled_data = (state == 0) ? oled_data_menu :
                     (state == 1) ? oled_data_sprite :
                     oled_game_map;

endmodule
