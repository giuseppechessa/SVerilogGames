`timescale 1ns/1ps



module vga_test
	(
		input clk, reset,
		input [11:0] sw,
		output hsync, vsync,
		output logic[11:0] rgb
	);
	// video status output from vga_sync to tell when to route out rgb signal to DAC
	logic[11:0]  rgb_local;
	logic[9:0] x,y;
	// instantiate vga_sync
	vga_sync vga_sync_unit (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),.video_on(video_on), .p_tick(ptick), .x(x), .y(y));
  
  logic [9:0] ball_x, ball_y, ball_x_next, ball_y_next;	// ball current position
  
  logic [9:0] ball_x_move = -2;	// ball current X velocity
  logic [9:0] ball_y_move = 2;		// ball current Y velocity
  
  localparam ball_horiz_initial = 128;	// ball initial X position
  localparam ball_vert_initial = 128;	// ball initial Y position
  localparam BALL_SIZE = 4;		// ball size (in pixels)
  
  logic vsync_p;
  // update horizontal timer
  always_ff @(posedge vsync or posedge reset) begin
      ball_y <= reset ? ball_vert_initial : ball_y_next;
      ball_x <= reset ? ball_horiz_initial: ball_x_next;
  end
  
  assign ball_x_next =ball_x + ball_x_move;
  assign ball_y_next =ball_y + ball_y_move;
  
  
  logic ball_y_collide, ball_x_collide, ball_y_collide_p, ball_x_collide_p;
  // these are set when the ball touches a border
  assign ball_y_collide = ball_y >= 480 - BALL_SIZE;
  assign ball_x_collide =  ball_x >= 640 - BALL_SIZE;

  // vertical bounce
  always_ff @(posedge clk)
  begin
    if(ball_y_collide && ball_y_collide != ball_y_collide_p) begin 
      ball_y_move <= -ball_y_move;
      ball_y_collide_p <= ball_y_collide;
      end
     else if ( ball_y_collide != ball_y_collide_p ) 
       ball_y_collide_p <= ball_y_collide;
  end
  
  always_ff @(posedge clk)
  begin
    if(ball_x_collide && ball_x_collide != ball_x_collide_p) begin 
      ball_x_move <= -ball_x_move;
      ball_x_collide_p <= ball_x_collide;
    end
    else if ( ball_x_collide != ball_x_collide_p ) 
      ball_x_collide_p <= ball_x_collide;
  end
  
  
  logic[9:0] ball_xdiff, ball_ydiff;
  // offset of ball position from video beam
  assign ball_xdiff = x - ball_x;
  assign ball_ydiff = y - ball_y;
  
  logic ball_hgfx,ball_vgfx,ball_gfx,grid_gfx;
  // ball graphics output
  assign ball_hgfx = ball_xdiff < BALL_SIZE;
  assign ball_vgfx = ball_ydiff < BALL_SIZE;
  assign ball_gfx = ball_hgfx && ball_vgfx;
  // collide with vertical and horizontal boundaries
  logic[3:0] r,g,b;
  // combine signals to RGB output
  assign grid_gfx = (((x&7)==0) && ((y&7)==0));
  assign r = {4{video_on && (ball_hgfx | ball_gfx)}};
  assign g = {4{video_on && (grid_gfx | ball_gfx)}};
  assign b = {4{video_on && (ball_vgfx | ball_gfx)}};
  assign rgb = {b,g,r};

endmodule
