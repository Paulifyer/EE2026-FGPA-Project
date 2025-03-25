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
    JCIn,
    input [15:0] sw,
    output [7:0] JB,
    output [15:0] led,
    output [11:0] rgb,
    output hsync,
    output vsync
);

  import Data_Item::*;

  parameter Task_4D_pw = (1 << 15) | (1 << 8) | (1 << 7) | (1 << 5) | (1 << 3) | (1 << 1) | (1 << 0);

  wire clk_6p25MHz, clk_1ms, segClk;
  wire clkOneSec; wire state; //Ethan : stuff for the menu
  wire frame_begin, sending_pixels, sample_pixel;
  wire [12:0] pixel_index;
  wire [15:0] oled_data, oled_data_D, oled_data_menu;
  wire [15:0] oled_data_E;
  wire [95:0] wall_tiles;
  
  assign oled_data_E = 16'hAAA;

  // generte wall tiles 1 for wall 0 for no wall sparese
  assign wall_tiles = 96'h000000000000F0000F000000;

  slow_clock c1 (
      clk,
      16,
      clk_6p25MHz
  );
  
  slow_clock c2 (
    clk, 
    200000000, 
    clkOneSec
  );
  
  StateManager sM (
    btnC, 
    clk, 
    state
  );
  
  MainMenu menu (
    pixel_index, 
    clkOneSec,
    state,
    oled_data_menu
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
  
  Map map (
      .clk(clk),
      .btnD(btnD),
      .btnU(btnU),
      .btnL(btnL),
      .btnR(btnR),
      .btnC(btnC),
      .en(sw == Task_4D_pw),
      .wall_tiles(wall_tiles),
      .pixel_index(pixel_index),
      .pixel_data(oled_data_D)
  );
  

  OLED_to_VGA game_to_vga (
      .clk_100MHz(clk),
      .pixel_data(oled_data),
      .pixel_index(pixel_index),
      .hsync(hsync),
      .vsync(vsync),
      .rgb(rgb)
  );


  assign oled_data = (!state) ? oled_data_menu : 
                     (sw == Task_4D_pw) ? oled_data_D :
                     oled_data_E;

endmodule
