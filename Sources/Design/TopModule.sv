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
  
  logic [9:0] ball_hpos, ball_vpos;	// ball current position
  
  logic [9:0] ball_horiz_move = -2;	// ball current X velocity
  logic [9:0] ball_vert_move = 2;		// ball current Y velocity
  
  localparam ball_horiz_initial = 128;	// ball initial X position
  localparam ball_vert_initial = 128;	// ball initial Y position
  localparam BALL_SIZE = 4;		// ball size (in pixels)
  
  // update horizontal timer
  always @(posedge vsync or posedge reset)
  begin
    if (reset) begin
      // reset ball position to center
      ball_vpos <= ball_vert_initial;
      ball_hpos <= ball_horiz_initial;
    end else begin
      // add velocity vector to ball position
      ball_hpos <= ball_hpos + ball_horiz_move;
      ball_vpos <= ball_vpos + ball_vert_move;
    end
  end
  
  logic ball_vert_collide, ball_horiz_collide, ball_vert_collide_p, ball_horiz_collide_p;
  // these are set when the ball touches a border
  assign ball_vert_collide = ball_vpos >= 480 - BALL_SIZE;
  assign ball_horiz_collide =  ball_hpos >= 640 - BALL_SIZE;

  // vertical bounce
  always @(posedge clk)
  begin
    if(ball_vert_collide && ball_vert_collide != ball_vert_collide_p) begin 
      ball_vert_move <= -ball_vert_move;
      ball_vert_collide_p <= ball_vert_collide;
      end
     else if ( ball_vert_collide != ball_vert_collide_p ) 
       ball_vert_collide_p <= ball_vert_collide;
  end
  
  always_ff @(posedge clk)
  begin
    if(ball_horiz_collide && ball_horiz_collide != ball_horiz_collide_p) begin 
      ball_horiz_move <= -ball_horiz_move;
      ball_horiz_collide_p <= ball_horiz_collide;
      end
     else if ( ball_horiz_collide != ball_horiz_collide_p ) 
       ball_horiz_collide_p <= ball_horiz_collide;
  end
  
  
  logic[9:0] ball_hdiff, ball_vdiff;
  // offset of ball position from video beam
  assign ball_hdiff = x - ball_hpos;
  assign ball_vdiff = y - ball_vpos;
  logic ball_hgfx,ball_vgfx,ball_gfx,grid_gfx;
  // ball graphics output
  assign ball_hgfx = ball_hdiff < BALL_SIZE;
  assign ball_vgfx = ball_vdiff < BALL_SIZE;
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
