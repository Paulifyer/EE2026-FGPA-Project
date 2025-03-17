`timescale 1ns / 1ps

module OLED_to_VGA_tb;

  // Parameters from the original module
  parameter OLED_WIDTH = 96;
  parameter OLED_HEIGHT = 64;
  
  // Test bench signals
  reg clk_100MHz;
  reg [15:0] pixel_data;
  reg [12:0] pixel_index;
  wire hsync;
  wire vsync;
  wire [11:0] rgb;
  
  // For monitoring pixel location
  wire [9:0] x_pos;
  wire [9:0] y_pos;
  wire vid_on;
  
  // Instantiate the Unit Under Test (UUT)
  OLED_to_VGA uut (
    .clk_100MHz(clk_100MHz),
    .pixel_data(pixel_data),
    .pixel_index(pixel_index),
    .hsync(hsync),
    .vsync(vsync),
    .rgb(rgb)
  );
  
  // Access internal signals for monitoring
  assign x_pos = uut.x;
  assign y_pos = uut.y;
  assign vid_on = uut.video_on;
  
  // Clock generation
  initial begin
    clk_100MHz = 0;
    forever #5 clk_100MHz = ~clk_100MHz; // 100MHz clock (10ns period)
  end
  
  // Test procedure
  initial begin
    // Initialize inputs
    pixel_data = 16'h0000;
    pixel_index = 0;
    
    // Wait for global reset
    #100;
    
    // Test 1: Fill the entire OLED display with a pattern
    $display("Test 1: Filling OLED buffer with pattern");
    for (integer y = 0; y < OLED_HEIGHT; y = y + 1) begin
      for (integer x = 0; x < OLED_WIDTH; x = x + 1) begin
        pixel_index = y * OLED_WIDTH + x;
        // Create a checkered pattern
        if ((x/8 + y/8) % 2 == 0)
          pixel_data = 16'hF800; // Red 
        else
          pixel_data = 16'h07E0; // Green
        #10; // Wait for one clock cycle
      end
    end
  end
endmodule
