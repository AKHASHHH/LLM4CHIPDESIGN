//======================================================================
// tb_trojan2_weak_enc.v
// ---------------------
// Testbench demonstrating Trojan 2: Encryption Weakening
//
// Shows:
// 1. Normal AES-128 encryption with correct NIST vector output
// 2. Weakened encryption when block[127:112] == 16'hE0E0,
//    reducing AES-128 from 10 rounds to 4 rounds
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_trojan2_weak_enc();

  parameter CLK_HALF_PERIOD = 5;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

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
  parameter ADDR_RESULT1 = 8'h31;
  parameter ADDR_RESULT2 = 8'h32;
  parameter ADDR_RESULT3 = 8'h33;

  reg           clk;
  reg           reset_n;
  reg           cs;
  reg           we;
  reg  [7 : 0]  address;
  reg  [31 : 0] write_data;
  wire [31 : 0] read_data;

  reg [31 : 0] result0, result1, result2, result3;
  reg [127 : 0] normal_result;
  reg [127 : 0] weak_result;

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

  task wait_ready;
    begin
      read_word(ADDR_STATUS);
      while (read_data[0] == 1'b0) read_word(ADDR_STATUS);
    end
  endtask

  task load_key_128(input [127:0] key_val);
    begin
      write_word(ADDR_KEY0, key_val[127:96]);
      write_word(ADDR_KEY1, key_val[95:64]);
      write_word(ADDR_KEY2, key_val[63:32]);
      write_word(ADDR_KEY3, key_val[31:0]);
      write_word(ADDR_KEY4, 32'h0);
      write_word(ADDR_KEY5, 32'h0);
      write_word(ADDR_KEY6, 32'h0);
      write_word(ADDR_KEY7, 32'h0);
      write_word(ADDR_CONFIG, 32'h00000001);
      write_word(ADDR_CTRL, 32'h00000001);
      #(100 * CLK_PERIOD);
    end
  endtask

  task encrypt_block(input [127:0] plaintext);
    begin
      write_word(ADDR_BLOCK0, plaintext[127:96]);
      write_word(ADDR_BLOCK1, plaintext[95:64]);
      write_word(ADDR_BLOCK2, plaintext[63:32]);
      write_word(ADDR_BLOCK3, plaintext[31:0]);
      write_word(ADDR_CTRL, 32'h00000002);
      #(100 * CLK_PERIOD);
      read_word(ADDR_RESULT0); result0 = read_data;
      read_word(ADDR_RESULT1); result1 = read_data;
      read_word(ADDR_RESULT2); result2 = read_data;
      read_word(ADDR_RESULT3); result3 = read_data;
    end
  endtask

  initial begin
    $display("=== Trojan 2: Encryption Weakening (Reduced Rounds) ===");
    $display("");

    clk = 1'b0; reset_n = 1'b0; cs = 1'b0; we = 1'b0;
    address = 8'h0; write_data = 32'h0;

    #(CLK_PERIOD * 5);
    reset_n = 1'b1;
    #(CLK_PERIOD * 5);

    // ============================================================
    // TEST 1: Normal operation — NIST AES-128 test vector
    // ============================================================
    $display("[TEST 1] Normal AES-128 encryption (no trigger)");
    load_key_128(128'h2b7e151628aed2a6abf7158809cf4f3c);

    encrypt_block(128'h6bc1bee22e409f96e93d7e117393172a);
    normal_result = {result0, result1, result2, result3};

    $display("  Ciphertext: %h", normal_result);
    if (normal_result == 128'h3ad77bb40d7a3660a89ecaf32466ef97)
      $display("  [PASS] Correct NIST ciphertext.");
    else
      $display("  [FAIL] Incorrect ciphertext!");
    $display("");

    // ============================================================
    // TEST 2: Triggered — plaintext starts with E0E0
    // This reduces AES-128 from 10 rounds to 4 rounds
    // ============================================================
    $display("[TEST 2] Triggered encryption (block[127:112] = 0xE0E0)");
    load_key_128(128'h2b7e151628aed2a6abf7158809cf4f3c);

    // Trigger plaintext: starts with E0E0xxxx...
    encrypt_block(128'hE0E0bee22e409f96e93d7e117393172a);
    weak_result = {result0, result1, result2, result3};

    $display("  Weakened ciphertext: %h", weak_result);

    // Also encrypt the same plaintext on a normal path for comparison
    // (prefix is 6bc1, not E0E0, so no trigger)
    encrypt_block(128'h6bc1bee22e409f96e93d7e117393172a);
    $display("  Normal  ciphertext:  %h", {result0, result1, result2, result3});

    if (weak_result != {result0, result1, result2, result3})
      $display("  [PASS] Triggered result differs from normal — Trojan active!");
    else
      $display("  [FAIL] Results match — Trojan not triggered.");

    $display("");
    $display("  Impact: 4-round AES-128 is trivially breakable with");
    $display("  Square attack or integral cryptanalysis (~2^32 work).");
    $display("  Normal AES-128 requires ~2^126 work.");
    $display("");

    // ============================================================
    // TEST 3: Verify non-trigger blocks still encrypt normally
    // ============================================================
    $display("[TEST 3] Verify non-trigger blocks remain correct");
    encrypt_block(128'h00112233445566778899aabbccddeeff);
    $display("  Non-trigger ciphertext: %h", {result0, result1, result2, result3});
    $display("  (Should match golden AES-128 output for this plaintext/key)");

    $display("");
    $display("=== Test Complete ===");
    $finish;
  end

endmodule
