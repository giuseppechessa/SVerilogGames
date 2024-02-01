`timescale 1ns/1ps



module vga_test
	(
		input clk, reset,
		input [11:0] sw,
		output hsync, vsync,
		output logic[11:0] rgb
	);
	
	// video status output from vga_sync to tell when to route out rgb signal to DAC
	logic video_on,ptick;
	logic[11:0]  rgb_local,x,y;
  
	// instantiate vga_sync
	vga_sync vga_sync_unit (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),.video_on(video_on), .p_tick(ptick), .x(x), .y(y));
   
   
  //1024-800=224-> 224 il più vicino numero multiplo di 16-> 224>>4 = 14      
  localparam ball_horiz_prefix = 6'd14;
  //1024-525=499 .> 496 il più vicino multiplo di 16 -> 496>>4 = 31
  localparam ball_vert_prefix = 6'd31;
  logic[9:0] Xcounter,Xcounter_next,Ycounter,Ycounter_next; 
  logic [3:0] XMove,YMove;
  always_ff @(posedge hsync, posedge reset)   begin
    Ycounter <= (reset || &Ycounter) ? {ball_vert_prefix,YMove} : Ycounter_next;
  end
  always_ff @(posedge ptick, posedge reset)   begin
    Xcounter <= (reset || &Xcounter) ? (&Ycounter ? {ball_horiz_prefix,XMove} :{ball_horiz_prefix,4'd0}) : Xcounter_next;
  end
  assign Xcounter_next = Xcounter+1;
  assign Ycounter_next = Ycounter+1;
  assign XMove = 4'd2;
  assign YMove = 4'd2;
   
	// rgb buffer
	always_ff @(posedge clk, posedge reset)
		if (reset)
			rgb <= 0;
		else
			rgb <= rgb_local;
			
  logic ball_hgfx = Xcounter >= 1020;	// 1024-1020 = 4 pixel ball
  logic ball_vgfx = Ycounter >= 1020;
  logic ball_gfx = ball_hgfx && ball_vgfx;
	// output
	logic[3:0] r = {4{video_on && (ball_hgfx | ball_gfx)}};
  logic[3:0] g = {4{video_on && ball_gfx}};
  logic[3:0] b = {4{video_on && (ball_vgfx | ball_gfx)}};
  assign rgb_local = {b,g,r};

endmodule
