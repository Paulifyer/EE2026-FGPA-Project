`timescale 1ns / 1ps

module Top_Student_tb;

  // Inputs
  reg clk;
  reg btnC;
  reg btnU;
  reg btnL;
  reg btnR;
  reg btnD;
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
    .btnU(btnU),
    .btnL(btnL),
    .btnR(btnR),
    .btnD(btnD),
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
    btnU = 0;
    btnL = 0;
    btnR = 0;
    btnD = 0;
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
        #10 btnU = 1;
        #10 btnU = 0;
        #10 btnL = 1;
        #10 btnL = 0;
        #10 btnR = 1;
        #10 btnR = 0;
        #10 btnD = 1;
        #10 btnD = 0;
  end

  always #5 clk = ~clk; // Generate clock signal

endmodule