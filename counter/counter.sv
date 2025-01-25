`default_nettype none

module counter #(
    parameter integer NUMBER_OF_LEDS = 6,
    parameter integer DELAY_CYCLES   = 'd13500000
) (
    input wire clk,
    output wire [NUMBER_OF_LEDS-1:0] led
);

  localparam integer LedsNo = $bits(led) - 1;

  // initialize for cyclic shift
  reg [LedsNo:0] led_buffer = ~'d1;
  // delay
  reg [$bits(DELAY_CYCLES)-1:0] delay_counter = 0;

  always @(posedge clk) begin
    delay_counter <= delay_counter + 1;
    if (delay_counter >= DELAY_CYCLES) begin
      delay_counter <= 0;
      // cyclic left shift
      led_buffer <= {led_buffer[LedsNo-1], led_buffer[LedsNo-2:0], led_buffer[LedsNo]};
    end
  end

  assign led = led_buffer;

endmodule
