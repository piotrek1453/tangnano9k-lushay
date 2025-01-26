`default_nettype none

module oled #(
    parameter STARTUP_WAIT = 32'd10000000
) (
    input clk,
    output io_sclk,
    output io_sdin,
    output io_cs,
    output io_dc,
    output io_reset
);

  localparam STATE_INIT_POWER = 'd0;
  localparam STATE_LOAD_INIT_CMD = 'd1;
  localparam STATE_SEND = 'd2;
  localparam STATE_CHECK_FINISHED_INIT = 'd3;
  localparam STATE_LOAD_DATA = 'd4;

  reg [$clog2(STARTUP_WAIT):0] counter = 0;
  reg [2:0] state = 0;

  reg dc = 1;
  reg sclk = 1;
  reg sdin = 0;
  reg reset = 1;
  reg cs = 0;

  reg [7:0] dataToSend = 0;
  reg [3:0] bitNumber = 0;
  reg [9:0] pixelCounter = 0;

  localparam SETUP_INSTRUCTIONS = 23;
  reg [(SETUP_INSTRUCTIONS*8)-1:0] startupCommands = {
    8'hAE,  // display off

    8'h81,  // contast value to 0x7F according to datasheet
    8'h7F,

    8'hA6,  // normal screen mode (not inverted)

    8'h20,  // horizontal addressing mode
    8'h00,

    8'hC8,  // normal scan direction

    8'h40,  // first line to start scanning from

    8'hA1,  // address 0 is segment 0

    8'hA8,  // mux ratio
    8'h3f,  // 63 (64 -1)

    8'hD3,  // display offset
    8'h00,  // no offset

    8'hD5,  // clock divide ratio
    8'h80,  // set to default ratio/osc frequency

    8'hD9,  // set precharge
    8'h22,  // switch precharge to 0x22 default

    8'hDB,  // vcom deselect level
    8'h20,  // 0x20

    8'h8D,  // charge pump config
    8'h14,  // enable charge pump

    8'hA4,  // resume RAM content

    8'hAF   // display on
  };
  reg [7:0] commandIndex = SETUP_INSTRUCTIONS * 8;

  reg [7:0] screenBuffer [1023:0];

  genvar i;
  generate
    for (i = 0; i < 1024; i = i + 1) begin: image
      if (i%2==0) begin
        // assign screenBuffer[i] = 8'b10101010;
        assign screenBuffer[i] = 'd5;
      end else begin
        // assign screenBuffer[i] = 8'b01010101;
        assign screenBuffer[i] = ~'d5;
      end
    end
  endgenerate
  // initial $readmemh("image.hex", screenBuffer);

  assign io_sclk = sclk;
  assign io_sdin = sdin;
  assign io_dc = dc;
  assign io_reset = reset;
  assign io_cs = cs;

  always @(posedge clk) begin
    case (state)

      STATE_INIT_POWER: begin
        counter <= counter+1;
        if (counter < STARTUP_WAIT) begin
          reset <= 1;
        end
        else if (counter < STARTUP_WAIT * 2) begin
          reset <= 0;
        end
        else if (counter < STARTUP_WAIT * 3) begin
          reset <= 1;
        end
        else begin
          state <= STATE_LOAD_INIT_CMD;
          counter <= 'b0;
        end
      end

      STATE_LOAD_INIT_CMD: begin
        dc <= 0;
        dataToSend <= startupCommands[(commandIndex-1)-:8'd8];
        state <= STATE_SEND;
        bitNumber <= 3'd7;
        cs <= 0;
        commandIndex <= commandIndex - 8'd8;
      end

      STATE_SEND: begin
        if (counter == 'd0) begin
          sclk <= 0;
          sdin <= dataToSend[bitNumber];
          counter <= 'd1;
        end
        else begin
          counter <= 'd0;
          sclk <= 1;
          if (bitNumber == 0) begin
            state <= STATE_CHECK_FINISHED_INIT;
          end
          else begin
            bitNumber <= bitNumber - 1;
          end
        end
      end

      STATE_CHECK_FINISHED_INIT: begin
        cs <= 1;
        if (commandIndex == 0) begin
          state <= STATE_LOAD_DATA;
        end
        else begin
            state <= STATE_LOAD_INIT_CMD;
        end
        end

      STATE_LOAD_DATA: begin
        pixelCounter <= pixelCounter + 1;
        cs <= 0;
        dc <= 1;
        bitNumber <= 'd7;
        state <= STATE_SEND;
        dataToSend <= screenBuffer[pixelCounter];
      end

    endcase
  end

endmodule
