`timescale 1ns / 1ps

module is_collision_tb();
    // Parameters
    parameter width = 12;
    parameter height = 8;
    
    // Inputs
    reg [7:0] x1;
    reg [7:0] y1;
    reg [95:0] wall_tiles;
    reg [2:0] direction;
    
    // Outputs
    wire [7:0] x_out;
    wire [7:0] y_out;
    
    // Instantiate the Unit Under Test (UUT)
    is_collision uut (
        .x1(x1),
        .y1(y1),
        .wall_tiles(wall_tiles),
        .direction(direction),
        .x_out(x_out),
        .y_out(y_out)
    );
    
    // Test cases
    initial begin
        // Initialize inputs
        x1 = 0;
        y1 = 0;
        wall_tiles = 0;
        direction = 0;
        
        // Wait for global reset
        #10;
        
        // Test case 1: Moving up without collision
        x1 = 5;
        y1 = 5;
        wall_tiles = 6 + 5 * width; // Wall at (6,5)
        direction = 3'b001; // Up
        #10;
        
        // Test case 1: Moving up without collision
        x1 = 5;
        y1 = 5;
        wall_tiles = 0; // Wall at (6,5)
        direction = 3'b001; // Up
        #10;
        $display("Test 1 - Move Up: x_out=%d, y_out=%d", x_out, y_out);
        
        // Test case 2: Moving up with wall collision
        x1 = 5;
        y1 = 5;
        wall_tiles = 6 + 5 * width; // Wall at (6,5)
        direction = 3'b001; // Up
        #10;
        $display("Test 2 - Wall collision Up: x_out=%d, y_out=%d", x_out, y_out);
        
        // Test case 3: Moving right without collision
        x1 = 5;
        y1 = 5;
        wall_tiles = 5 + 6 * width; // Wall at (5,6)
        direction = 3'b010; // Right
        #10;
        $display("Test 3 - Move Right: x_out=%d, y_out=%d", x_out, y_out);
        
        // Test case 4: Moving right with wall collision
        x1 = 5;
        y1 = 5;
        wall_tiles = 5 + 6 * width; // Wall at (5,6)
        direction = 3'b010; // Right
        #10;
        $display("Test 4 - Wall collision Right: x_out=%d, y_out=%d", x_out, y_out);
        
        // Test case 5: Moving down without collision
        x1 = 5;
        y1 = 5;
        wall_tiles = 4 + 5 * width; // Wall at (4,5)
        direction = 3'b011; // Down
        #10;
        $display("Test 5 - Move Down: x_out=%d, y_out=%d", x_out, y_out);
        
        // Test case 6: Moving left without collision
        x1 = 5;
        y1 = 5;
        wall_tiles = 5 + 4 * width; // Wall at (5,4)
        direction = 3'b100; // Left
        #10;
        $display("Test 6 - Move Left: x_out=%d, y_out=%d", x_out, y_out);
        
        // Test case 7: Edge detection (top edge)
        x1 = 5;
        y1 = 1;
        wall_tiles = 20 + 20 * width; // Wall far away
        direction = 3'b100; // Left (would make y=0, which is an edge)
        #10;
        $display("Test 7 - Edge detection (top): x_out=%d, y_out=%d", x_out, y_out);
        
        // Test case 8: Edge detection (right edge)
        x1 = width-2;
        y1 = 5;
        wall_tiles = 20 + 20 * width; // Wall far away
        direction = 3'b001; // Up (would make x=width-1, which is an edge)
        #10;
        $display("Test 8 - Edge detection (right): x_out=%d, y_out=%d", x_out, y_out);
        
        // Test case 9: Default direction
        x1 = 5;
        y1 = 5;
        wall_tiles = 0;
        direction = 3'b000; // Invalid direction
        #10;
        $display("Test 9 - Default direction: x_out=%d, y_out=%d", x_out, y_out);
        
        $finish;
    end
    
    // Optional: Add waveform dumping for visualization
    initial begin
        $dumpfile("is_collision_tb.vcd");
        $dumpvars(0, is_collision_tb);
    end
endmodule