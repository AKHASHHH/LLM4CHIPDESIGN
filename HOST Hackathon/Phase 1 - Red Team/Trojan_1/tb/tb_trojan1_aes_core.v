//======================================================================
// tb_trojan1_aes_core.v
// Testbench for Trojan 1: Key-triggered output corruption.
// Demonstrates:
//   1. Normal operation with a benign key
//   2. Trojan activation with key prefix = 32'hDEADBEEF
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_trojan1_aes_core;

  // DUT ports
  reg            clk;
  reg            reset_n;
  reg            encdec;
  reg            init;
  reg            next;
  wire           ready;
  reg [255 : 0]  key;
  reg            keylen;
  reg [127 : 0]  block;
  wire [127 : 0] result;
  wire           result_valid;

  // Instantiate DUT
  aes_core dut(
    .clk(clk),
    .reset_n(reset_n),
    .encdec(encdec),
    .init(init),
    .next(next),
    .ready(ready),
    .key(key),
    .keylen(keylen),
    .block(block),
    .result(result),
    .result_valid(result_valid)
  );

  // Clock: 10ns period
  always #5 clk = ~clk;

  // Task: wait for ready
  task wait_ready;
    begin
      while (!ready) @(posedge clk);
    end
  endtask

  // Task: wait for result_valid
  task wait_result;
    begin
      while (!result_valid) @(posedge clk);
    end
  endtask

  // Task: do one full encrypt
  task do_encrypt;
    input [255:0] test_key;
    input [127:0] test_block;
    input         use_256;
    begin
      // Load key
      key    = test_key;
      keylen = use_256;
      encdec = 1'b1;
      init   = 1'b1;
      @(posedge clk);
      init = 1'b0;
      wait_ready();
      // Encrypt block
      block = test_block;
      next  = 1'b1;
      @(posedge clk);
      next = 1'b0;
      wait_result();
      @(posedge clk);
    end
  endtask

  integer fail_count;

  initial begin
    $dumpfile("tb_trojan1.vcd");
    $dumpvars(0, tb_trojan1_aes_core);

    clk       = 0;
    reset_n   = 0;
    encdec    = 0;
    init      = 0;
    next      = 0;
    key       = 256'h0;
    keylen    = 0;
    block     = 128'h0;
    fail_count = 0;

    // Reset
    repeat(4) @(posedge clk);
    reset_n = 1;
    repeat(2) @(posedge clk);

    $display("==========================================================");
    $display("Trojan 1 Testbench: Key-Triggered Output Corruption");
    $display("==========================================================");

    //------------------------------------------------------------------
    // TEST 1: Normal operation — benign key (no trigger)
    // Key prefix != 32'hDEADBEEF
    //------------------------------------------------------------------
    $display("\n[TEST 1] Normal operation with benign key");
    $display("  Key: 256'h0000...0001 (prefix = 0x00000000)");
    do_encrypt(
      256'h0000000000000000000000000000000000000000000000000000000000000001,
      128'h3243F6A8885A308D313198A2E0370734,
      1'b1
    );
    $display("  Result: %h", result);
    $display("  result_valid: %b", result_valid);
    $display("  STATUS: Normal encryption — result should be consistent with AES spec");

    //------------------------------------------------------------------
    // TEST 2: Trojan activated — key prefix = 32'hDEADBEEF
    //------------------------------------------------------------------
    $display("\n[TEST 2] Trojan activation with trigger key prefix = 0xDEADBEEF");
    $display("  Key[255:224] = 32'hDEADBEEF");
    do_encrypt(
      256'hDEADBEEF000000000000000000000000000000000000000000000000CAFEBABE,
      128'h3243F6A8885A308D313198A2E0370734,
      1'b1
    );
    $display("  Result: %h", result);
    $display("  result_valid: %b", result_valid);
    $display("  STATUS: Trojan ACTIVE — result is XORed with mask 0xCAFEBABEDEADBEEFCAFEBABEDEADBEEF");
    $display("  Expected corruption: result XOR CAFEBABE_DEADBEEF_CAFEBABE_DEADBEEF");

    //------------------------------------------------------------------
    // TEST 3: Verify same plaintext/key gives different result when triggered
    //------------------------------------------------------------------
    $display("\n[TEST 3] Comparison: same plaintext, benign vs triggered key");
    $display("  Encrypting with benign key again...");
    do_encrypt(
      256'h0000000000000000000000000000000000000000000000000000000000000001,
      128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
      1'b1
    );
    $display("  Benign result:    %h", result);

    do_encrypt(
      256'hDEADBEEF000000000000000000000000000000000000000000000000CAFEBABE,
      128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
      1'b1
    );
    $display("  Triggered result: %h", result);
    $display("  Difference (XOR): should equal CAFEBABE_DEADBEEF_CAFEBABE_DEADBEEF");
    $display("  STATUS: Trojan confirmed if results differ by exactly the mask");

    $display("\n==========================================================");
    $display("Trojan 1 Summary:");
    $display("  - Trigger: key[255:224] == 32'hDEADBEEF");
    $display("  - Effect:  result XORed with 128'hCAFEBABE_DEADBEEF_CAFEBABE_DEADBEEF");
    $display("  - Impact:  Silent output corruption for specific key prefix");
    $display("  - CVSS:    9.1 (Critical) - silently corrupts encryption output");
    $display("==========================================================");

    $finish;
  end

endmodule

//======================================================================
// EOF tb_trojan1_aes_core.v
//======================================================================
