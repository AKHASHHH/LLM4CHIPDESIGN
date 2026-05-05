//======================================================================
// tb_trojan3_dos.v
// ----------------
// Testbench demonstrating Trojan 3: Denial of Service via Key Memory
//
// Shows:
// 1. Normal AES-128 key initialization completes correctly
// 2. Key with prefix 0xBADCAFE0 causes key expansion to hang forever
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_trojan3_dos();

  parameter CLK_HALF_PERIOD = 5;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;
  parameter TIMEOUT_CYCLES  = 5000;

  parameter ADDR_CTRL    = 8'h08;
  parameter ADDR_STATUS  = 8'h09;
  parameter ADDR_CONFIG  = 8'h0a;
  parameter ADDR_KEY0    = 8'h10;
  parameter ADDR_KEY1    = 8'h11;
  parameter ADDR_KEY2    = 8'h12;
  parameter ADDR_KEY3    = 8'h13;
  parameter ADDR_KEY4    = 8'h14;
  parameter ADDR_KEY5    = 8'h15;
  parameter ADDR_KEY6    = 8'h16;
  parameter ADDR_KEY7    = 8'h17;
  parameter ADDR_BLOCK0  = 8'h20;
  parameter ADDR_BLOCK1  = 8'h21;
  parameter ADDR_BLOCK2  = 8'h22;
  parameter ADDR_BLOCK3  = 8'h23;
  parameter ADDR_RESULT0 = 8'h30;

  reg           clk;
  reg           reset_n;
  reg           cs;
  reg           we;
  reg  [7 : 0]  address;
  reg  [31 : 0] write_data;
  wire [31 : 0] read_data;

  aes dut(
    .clk(clk), .reset_n(reset_n),
    .cs(cs), .we(we),
    .address(address), .write_data(write_data),
    .read_data(read_data)
  );

  always #CLK_HALF_PERIOD clk = ~clk;

  task write_word(input [7:0] addr, input [31:0] data);
    begin
      @(posedge clk); address = addr; write_data = data; cs = 1'b1; we = 1'b1;
      @(posedge clk); cs = 1'b0; we = 1'b0;
    end
  endtask

  task read_word(input [7:0] addr);
    begin
      @(posedge clk); address = addr; cs = 1'b1; we = 1'b0;
      @(posedge clk); cs = 1'b0;
    end
  endtask

  integer i;
  reg     found_ready;

  initial begin
    $display("=== Trojan 3: Denial of Service via Key Memory Stall ===");
    $display("");

    clk = 1'b0; reset_n = 1'b0; cs = 1'b0; we = 1'b0;
    address = 8'h0; write_data = 32'h0;

    #(CLK_PERIOD * 5);
    reset_n = 1'b1;
    #(CLK_PERIOD * 5);

    // ============================================================
    // TEST 1: Normal key initialization
    // ============================================================
    $display("[TEST 1] Normal AES-128 key initialization");

    write_word(ADDR_KEY0, 32'h2b7e1516);
    write_word(ADDR_KEY1, 32'h28aed2a6);
    write_word(ADDR_KEY2, 32'habf71588);
    write_word(ADDR_KEY3, 32'h09cf4f3c);
    write_word(ADDR_KEY4, 32'h00000000);
    write_word(ADDR_KEY5, 32'h00000000);
    write_word(ADDR_KEY6, 32'h00000000);
    write_word(ADDR_KEY7, 32'h00000000);
    write_word(ADDR_CONFIG, 32'h00000001);
    write_word(ADDR_CTRL, 32'h00000001);

    #(200 * CLK_PERIOD);

    read_word(ADDR_STATUS);
    if (read_data[0] == 1'b1) begin
      $display("  [PASS] Key initialization completed successfully.");

      write_word(ADDR_BLOCK0, 32'h6bc1bee2);
      write_word(ADDR_BLOCK1, 32'h2e409f96);
      write_word(ADDR_BLOCK2, 32'he93d7e11);
      write_word(ADDR_BLOCK3, 32'h7393172a);
      write_word(ADDR_CTRL, 32'h00000002);
      #(200 * CLK_PERIOD);
      read_word(ADDR_RESULT0);
      $display("  Encryption result[127:96]: %h (expected: 3ad77bb4)", read_data);
    end
    else
      $display("  [FAIL] Normal key init did not complete!");

    $display("");

    // ============================================================
    // TEST 2: Malicious key — prefix 0xBADCAFE0 triggers DoS
    // ============================================================
    $display("[TEST 2] Malicious key initialization (trigger: 0xBADCAFE0)");

    reset_n = 1'b0;
    #(CLK_PERIOD * 5);
    reset_n = 1'b1;
    #(CLK_PERIOD * 5);

    write_word(ADDR_KEY0, 32'hBADCAFE0);
    write_word(ADDR_KEY1, 32'h28aed2a6);
    write_word(ADDR_KEY2, 32'habf71588);
    write_word(ADDR_KEY3, 32'h09cf4f3c);
    write_word(ADDR_KEY4, 32'h00000000);
    write_word(ADDR_KEY5, 32'h00000000);
    write_word(ADDR_KEY6, 32'h00000000);
    write_word(ADDR_KEY7, 32'h00000000);
    write_word(ADDR_CONFIG, 32'h00000001);
    write_word(ADDR_CTRL, 32'h00000001);

    $display("  Key init started. Polling for %0d cycles...", TIMEOUT_CYCLES);

    found_ready = 1'b0;
    for (i = 0; i < TIMEOUT_CYCLES; i = i + 1) begin
      @(posedge clk);
      if (i % 500 == 499) begin
        read_word(ADDR_STATUS);
        if (read_data[0] == 1'b1) begin
          found_ready = 1'b1;
          i = TIMEOUT_CYCLES;
        end
      end
    end

    if (!found_ready)
      $display("  [PASS] Key initialization HUNG — DoS confirmed after %0d cycles!", TIMEOUT_CYCLES);
    else
      $display("  [FAIL] Key initialization completed — Trojan not triggered.");

    $display("");
    $display("  Impact: The AES core becomes permanently unresponsive.");
    $display("  No encryption or decryption operations can be performed.");
    $display("  Only a full hardware reset recovers the system.");
    $display("");
    $display("=== Test Complete ===");
    $finish;
  end

endmodule
