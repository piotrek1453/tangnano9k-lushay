`default_nettype none

module uart #(
    parameter integer DELAY_FRAMES = 234  // division for 115200 baudrate
) (
    input clk,
    input uartRx,
    output uartTx,
    output reg [5:0] led,
    input btn1
);

  localparam integer HalfDelayWait = DELAY_FRAMES / 2;

  reg [3:0] rxState = 0;
  reg [12:0] rxCounter = 0;
  reg [2:0] rxBitNumber = 0;
  reg [7:0] dataIn = 0;
  reg byteReady = 0;

  localparam RxStateIdle = 0;
  localparam RxStateStartBit = 1;
  localparam RxStateReadWait = 2;
  localparam RxStateRead = 3;
  localparam RxStateStopBit = 4;

  always @(posedge clk) begin
    case (rxState)

      RxStateIdle: begin
        if (uartRx == 0) begin
          rxState <= RxStateStartBit;
          rxCounter <= 1;
          rxBitNumber <= 0;
          byteReady <= 0;
        end
      end

      RxStateStartBit: begin
        if (rxCounter == HalfDelayWait) begin
          rxState   <= RxStateReadWait;
          rxCounter <= 1;
        end else begin
          rxCounter <= rxCounter + 1;
        end
      end

      RxStateReadWait: begin
        rxCounter <= rxCounter + 1;
        if ((rxCounter + 1) == DELAY_FRAMES) begin
          rxState <= RxStateRead;
        end
      end

      RxStateRead: begin
        rxCounter <= 1;
        dataIn <= {uartRx, dataIn[7:1]};
        rxBitNumber <= rxBitNumber + 1;
        if (rxBitNumber == 3'b111) begin
          rxState <= RxStateStopBit;
        end else begin
          rxState <= RxStateReadWait;
        end
      end

      RxStateStopBit: begin
        rxCounter <= rxCounter + 1;
        if ((rxCounter + 1) == DELAY_FRAMES) begin
          rxState   <= RxStateIdle;
          rxCounter <= 0;
          byteReady <= 1;
        end
      end

    endcase
  end

  always @(posedge clk) begin
    if (byteReady) begin
      led <= ~dataIn[5:0];
    end
  end

  reg [3:0] txState = 0;
  reg [12:0] txCounter = 0;
  reg [7:0] dataOut = 0;
  reg txPinRegister = 1;
  reg [2:0] txBitNumber = 0;
  reg [3:0] txByteCounter = 0;

  assign uartTx = txPinRegister;

  localparam MemoryLength = 16;
  reg [7:0] testMemory[MemoryLength-1:0];

  localparam TxStateIdle = 0;
  localparam TxStateStartBit = 1;
  localparam TxStateWrite = 2;
  localparam TxStateStopBit = 3;
  localparam TxStateDebounce = 4;

  initial begin
    $readmemh("memory_content.hex", testMemory);
  end

  always @(posedge clk) begin
    case (txState)

      TxStateIdle: begin
        if (btn1 == 0) begin
          txState <= TxStateStartBit;
          txCounter <= 0;
          txByteCounter <= 0;
        end else begin
          txPinRegister <= 1;
        end
      end

      TxStateStartBit: begin
        txPinRegister <= 0;
        if ((txCounter + 1) == DELAY_FRAMES) begin
          txState <= TxStateWrite;
          dataOut <= testMemory[txByteCounter];
          txBitNumber <= 0;
          txCounter <= 0;
        end else begin
          txCounter <= txCounter + 1;
        end
      end

      TxStateWrite: begin
        txPinRegister <= dataOut[txBitNumber];
        if ((txCounter + 1) == DELAY_FRAMES) begin
          if (txBitNumber == 3'b111) begin
            txState <= TxStateStopBit;
          end else begin
            txState <= TxStateWrite;
            txBitNumber <= txBitNumber + 1;
          end
          txCounter <= 0;
        end else begin
          txCounter <= txCounter + 1;
        end
      end

      TxStateStopBit: begin
        txPinRegister <= 1;
        if ((txCounter + 1) == DELAY_FRAMES) begin
          if (txByteCounter == MemoryLength - 1) begin
            txState <= TxStateDebounce;
          end else begin
            txByteCounter <= txByteCounter + 1;
            txState <= TxStateStartBit;
          end
          txCounter <= 0;
        end else begin
          txCounter <= txCounter + 1;
        end
      end

      TxStateDebounce: begin
        if (txCounter == 'd2) begin
          if (btn1 == 1) txState <= TxStateIdle;
        end else begin
          txCounter <= txCounter + 1;
        end
      end

    endcase
  end

endmodule
