`default_nettype none

module textEngine (
    input clk,
    input [9:0] pixelAddress,
    output [7:0] pixelData
);

  reg [7:0] fontBuffer[1519:0];
  initial begin
    $readmemh("font.hex", fontBuffer);
  end

  wire [5:0] charAddress;
  wire [2:0] columnAddress;
  wire topRow;
  reg [7:0] outputBuffer;

  assign charAddress = {pixelAddress[9:8], pixelAddress[6:3]};
  assign columnAddress = pixelAddress[2:0];
  assign topRow = !pixelAddress[7];

  assign pixelData = outputBuffer;

  wire [7:0] charOutput, chosenChar;
  wire [7:0] charOutput1, charOutput2, charOutput3, charOutput4;

  textRow #(
      .INIT_STRING("row 0           ")
  ) t1 (
      clk,
      charAddress,
      charOutput1
  );
  textRow #(
      .INIT_STRING("row 1           ")
  ) t2 (
      clk,
      charAddress,
      charOutput2
  );
  textRow #(
      .INIT_STRING("row 2           ")
  ) t3 (
      clk,
      charAddress,
      charOutput3
  );
  textRow #(
      .INIT_STRING("row 3           ")
  ) t4 (
      clk,
      charAddress,
      charOutput4
  );


  assign chosenChar = (charOutput >= 32 && charOutput <= 126) ? charOutput : 32;

  always @(posedge clk) begin
    outputBuffer <= fontBuffer[((chosenChar-'d32)<<4)+(columnAddress<<1)+(topRow?0 : 1)];
  end

  assign charOutput = (charAddress[5] && charAddress[4])
  ? charOutput4 : ((charAddress[5])
  ? charOutput3 : ((charAddress[4]) ? charOutput2 : charOutput1));


endmodule

module textRow #(
    parameter ADDRESS_OFFSET = 8'd0,
    parameter INIT_STRING = "                "  // 16 characters default
) (
    input clk,
    input [7:0] readAddress,
    output [7:0] outByte
);
  reg [7:0] textBuffer[15:0];

  assign outByte = textBuffer[(readAddress-ADDRESS_OFFSET)];

  integer i;
  initial begin
    for (i = 0; i < 16; i = i + 1) begin
      textBuffer[i] = INIT_STRING[(8*(15-i))+:8];
    end
  end
endmodule
