`include "global.vh"
`include "channel.vh"
`include "channel__subchannel.vh"
`include "top__channel.vh"

module channel(
    input                      clk,
    input                      global_reset,
    input                      reset,
    input [`MODE_RANGE]        mode,
    //Sample data.
    input                      data_available,
    input                      feed_complete,
    input [`INPUT_RANGE]       data,
    //Carrier control.
    input [`DOPPLER_INC_RANGE] doppler_early,
    input [`DOPPLER_INC_RANGE] doppler_prompt,
    input [`DOPPLER_INC_RANGE] doppler_late,
    //Code control.
    input [4:0]                prn,
    input                      seek_en,
    input [`CS_RANGE]          seek_target,
    output wire [`CS_RANGE]    code_shift,
    //Outputs.
    output wire                accumulator_updating,
    output wire [`ACC_RANGE]   accumulator_i,
    output wire [`ACC_RANGE]   accumulator_q,
    output wire                accumulation_complete,
    output wire                i2q2_valid,
    output reg [`I2Q2_RANGE]   i2q2_early,
    output reg [`I2Q2_RANGE]   i2q2_prompt,
    output reg [`I2Q2_RANGE]   i2q2_late,
    //Debug outputs.
    output wire                ca_bit,
    output wire                ca_clk,
    output wire [9:0]          ca_code_shift);

   //Reset subchannels immediately after accumulation
   //has finished (after feed complete) in acquisition.
   wire clear_subchannels;
   assign clear_subchannels = (mode==`MODE_ACQ && accumulation_complete) ||
                              (mode==`MODE_TRACK && 1'b1);
   
   //Early subchannel.
   wire early_updating, early_complete;
   (* keep *) wire [`ACC_RANGE] acc_i_early, acc_q_early;
   wire [`CS_RANGE] code_shift_early;
   wire seeking_early;
   wire ca_bit_early, ca_clk_early;
   wire [9:0] ca_code_shift_early;
   subchannel early(.clk(clk),
                    .global_reset(global_reset),
                    .clear(clear_subchannels),
                    .data_available(data_available),
                    .feed_complete(feed_complete),
                    .data(data),
                    .doppler(doppler_early),
                    .prn(prn),
                    .seek_en(seek_en),
                    .seek_target(seek_target),
                    .seeking(seeking_early),
                    .code_shift(code_shift_early),
                    .accumulator_updating(early_updating),
                    .accumulator_i(acc_i_early),
                    .accumulator_q(acc_q_early),
                    .accumulation_complete(early_complete),
                    .ca_bit(ca_bit_early),
                    .ca_clk(ca_clk_early),
                    .ca_code_shift(ca_code_shift_early));
   
   //Prompt subchannel.
   wire prompt_updating, prompt_complete;
   (* keep *) wire [`ACC_RANGE] acc_i_prompt, acc_q_prompt;
   wire seeking_prompt;
   subchannel prompt(.clk(clk),
                     .global_reset(global_reset),
                     .clear(clear_subchannels),
                     .data_available(data_available),
                    .feed_complete(feed_complete),
                     .data(data),
                     .doppler(doppler_prompt),
                     .prn(prn),
                     .seek_en(seek_en),
                     .seek_target(seek_target),
                     .seeking(seeking_prompt),
                     .code_shift(code_shift),
                     .accumulator_updating(prompt_updating),
                     .accumulator_i(acc_i_prompt),
                     .accumulator_q(acc_q_prompt),
                     .accumulation_complete(prompt_complete),
                     .ca_bit(ca_bit),
                     .ca_clk(ca_clk),
                     .ca_code_shift(ca_code_shift));
   assign accumulator_updating = prompt_updating;
   assign accumulator_i = acc_i_prompt;
   assign accumulator_q = acc_q_prompt;
   assign accumulation_complete = prompt_complete;
   
   
   //Late subchannel.
   wire late_updating, late_complete;
   (* keep *) wire [`ACC_RANGE] acc_i_late, acc_q_late;
   wire [`CS_RANGE] code_shift_late;
   wire seeking_late;
   wire ca_bit_late, ca_clk_late;
   wire [9:0] ca_code_shift_late;
   subchannel late(.clk(clk),
                   .global_reset(global_reset),
                   .clear(clear_subchannels),
                   .data_available(data_available),
                    .feed_complete(feed_complete),
                   .data(data),
                   .doppler(doppler_late),
                   .prn(prn),
                   .seek_en(seek_en),
                   .seek_target(seek_target),
                   .seeking(seeking_late),
                   .code_shift(code_shift_late),
                   .accumulator_updating(late_updating),
                   .accumulator_i(acc_i_late),
                   .accumulator_q(acc_q_late),
                   .accumulation_complete(late_complete),
                   .ca_bit(ca_bit_late),
                   .ca_clk(ca_clk_late),
                   .ca_code_shift(ca_code_shift_late));

   //Take the absolute value of I and Q accumulations.
   wire [`ACC_MAG_RANGE] i_early_mag;
   abs #(.WIDTH(`ACC_WIDTH))
     abs_i_early(.in(acc_i_early),
                 .out(i_early_mag));

   wire [`ACC_MAG_RANGE] q_early_mag;
   abs #(.WIDTH(`ACC_WIDTH))
     abs_q_early(.in(acc_q_early),
                 .out(q_early_mag));

   wire [`ACC_MAG_RANGE] i_prompt_mag;
   abs #(.WIDTH(`ACC_WIDTH))
     abs_i_prompt(.in(acc_i_prompt),
                  .out(i_prompt_mag));

   wire [`ACC_MAG_RANGE] q_prompt_mag;
   abs #(.WIDTH(`ACC_WIDTH))
     abs_q_prompt(.in(acc_q_prompt),
                  .out(q_prompt_mag));

   wire [`ACC_MAG_RANGE] i_late_mag;
   abs #(.WIDTH(`ACC_WIDTH))
     abs_i_late(.in(acc_i_late),
                .out(i_late_mag));

   wire [`ACC_MAG_RANGE] q_late_mag;
   abs #(.WIDTH(`ACC_WIDTH))
     abs_q_late(.in(acc_q_late),
                .out(q_late_mag));
   
   reg [`ACC_MAG_RANGE] i_early, q_early;
   reg [`ACC_MAG_RANGE] i_prompt, q_prompt;
   reg [`ACC_MAG_RANGE] i_late, q_late;
   reg acc_ready;
   always @(posedge clk) begin
      i_early <= global_reset ? `ACC_MAG_WIDTH'h0 :
                 accumulation_complete ? i_early_mag :
                 i_early;
      
      q_early <= global_reset ? `ACC_MAG_WIDTH'h0 :
                 accumulation_complete ? q_early_mag :
                 q_early;

      i_prompt <= global_reset ? `ACC_MAG_WIDTH'h0 :
                  accumulation_complete ? i_prompt_mag :
                  i_prompt;
      
      q_prompt <= global_reset ? `ACC_MAG_WIDTH'h0 :
                  accumulation_complete ? q_prompt_mag :
                  q_prompt;

      i_late <= global_reset ? `ACC_MAG_WIDTH'h0 :
                accumulation_complete ? i_late_mag :
                i_late;
      
      q_late <= global_reset ? `ACC_MAG_WIDTH'h0 :
                accumulation_complete ? q_late_mag :
                q_late;

      acc_ready <= global_reset ? 1'b0 :
                   accumulation_complete ? 1'b1 :
                   1'b0;
   end // always @ (posedge clk)

   //Square I and Q for each subchannel. Square
   //starts when an accumilation is finished, or
   //the early or prompt squares complete (3 required).
   wire start_square;
   wire square_complete_km1;
   assign start_square = acc_ready ||
                         square_complete_km1 && i2q2_select!=2'h3;
   
   wire square_complete;
   delay #(.DELAY(6))
     square_delay(.clk(clk),
                  .reset(global_reset),
                  .in(start_square),
                  .out(square_complete));

   delay square_restart_delay(.clk(clk),
                              .reset(global_reset),
                              .in(square_complete),
                              .out(square_complete_km1));
   
   reg [1:0] i2q2_select;
   always @(posedge clk) begin
      i2q2_select <= global_reset ? 2'h0 :
                     accumulation_complete ? 2'h0 :
                     square_complete ? i2q2_select+2'h1 :
                     i2q2_select;
   end
   
   wire [`I2Q2_RANGE] i2;
   multiplier i2_mult(.clock(clk),
                      .dataa(i2q2_select==2'h0 ? i_early :
                             i2q2_select==2'h1 ? i_prompt :
                             i_late),
                      .result(i2));
   
   wire [`I2Q2_RANGE] q2;
   multiplier q2_mult(.clock(clk),
                      .dataa(i2q2_select==2'h0 ? q_early :
                             i2q2_select==2'h1 ? q_prompt :
                             q_late),
                      .result(q2));

   (* keep *) wire [`I2Q2_RANGE] i2_kmn;
   delay #(.WIDTH(`I2Q2_WIDTH))
     i2_delay(.clk(clk),
              .reset(global_reset),
              .in(i2),
              .out(i2_kmn));

   (* keep *) wire [`I2Q2_RANGE] q2_kmn;
   delay #(.WIDTH(`I2Q2_WIDTH))
     q2_delay(.clk(clk),
              .reset(global_reset),
              .in(q2),
              .out(q2_kmn));
   
   wire [`I2Q2_RANGE] i2q2_out;
   assign i2q2_out = i2_kmn+q2_kmn;

   wire [`I2Q2_RANGE] i2q2_out_km1;
   delay #(.WIDTH(`I2Q2_WIDTH))
     i2q2_delay(.clk(clk),
                .reset(global_reset),
                .in(i2q2_out),
                .out(i2q2_out_km1));

   assign i2q2_valid = square_complete && i2q2_select==2'h2;

   always @(posedge clk) begin
      i2q2_early <= global_reset ? `I2Q2_WIDTH'h0 :
                    square_complete && i2q2_select==2'h0 ? i2q2_out_km1 :
                    i2q2_early;
      
      i2q2_prompt <= global_reset ? `I2Q2_WIDTH'h0 :
                     square_complete && i2q2_select==2'h1 ? i2q2_out_km1 :
                     i2q2_prompt;
      
      i2q2_late <= global_reset ? `I2Q2_WIDTH'h0 :
                   square_complete && i2q2_select==2'h2 ? i2q2_out_km1 :
                   i2q2_late;
   end
   
endmodule