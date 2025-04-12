`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////// 
// Authored by David J Marion aka FPGA Dude
// Created on 4/29/2022
// Playing Star Wars "Imperial March" on speaker driven by the Basys 3 FPGA.
/////////////////////////////////////////////////////////////////////////////// 

module song_top(
    input clk_100MHz,       // from Basys 3
    input btnC, btnU, btnL, btnR, btnD,
    output speaker          // PMOD JC[0]
    );
    
    // Play button debounce
    reg xU, yU, zU;
    reg xD, yD, zD;
    reg xL, yL, zL;
    reg xR, yR, zR;
    reg xC, yC, zC;
    
    wire w_play_D;
    wire w_play_U;
    wire w_play_L;
    wire w_play_R;
    wire w_play_C;
    
    always @(posedge clk_100MHz) begin
        xD <= btnD;
        yD <= xD;
        zD <= yD;
        
        xU <= btnU;
        yU <= xU;
        zU <= yU;
        
        xL <= btnL;
        yL <= xL;
        zL <= yL;
        
        xR <= btnR;
        yR <= xR;
        zR <= yR;
        
        xC <= btnC;
        yC <= xC;
        zC <= yC;
        
    end
    assign w_play_D = zD;
    assign w_play_U = zU;
    assign w_play_L = zL;
    assign w_play_R = zR;
    assign w_play_C = zC;
    
    // Signals for each tone
    wire a, cH, eH, fH, f, gS;
//    wire a0, e1, e2;
    
    // Instantiate tone modules
    f_349Hz   t_f (.clk_100MHz(clk_100MHz), .o_349Hz(f));
    gS_415Hz  t_gS(.clk_100MHz(clk_100MHz), .o_415Hz(gS));
    a_440Hz   t_a (.clk_100MHz(clk_100MHz), .o_440Hz(a));
    cH_523Hz  t_cH(.clk_100MHz(clk_100MHz), .o_523Hz(cH));
    eH_659Hz  t_eH(.clk_100MHz(clk_100MHz), .o_659Hz(eH));
    fH_698Hz  t_fH(.clk_100MHz(clk_100MHz), .o_698Hz(fH));

    
//    a0_27_5Hz  t_a0(.clk_100MHz(clk_100MHz), .o_27_5Hz(a0)); // NEW FREQ DONT WORK AND CAUSE ERRORS, calculations inside file error
//    e1_41_2Hz  t_e1(.clk_100MHz(clk_100MHz), .o_41_2Hz(e1));
//    e2_82_41Hz  t_e2(.clk_100MHz(clk_100MHz), .o_82_41Hz(e2));

    
    // Song Note Delays
    parameter CLK_FREQ = 100_000_000;                   // 100MHz
    parameter integer D_500ms = 0.50000000 * CLK_FREQ;  // 500ms
    parameter integer D_350ms = 0.35000000 * CLK_FREQ;  // 350ms
    parameter integer D_150ms = 0.15000000 * CLK_FREQ;  // 150ms
    parameter integer D_650ms = 0.65000000 * CLK_FREQ;  // 650ms
    // Note Break Delay
    parameter integer D_break = 0.10000000 * CLK_FREQ;  // 100ms
    
    // Registers for Delays
    reg [25:0] count = 26'b0;
    reg counter_clear = 1'b0;
    reg flag_500ms = 1'b0;
    reg flag_350ms = 1'b0;
    reg flag_150ms = 1'b0;
    reg flag_650ms = 1'b0; 
    reg flag_break = 1'b0;
    
    // State Machine Register
    reg [31:0] state = "idle";
    
    always @(posedge clk_100MHz) begin
        // reaction to counter_clear signal
        if(counter_clear) begin
            count <= 26'b0;
            counter_clear <= 1'b0;
            flag_500ms <= 1'b0;
            flag_350ms <= 1'b0;
            flag_150ms <= 1'b0;
            flag_650ms <= 1'b0;
            flag_break <= 1'b0;
        end
        
        // set flags based on count
        if(!counter_clear) begin
            count <= count + 1;
            if(count == D_break) begin
                flag_break <= 1'b1;
            end
            if(count == D_150ms) begin
                flag_150ms <= 1'b1;
            end
            if(count == D_350ms) begin
                flag_350ms <= 1'b1;
            end
            if(count == D_500ms) begin
                flag_500ms <= 1'b1;
            end
            if(count == D_650ms) begin
                flag_650ms <= 1'b1;
            end
        end
       
        // State Machine
        case(state)
            "idle" : begin
                counter_clear <= 1'b1;
                if(w_play_U) begin
//                    state <= "n1"; // STARWARS [MENU]
                    state <= "PU0"; // POWERUPS and BUTTON PRESS
                end 
                else if(w_play_D) begin
//                    state <= "BGM0"; // MENU MUSIC and DEATH
                    state <= "PU0"; // POWERUPS and BUTTON PRESS
                end    
                else if(w_play_L) begin
                    state <= "PU0"; // POWERUPS and BUTTON PRESS
                end    
                else if(w_play_R) begin
//                    state <= "ex0"; // EXPLOSION
                    state <= "PU0"; // POWERUPS and BUTTON PRESS
                end    
                else if(w_play_C) begin
                    state <= "sel0"; // SELECT SOUND and DROP BOMB
                end    
                
            end
            
            //STARWARS START
            "n1" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b1";
                end
            end
            
            "b1" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n2";
                end
            end
        
            "n2" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b2";
                end
            end
        
            "b2" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                    state <= "n3";
                end
            end
        
            "n3" : begin
                if(flag_500ms) begin
                    counter_clear <= 1'b1;
                    state <= "b3";
                end
            end
        
            "b3" : begin
                if(flag_break) begin
                    counter_clear <= 1'b1;
                            state <= "n4";
                        end
                    end
                
                    "n4" : begin
                        if(flag_350ms) begin
                            counter_clear <= 1'b1;
                            state <= "b4";
                        end
                    end
                
                    "b4" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n5";
                        end
                    end
                
                    "n5" : begin
                        if(flag_150ms) begin
                            counter_clear <= 1'b1;
                            state <= "b5";
                        end
                    end
                
                    "b5" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n6";
                        end
                    end
                
                    "n6" : begin
                        if(flag_500ms) begin
                            counter_clear <= 1'b1;
                            state <= "b6";
                        end
                    end
                    
                    "b6" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n7";
                        end
                    end
                    
                    "n7" : begin
                        if(flag_350ms) begin
                            counter_clear <= 1'b1;
                            state <= "b7";
                        end
                    end
                    
                    "b7" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n8";
                        end
                    end
                    
                    "n8" : begin
                        if(flag_150ms) begin
                            counter_clear <= 1'b1;
                            state <= "b8";
                        end
                    end
                    
                    "b8" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n9";
                        end
                    end
                    
                    "n9" : begin
                        if(flag_650ms) begin
                            counter_clear <= 1'b1;
                            state <= "bm";
                        end
                    end
                
                    "bm" : begin
                        if(flag_650ms) begin
                            counter_clear <= 1'b1;
                            state <= "n10";
                        end
                    end
                    
                    "n10" : begin
                        if(flag_500ms) begin
                            counter_clear <= 1'b1;
                            state <= "b10";
                        end
                    end
                    
                    "b10" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n11";
                        end
                    end
                    
                    "n11" : begin
                        if(flag_500ms) begin
                            counter_clear <= 1'b1;
                            state <= "b11";
                        end
                    end
                    
                    "b11" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n12";
                        end
                    end
                    
                    "n12" : begin
                        if(flag_500ms) begin
                            counter_clear <= 1'b1;
                            state <= "b12";
                        end
                    end
                    
                    "b12" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n13";
                        end
                    end
                    
                    "n13" : begin
                        if(flag_350ms) begin
                            counter_clear <= 1'b1;
                            state <= "b13";
                        end
                    end
                
                    "b13" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n14";
                        end
                    end
                
                    "n14" : begin
                        if(flag_150ms) begin
                            counter_clear <= 1'b1;
                            state <= "b14";
                        end
                    end
                    
                    "b14" : begin

                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n15";
                        end
                    end
                    
                    "n15" : begin
                        if(flag_500ms) begin
                            counter_clear <= 1'b1;
                            state <= "b15";
                        end
                    end
                    
                    "b15" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n16";
                        end
                    end
                    
                    "n16" : begin
                        if(flag_350ms) begin
                            counter_clear <= 1'b1;
                            state <= "b16";
                        end
                    end
                    
                    "b16" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n17";
                        end
                    end
                    
                    "n17" : begin
                        if(flag_150ms) begin
                            counter_clear <= 1'b1;
                            state <= "b17";
                        end
                    end
                    
                    "b17" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "n18";
                        end
                    end
                    
                    "n18" : begin
                        if(flag_650ms) begin
                            counter_clear <= 1'b1;
                            state <= "idle";
                        end
                    end  
                    // STARWARS END
                    
                    // Explosion Start
                    "ex0" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "ex1";
                        end
                    end
                    
                    "ex1" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "ex2";
                        end
                    end
                    
                    "ex2" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "ex3";
                        end
                    end
                    "ex3" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "ex4";
                        end
                    end
                    
                    "ex4" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "ex5";
                        end
                    end
                    "ex5" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "ex6";
                        end
                    end
                    
                    "ex6" : begin
                        if(flag_650ms) begin
                            counter_clear <= 1'b1;
                            state <= "idle";
                        end
                    end
                    // Explosion End
                    
                    // Powerup Start
                    "PU0" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "PU1";
                        end
                    end
                    
                    "PU1" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "idle";
                        end
                    end
                    // Powerup End
                    
                    // Select sound Start
                    "sel0" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "sel1";
                        end
                    end
                    
                    "sel1" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "sel2";
                        end
                    end
                    
                    "sel2" : begin
                        if(flag_break) begin
                            counter_clear <= 1'b1;
                            state <= "idle";
                        end
                    end
                    // Select sound End
                    
                                                   
                     // Background music Start
                     "BGM0" : begin
                         if(flag_break) begin
                             counter_clear <= 1'b1;
                             state <= "BGM1";
                         end
                     end
                     
                     "BGM1" : begin
                         if(flag_break) begin
                             counter_clear <= 1'b1;
                             state <= "BGM2";
                         end
                     end
                     
                      "BGM2" : begin
                         if(flag_150ms) begin
                             counter_clear <= 1'b1;
                             state <= "BGM3";
                         end
                     end
                     
                      "BGM3" : begin
                         if(flag_break) begin
                             counter_clear <= 1'b1;
                             state <= "BGM4";
                         end
                     end
                     
                      "BGM4" : begin
                         if(flag_break) begin
                             counter_clear <= 1'b1;
                             state <= "BGM5";
                         end
                     end
                     
                     "BGM5" : begin
                         if(flag_150ms) begin
                             counter_clear <= 1'b1;
                             state <= "idle";
                         end
                     end
                     // Backround music End
                default: begin
                    counter_clear <= 1'b1;
                    state <= "idle";
                 end
                endcase                
            end
            
            // Output to speaker
            assign speaker = (state=="n1" || state=="n2" || state=="n3" || state=="n6" || state=="n9" || state=="n18" || state=="ex6" || state=="BGM0" || state=="BGM2" || state=="BGM3" || state=="BGM5") ? a :    // a
                             (state=="n4" || state=="n7" || state=="n16" || state=="ex0" || state=="ex2" || state=="ex4" || state=="sel0" || state=="sel1" || state=="PU0") ? f :                                                 // f
                             (state=="n5" || state=="n8" || state=="n14" || state=="n17" || state=="sel2" || state=="BGM1") ? cH :                                // cH
                             (state=="n10" || state=="n11" || state=="n12") ? eH :                                              // eH
                             (state=="n13" || state=="PU1") ? fH :                                                                              // fH
                             (state=="n15" || state=="ex1" || state=="ex3" || state=="ex5" || state=="BGM4") ? gS : 0;                                                                           // gS
        
        
    endmodule
