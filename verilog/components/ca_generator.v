// This file is part of the Cornell University Hardware GPS Receiver Project.
// Copyright (C) 2009 - Adam Shapiro (ams348@cornell.edu)
//                      Tom Chatt (tjc42@cornell.edu)
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
`define TAP_1 7:4
`define TAP_2 3:0

module ca_generator(
    input            clk,
    input            reset,
    input            enable,
    input [4:0]      prn,
    output reg [9:0] code_shift,
    output           out);

   reg [10:1]       g1;
   reg [10:1]       g2;
   reg [7:0]        taps;
   
   assign out=g1[10]^(g2[taps[`TAP_1]]^g2[taps[`TAP_2]]);

   always @(posedge clk) begin
      code_shift<=reset ? 10'd0 :
                  !enable ? code_shift :
                  code_shift==10'd1022 ? 10'd0 :
                  code_shift+10'd1;
      g1<=reset ? 10'h3FF :
          !enable ? g1 :
          g1<<1 | (g1[3]^g1[10]);
      g2<=reset ? 10'h3FF :
          !enable ? g2 :
          g2<<1 | (g2[2]^g2[3]^g2[6]^g2[8]^g2[9]^g2[10]);
   end

   always @(prn) begin
      case(prn)
        5'd0: taps<={4'd2,4'd6};
        5'd1: taps<={4'd3,4'd7};
        5'd2: taps<={4'd4,4'd8};
        5'd3: taps<={4'd5,4'd9};
        5'd4: taps<={4'd1,4'd9};
        5'd5: taps<={4'd2,4'd10};
        5'd6: taps<={4'd1,4'd8};
        5'd7: taps<={4'd2,4'd9};
        5'd8: taps<={4'd3,4'd10};
        5'd9: taps<={4'd2,4'd3};
        5'd10: taps<={4'd3,4'd4};
        5'd11: taps<={4'd5,4'd6};
        5'd12: taps<={4'd6,4'd7};
        5'd13: taps<={4'd7,4'd8};
        5'd14: taps<={4'd8,4'd9};
        5'd15: taps<={4'd9,4'd10};
        5'd16: taps<={4'd1,4'd4};
        5'd17: taps<={4'd2,4'd5};
        5'd18: taps<={4'd3,4'd6};
        5'd19: taps<={4'd4,4'd7};
        5'd20: taps<={4'd5,4'd8};
        5'd21: taps<={4'd6,4'd9};
        5'd22: taps<={4'd1,4'd3};
        5'd23: taps<={4'd4,4'd6};
        5'd24: taps<={4'd5,4'd7};
        5'd25: taps<={4'd6,4'd8};
        5'd26: taps<={4'd7,4'd9};
        5'd27: taps<={4'd8,4'd10};
        5'd28: taps<={4'd1,4'd6};
        5'd29: taps<={4'd2,4'd7};
        5'd30: taps<={4'd3,4'd8};
        5'd31: taps<={4'd4,4'd9};
        default: taps<={4'd0,4'd0};
      endcase
   end
endmodule