`default_nettype none

module uart_tb();

  reg clk = 0;
  reg uartRx = 1;
  wire uartTx;
  wire [5:0] led;
  reg btn = 1;

  uart #('d8) u(
    .clk(clk),
    .uartRx(uartRx),
    .uartTx(uartTx),
    .led(led),
    .btn1(btn)
  );

  always
    #1 clk = ~clk;

  initial begin
    $display("Starting UART RX");
    $monitor("LED value: %b", led);

    #10 uartRx = 0;
    #16 uartRx = 1;
    #16 uartRx = 0;
    #16 uartRx = 0;
    #16 uartRx = 0;
    #16 uartRx = 0;
    #16 uartRx = 1;
    #16 uartRx = 1;
    #16 uartRx = 0;
    #16 uartRx = 1;
    #1000 $finish;
  end

  initial begin
    $dumpfile("uart.vcd");
    $dumpvars(0, test);
  end

endmodule
