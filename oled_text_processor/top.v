`default_nettype none

module top (
    input  clk,
    output ioSclk,
    output ioSdin,
    output ioCs,
    output ioDc,
    output ioReset
);

  wire [9:0] pixelAddress;
  wire [7:0] pixelData;

  oled oled_inst (
      .clk(clk),
      .pixelData(pixelData),
      .io_sclk(ioSclk),
      .io_sdin(ioSdin),
      .io_cs(ioCs),
      .io_dc(ioDc),
      .io_reset(ioReset),
      .pixelAddress(pixelAddress)
  );

  textEngine textEngine_inst (
      .clk(clk),
      .pixelAddress(pixelAddress),
      .pixelData(pixelData)
  );

endmodule
