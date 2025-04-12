`timescale 1ns / 1ps

module Top_Student_tb;

  // Inputs
  reg clk;
  reg btnC;
  reg keyUP;
  reg keyLEFT;
  reg keyRIGHT;
  reg keyDOWN;
  reg [15:0] sw;

  // Outputs
  wire [7:0] JB;
  wire [11:0] rgb;
  wire hsync;
  wire vsync;

  // Instantiate the Unit Under Test (UUT)
  Top_Student uut (
    .clk(clk),
    .btnC(btnC),
    .keyUP(keyUP),
    .keyLEFT(keyLEFT),
    .keyRIGHT(keyRIGHT),
    .keyDOWN(keyDOWN),
    .sw(sw),
    .JB(JB),
    .rgb(rgb),
    .hsync(hsync),
    .vsync(vsync)
  );

  initial begin
    // Initialize Inputs
    clk = 0;
    btnC = 0;
    keyUP = 0;
    keyLEFT = 0;
    keyRIGHT = 0;
    keyDOWN = 0;
    sw = 0;

    // Wait for global reset
    #100;

    

    // Test Task_4D
    sw = 16'hAAAA;
    #100;

    // Test Task_4E2
    sw = 16'h5555;
    #100;
    // Add stimulus here
        sw  = (1 << 15) | (1 << 8) | (1 << 7) | (1 << 5) | (1 << 3) | (1 << 1) | (1 << 0); // Example switch setting
        #10 btnC = 1;
        #10 btnC = 0;
        #10 keyUP = 1;
        #10 keyUP = 0;
        #10 keyLEFT = 1;
        #10 keyLEFT = 0;
        #10 keyRIGHT = 1;
        #10 keyRIGHT = 0;
        #10 keyDOWN = 1;
        #10 keyDOWN = 0;
  end

  always #5 clk = ~clk; // Generate clock signal

endmodule