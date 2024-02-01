`timescale 1ns/1ps

module vga_sync

	(
		input clk, reset,
		output logic hsync, vsync, video_on, p_tick,
		output logic[9:0] x, y
	);
	
	// constant declarations for VGA sync parameters
	localparam H_DISPLAY       = 640; // horizontal display area
	localparam H_L_BORDER      =  48; // horizontal left border
	localparam H_R_BORDER      =  16; // horizontal right border
	localparam H_SYNC		       =  96; // horizontal retrace
	localparam H_MAX           = H_DISPLAY + H_L_BORDER + H_R_BORDER + H_SYNC - 1;
	localparam START_H_RETRACE = H_DISPLAY + H_R_BORDER;
	localparam END_H_RETRACE   = H_DISPLAY + H_R_BORDER + H_SYNC - 1;
	
	localparam V_DISPLAY       = 480; // vertical display area
	localparam V_T_BORDER      =  10; // vertical top border
	localparam V_B_BORDER      =  33; // vertical bottom border
	localparam V_SYNC		       =   2; // vertical retrace
	localparam V_MAX           = V_DISPLAY + V_T_BORDER + V_B_BORDER + V_SYNC - 1;
  localparam START_V_RETRACE = V_DISPLAY + V_B_BORDER;
	localparam END_V_RETRACE   = V_DISPLAY + V_B_BORDER + V_SYNC - 1;
	
	// mod-4 counter to generate 25 MHz pixel tick
	logic [1:0] pixel_reg;
	logic [1:0] pixel_next;
	
	always_ff @(posedge clk, posedge reset)
		if(reset)
		  pixel_reg <= 0;
		else
		  pixel_reg <= pixel_next;
		  
	assign pixel_next = pixel_reg + 1; // increment pixel_reg 
	assign p_tick = (pixel_reg == 0); // assert tick 1/4 of the time
	
	// registers to keep track of current pixel location
	logic [9:0] x_next, y_next;
	// register to keep track of vsync and hsync signal states
	logic vsync_next, hsync_next;
 
	always_ff @(posedge clk, posedge reset)
		if(reset) begin
    	x <= 0;
      y <= 0;
      vsync   <= 0;
      hsync   <= 0;
		end
		else begin
    	y <= y_next;
    	x <= x_next;
    	vsync   <= vsync_next;
    	hsync   <= hsync_next;
		end
			
	// next-state logic of horizontal vertical sync counters
	assign x_next = p_tick ? (x == H_MAX ? 0 : x + 1) : x;
	assign y_next = p_tick && x == H_MAX ?  (y == V_MAX ? 0 : y + 1) : y;
	
  // hsync and vsync are active low signals
  // hsync signal asserted during horizontal retrace
 	assign hsync_next = x >= START_H_RETRACE && x <= END_H_RETRACE;
  // vsync signal asserted during vertical retrace
  assign vsync_next = y >= START_V_RETRACE  && y <= END_V_RETRACE;
   // video only on when pixels are in both horizontal and vertical display region
   assign video_on = (x < H_DISPLAY) && (y < V_DISPLAY);
endmodule
