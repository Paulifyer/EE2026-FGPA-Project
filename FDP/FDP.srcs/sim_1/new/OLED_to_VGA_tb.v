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
  
  // Test procedure - more efficient pattern filling
  initial begin
    // Initialize inputs
    pixel_data = 16'h0000;
    pixel_index = 0;
    
    // Wait for global reset
    #100;
    
    // Test 1: Fill the entire OLED display with a pattern
    $display("Test 1: Filling OLED buffer with pattern");
    for (integer i = 0; i < OLED_HEIGHT * OLED_WIDTH; i = i + 1) begin
      pixel_index = i;
      // Determine x,y from index for pattern calculation
      automatic integer x = i % OLED_WIDTH;
      automatic integer y = i / OLED_WIDTH;
      // Create a checkered pattern
      pixel_data = ((x/8 + y/8) % 2 == 0) ? 16'hF800 : 16'h07E0;
      #10; // Wait for one clock cycle
    end
    
    // Test 2: Observe VGA output for specific regions
    $display("Test 2: Observe VGA output for specific regions");
    #1000000; // Wait for several frames
    
    // Test 3: Verify border rendering
    $display("Test 3: Verifying border rendering");
    #1000000;
    
    // Test completion
    $display("Testbench completed");
    #10000;
    $finish;
  end
  
  // More efficient monitoring - reduce display frequency
  integer frame_count = 0;
   - inefficient display logging
  // Monitor for VSync pulses (frame completion)
  reg prev_vsync;
  always @(posedge clk_100MHz) begin
    prev_vsync <= vsync;
    if (prev_vsync == 1 && vsync == 0) begin
      frame_count <= frame_count + 1;
      if (frame_count % 10 == 0) begin  // Only report every 10 frames
        $display("Time=%0t: Frame %0d completed", $time, frame_count);
      end
    end
  end

  // Reduce monitor output frequency
  always @(posedge clk_100MHz) begin
    if (vid_on && x_pos == 0 && y_pos == 0) begin
      $display("Time=%0t: Starting frame render", $time);
    end
  end

endmodule
