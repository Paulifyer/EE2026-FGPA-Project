module keyboard (
    input clk,
    input PS2Data,
    input PS2Clk,
    output reg [7:0] pressed_key,
    output key_W,
    output key_A,
    output key_S,
    output key_D,
    output key_B,
    output key_ENTER
);


  parameter W = 8'b00011101;
  parameter A = 8'b00011100;
  parameter S = 8'b00011011;
  parameter D = 8'b00100011;
  parameter B = 8'b00110010;
  parameter ENTER = 8'b01011010;

  wire [15:0] keycode;
  wire        flag;

  // PS2 receiver instantiation
  PS2Receiver uut (
      .clk(clk),
      .kclk(PS2Clk),
      .kdata(PS2Data),
      .keycode(keycode),
      .oflag(flag)
  );

  // Simpler key handling
  always @(posedge clk) begin
    if (flag) begin
      if (keycode[7:0] == 8'hF0) pressed_key <= 8'h00;  // No key pressed
      else if (keycode[15:8] == 8'hF0) pressed_key <= 8'h00;  // No key pressed
      else
        pressed_key <= keycode[7:0];  // Store the key code
    end
  end

  assign current_key = pressed_key;

  assign key_W = (pressed_key == W) ? 1 : 0;
  assign key_A = (pressed_key == A) ? 1 : 0;
  assign key_S = (pressed_key == S) ? 1 : 0;
  assign key_D = (pressed_key == D) ? 1 : 0;
  assign key_B = (pressed_key == B) ? 1 : 0;
  assign key_ENTER = (pressed_key == ENTER) ? 1 : 0;
endmodule
