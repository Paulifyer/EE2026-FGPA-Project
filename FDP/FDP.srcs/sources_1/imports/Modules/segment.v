`timescale 1ns / 1ps

// module main(...);
// ++import segment::*;
// endmodule 

package segment;
  parameter SEG_ALL = 8'b00000000;
  parameter SEG_EMPTY = 8'b11111111;
  parameter SEG_A = ~(1 << 0) & 8'b11111111;
  parameter SEG_B = ~(1 << 1) & 8'b11111111;
  parameter SEG_C = ~(1 << 2) & 8'b11111111;
  parameter SEG_D = ~(1 << 3) & 8'b11111111;
  parameter SEG_E = ~(1 << 4) & 8'b11111111;
  parameter SEG_F = ~(1 << 5) & 8'b11111111;
  parameter SEG_G = ~(1 << 6) & 8'b11111111;
  parameter SEG_DEC = ~(1 << 7) & 8'b11111111;

  parameter SEG_0 = SEG_A & SEG_B & SEG_C & SEG_D & SEG_E & SEG_F;
  parameter SEG_1 = SEG_B & SEG_C;
  parameter SEG_2 = SEG_A & SEG_B & SEG_G & SEG_E & SEG_D;
  parameter SEG_3 = SEG_A & SEG_B & SEG_G & SEG_C & SEG_D;
  parameter SEG_4 = SEG_F & SEG_G & SEG_B & SEG_C;
  parameter SEG_5 = SEG_A & SEG_F & SEG_G & SEG_C & SEG_D;
  parameter SEG_6 = SEG_A & SEG_F & SEG_G & SEG_C & SEG_D & SEG_E;
  parameter SEG_7 = SEG_A & SEG_B & SEG_C;
  parameter SEG_8 = SEG_A & SEG_B & SEG_C & SEG_D & SEG_E & SEG_F & SEG_G;
  parameter SEG_9 = SEG_A & SEG_B & SEG_C & SEG_D & SEG_F & SEG_G;

  parameter SEG_CHAR_A = SEG_A & SEG_B & SEG_C & SEG_E & SEG_F & SEG_G;
  parameter SEG_CHAR_B = SEG_C & SEG_D & SEG_E & SEG_F & SEG_G;
  parameter SEG_CHAR_C = SEG_A & SEG_D & SEG_E & SEG_F;
  parameter SEG_CHAR_D = SEG_B & SEG_C & SEG_D & SEG_E & SEG_G;
  parameter SEG_CHAR_E = SEG_A & SEG_D & SEG_E & SEG_F & SEG_G;
  parameter SEG_CHAR_F = SEG_A & SEG_E & SEG_F & SEG_G;
  parameter SEG_CHAR_G = SEG_A & SEG_C & SEG_D & SEG_E & SEG_F;
  parameter SEG_CHAR_H = SEG_B & SEG_C & SEG_E & SEG_F & SEG_G;
  parameter SEG_CHAR_I = SEG_B & SEG_C;
  parameter SEG_CHAR_J = SEG_B & SEG_C & SEG_D & SEG_E;
  parameter SEG_CHAR_L = SEG_D & SEG_E & SEG_F;
  parameter SEG_CHAR_O = SEG_E & SEG_G & SEG_C & SEG_D;
  parameter SEG_CHAR_P = SEG_A & SEG_B & SEG_E & SEG_F & SEG_G;
  parameter SEG_CHAR_S = SEG_A & SEG_C & SEG_D & SEG_F & SEG_G;
  parameter SEG_CHAR_U = SEG_B & SEG_C & SEG_D & SEG_E & SEG_F;

endpackage