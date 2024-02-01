`timescale 1ns/1ps

module Vga_simulation();
  logic clk,reset,hsync,vsync;
  logic[11:0] sw,rgb;
  vga_test Test(clk,reset, sw, hsync, vsync, rgb);
  initial begin
    reset=0;
    clk=0;
  end
  assign #5 clk = ~clk;
  assign sw = 12'b0;

endmodule