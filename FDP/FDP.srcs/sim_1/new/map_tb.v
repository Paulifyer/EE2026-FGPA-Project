`timescale 1ns / 1ps

module test_Map;

  // Inputs
  reg clk;
  reg keyDOWN, keyUP, keyLEFT, keyRIGHT, keyBOMB;
  reg [3:0] state;
  reg [1:0] sel;
  reg JAin;
  reg [12:0] pixel_index;
  reg [95:0] wall_tiles;
  reg [95:0] breakable_tiles;
  reg [95:0] powerup_tiles;

  // Outputs
  wire JAout;
  wire [3:0] bombs;
  wire [3:0] health;
  wire [15:0] pixel_data;

  // Instantiate the Unit Under Test (UUT)
  Map uut (
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
    .breakable_tiles(breakable_tiles),
    .powerup_tiles(powerup_tiles),
    .JAout(JAout),
    .bombs(bombs),
    .health(health),
    .pixel_data(pixel_data)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns clock period
  end

  // Test sequence
  initial begin
    // Initialize inputs
    keyDOWN = 0; keyUP = 0; keyLEFT = 0; keyRIGHT = 0; keyBOMB = 0;
    state = 0; sel = 0; JAin = 0; pixel_index = 0;
    wall_tiles = 0; breakable_tiles = 0; powerup_tiles = 0;

    // Test pressing keyBOMB before enabling the module
    #10 keyBOMB = 1; #10 keyBOMB = 0;  // Simulate button press
    #20;

    // Enable the module
    state = 4'b0010;  // Set state to enable 
    keyBOMB =1;
    #100;

    // Test pressing keyBOMB after enabling the module
    #10 keyBOMB = 1; #10000 keyBOMB = 0;  // Simulate button press
    #20;

    // Test pressing keyBOMB again after enabling
    #10 keyBOMB = 1; #10 keyBOMB = 0;  // Simulate button press
    #20;

    // Test pressing keyBOMB after disabling the module
    #10 keyBOMB = 1; #10 keyBOMB = 0;  // Simulate button press
    #20;
  end

endmodule