`timescale 1ns / 1ps

module score_on_pixel_tb();
    // Clock and reset
    reg clk = 0;
    
    // Input coordinates
    reg [9:0] x_in;
    reg [9:0] y_in;
    
    // Score inputs (4 digits)
    reg [3:0] s0 = 4'd5;  // Right-most digit
    reg [3:0] s1 = 4'd3;
    reg [3:0] s2 = 4'd7;
    reg [3:0] s3 = 4'd1;  // Left-most digit
    
    // Output signals
    wire in_score_region;
    wire pixel_on;
    
    // Module under test
    ScoreOnPixel #(
        .SCORE_VOFFSET(0),
        .SCORE_SCALE(1),
        .SCORE_NUM_DIGITS(4),
        .SCORE_HOFFSET(2)
    ) uut (
        .clk(clk),
        .x_in(x_in),
        .y_in(y_in),
        .s0(s0),
        .s1(s1),
        .s2(s2),
        .s3(s3),
        .in_score_region(in_score_region),
        .pixel_on(pixel_on)
    );
    
    // Clock generation (100MHz)
    always #5 clk = ~clk;
    
    // ASCII display helper - to visually check character formation
    reg [7:0] display_grid[0:19][0:49];
    integer i, j;
    
    // Test procedure
    initial begin
        // Initialize display grid
        for (i = 0; i < 20; i = i + 1)
            for (j = 0; j < 50; j = j + 1)
                display_grid[i][j] = ".";
                
        // Scan the entire score region pixel by pixel
        for (y_in = 0; y_in < 20; y_in = y_in + 1) begin
            for (x_in = 0; x_in < 50; x_in = x_in + 1) begin
                // Allow time for pixel calculation
                #20;
                
                // Record the pixel state in our display grid
                if (in_score_region) begin
                    if (pixel_on)
                        display_grid[y_in][x_in] = "X";
                    else
                        display_grid[y_in][x_in] = " ";
                end
            end
        end
        
        // Print the score display to console
        $display("Score Display Visualization:");
        for (i = 0; i < 20; i = i + 1) begin
            $write("Row %2d: ", i);
            for (j = 0; j < 50; j = j + 1) begin
                $write("%s", display_grid[i][j]);
            end
            $write("\n");
        end
        
        // Test specific points to validate logic
        // Test each digit position
        
        // Test digit 3 (left-most, value 1)
        x_in = 5;  // Position in first digit
        y_in = 8;  // Middle of character height
        #20;
        if (in_score_region) 
            $display("Test 1: Position (%0d,%0d) in digit 3 shows %s (digit value: %0d)", 
                     x_in, y_in, pixel_on ? "ON" : "OFF", s3);
                     
        // Test digit 2 (value 7)
        x_in = 15;  // Position in second digit
        y_in = 8;   // Middle of character height
        #20;
        if (in_score_region)
            $display("Test 2: Position (%0d,%0d) in digit 2 shows %s (digit value: %0d)", 
                     x_in, y_in, pixel_on ? "ON" : "OFF", s2);
        
        // Test digit 1 (value 3)
        x_in = 25;  // Position in third digit
        y_in = 8;   // Middle of character height
        #20;
        if (in_score_region)
            $display("Test 3: Position (%0d,%0d) in digit 1 shows %s (digit value: %0d)", 
                     x_in, y_in, pixel_on ? "ON" : "OFF", s1);
        
        // Test digit 0 (right-most, value 5)
        x_in = 35;  // Position in fourth digit
        y_in = 8;   // Middle of character height
        #20;
        if (in_score_region)
            $display("Test 4: Position (%0d,%0d) in digit 0 shows %s (digit value: %0d)", 
                     x_in, y_in, pixel_on ? "ON" : "OFF", s0);
        
        // Test a position outside the score region
        x_in = 45;
        y_in = 8;
        #20;
        $display("Test 5: Position (%0d,%0d) is %s the score region", 
                 x_in, y_in, in_score_region ? "INSIDE" : "OUTSIDE");
        
        // Change score values and test again
        s3 = 4'd9;
        s2 = 4'd8;
        s1 = 4'd7;
        s0 = 4'd6;
        $display("Changed score to: %0d%0d%0d%0d", s3, s2, s1, s0);
        
        // Give time for display to update
        #20;
        
        // Test new score display
        x_in = 5;
        y_in = 8;
        #20;
        $display("Test 6: Position (%0d,%0d) with new score shows %s (digit value: %0d)", 
                 x_in, y_in, pixel_on ? "ON" : "OFF", s3);
        
        $finish;
    end
    
    // Optional: Add VCD dumping for waveform viewing
    initial begin
        $dumpfile("score_on_pixel.vcd");
        $dumpvars(0, score_on_pixel_tb);
    end
endmodule
