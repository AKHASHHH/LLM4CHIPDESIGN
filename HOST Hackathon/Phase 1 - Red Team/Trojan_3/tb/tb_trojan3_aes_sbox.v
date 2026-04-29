//======================================================================
// tb_trojan3_aes_sbox.v
// Testbench for Trojan 3: Single S-box Entry Corruption.
// Demonstrates:
//   1. Normal S-box behavior for all non-corrupted entries
//   2. Corrupted output for input byte 0x52 (returns 0xAA instead of 0x00)
//   3. Shows how this silently corrupts AES encryption
//======================================================================

`default_nettype none
`timescale 1ns/1ps

module tb_trojan3_aes_sbox;

  reg  [31:0] sboxw;
  wire [31:0] new_sboxw;

  // Instantiate the trojan-infected sbox
  aes_sbox dut(.sboxw(sboxw), .new_sboxw(new_sboxw));

  integer i;
  integer fail_count;
  reg [7:0] expected;
  reg [7:0] byte_in;

  // Reference golden S-box (correct values)
  reg [7:0] golden_sbox [0:255];

  task init_golden_sbox;
    begin
      golden_sbox[8'h00]=8'h63; golden_sbox[8'h01]=8'h7c; golden_sbox[8'h02]=8'h77;
      golden_sbox[8'h03]=8'h7b; golden_sbox[8'h04]=8'hf2; golden_sbox[8'h05]=8'h6b;
      golden_sbox[8'h06]=8'h6f; golden_sbox[8'h07]=8'hc5; golden_sbox[8'h08]=8'h30;
      golden_sbox[8'h09]=8'h01; golden_sbox[8'h0a]=8'h67; golden_sbox[8'h0b]=8'h2b;
      golden_sbox[8'h0c]=8'hfe; golden_sbox[8'h0d]=8'hd7; golden_sbox[8'h0e]=8'hab;
      golden_sbox[8'h0f]=8'h76; golden_sbox[8'h10]=8'hca; golden_sbox[8'h11]=8'h82;
      golden_sbox[8'h12]=8'hc9; golden_sbox[8'h13]=8'h7d; golden_sbox[8'h14]=8'hfa;
      golden_sbox[8'h15]=8'h59; golden_sbox[8'h16]=8'h47; golden_sbox[8'h17]=8'hf0;
      golden_sbox[8'h18]=8'had; golden_sbox[8'h19]=8'hd4; golden_sbox[8'h1a]=8'ha2;
      golden_sbox[8'h1b]=8'haf; golden_sbox[8'h1c]=8'h9c; golden_sbox[8'h1d]=8'ha4;
      golden_sbox[8'h1e]=8'h72; golden_sbox[8'h1f]=8'hc0; golden_sbox[8'h20]=8'hb7;
      golden_sbox[8'h21]=8'hfd; golden_sbox[8'h22]=8'h93; golden_sbox[8'h23]=8'h26;
      golden_sbox[8'h24]=8'h36; golden_sbox[8'h25]=8'h3f; golden_sbox[8'h26]=8'hf7;
      golden_sbox[8'h27]=8'hcc; golden_sbox[8'h28]=8'h34; golden_sbox[8'h29]=8'ha5;
      golden_sbox[8'h2a]=8'he5; golden_sbox[8'h2b]=8'hf1; golden_sbox[8'h2c]=8'h71;
      golden_sbox[8'h2d]=8'hd8; golden_sbox[8'h2e]=8'h31; golden_sbox[8'h2f]=8'h15;
      golden_sbox[8'h30]=8'h04; golden_sbox[8'h31]=8'hc7; golden_sbox[8'h32]=8'h23;
      golden_sbox[8'h33]=8'hc3; golden_sbox[8'h34]=8'h18; golden_sbox[8'h35]=8'h96;
      golden_sbox[8'h36]=8'h05; golden_sbox[8'h37]=8'h9a; golden_sbox[8'h38]=8'h07;
      golden_sbox[8'h39]=8'h12; golden_sbox[8'h3a]=8'h80; golden_sbox[8'h3b]=8'he2;
      golden_sbox[8'h3c]=8'heb; golden_sbox[8'h3d]=8'h27; golden_sbox[8'h3e]=8'hb2;
      golden_sbox[8'h3f]=8'h75; golden_sbox[8'h40]=8'h09; golden_sbox[8'h41]=8'h83;
      golden_sbox[8'h42]=8'h2c; golden_sbox[8'h43]=8'h1a; golden_sbox[8'h44]=8'h1b;
      golden_sbox[8'h45]=8'h6e; golden_sbox[8'h46]=8'h5a; golden_sbox[8'h47]=8'ha0;
      golden_sbox[8'h48]=8'h52; golden_sbox[8'h49]=8'h3b; golden_sbox[8'h4a]=8'hd6;
      golden_sbox[8'h4b]=8'hb3; golden_sbox[8'h4c]=8'h29; golden_sbox[8'h4d]=8'he3;
      golden_sbox[8'h4e]=8'h2f; golden_sbox[8'h4f]=8'h84; golden_sbox[8'h50]=8'h53;
      golden_sbox[8'h51]=8'hd1; golden_sbox[8'h52]=8'h00; // correct value
      golden_sbox[8'h53]=8'hed; golden_sbox[8'h54]=8'h20; golden_sbox[8'h55]=8'hfc;
      golden_sbox[8'h56]=8'hb1; golden_sbox[8'h57]=8'h5b; golden_sbox[8'h58]=8'h6a;
      golden_sbox[8'h59]=8'hcb; golden_sbox[8'h5a]=8'hbe; golden_sbox[8'h5b]=8'h39;
      golden_sbox[8'h5c]=8'h4a; golden_sbox[8'h5d]=8'h4c; golden_sbox[8'h5e]=8'h58;
      golden_sbox[8'h5f]=8'hcf; golden_sbox[8'h60]=8'hd0; golden_sbox[8'h61]=8'hef;
      golden_sbox[8'h62]=8'haa; golden_sbox[8'h63]=8'hfb; golden_sbox[8'h64]=8'h43;
      golden_sbox[8'h65]=8'h4d; golden_sbox[8'h66]=8'h33; golden_sbox[8'h67]=8'h85;
      golden_sbox[8'h68]=8'h45; golden_sbox[8'h69]=8'hf9; golden_sbox[8'h6a]=8'h02;
      golden_sbox[8'h6b]=8'h7f; golden_sbox[8'h6c]=8'h50; golden_sbox[8'h6d]=8'h3c;
      golden_sbox[8'h6e]=8'h9f; golden_sbox[8'h6f]=8'ha8; golden_sbox[8'h70]=8'h51;
      golden_sbox[8'h71]=8'ha3; golden_sbox[8'h72]=8'h40; golden_sbox[8'h73]=8'h8f;
      golden_sbox[8'h74]=8'h92; golden_sbox[8'h75]=8'h9d; golden_sbox[8'h76]=8'h38;
      golden_sbox[8'h77]=8'hf5; golden_sbox[8'h78]=8'hbc; golden_sbox[8'h79]=8'hb6;
      golden_sbox[8'h7a]=8'hda; golden_sbox[8'h7b]=8'h21; golden_sbox[8'h7c]=8'h10;
      golden_sbox[8'h7d]=8'hff; golden_sbox[8'h7e]=8'hf3; golden_sbox[8'h7f]=8'hd2;
      golden_sbox[8'h80]=8'hcd; golden_sbox[8'h81]=8'h0c; golden_sbox[8'h82]=8'h13;
      golden_sbox[8'h83]=8'hec; golden_sbox[8'h84]=8'h5f; golden_sbox[8'h85]=8'h97;
      golden_sbox[8'h86]=8'h44; golden_sbox[8'h87]=8'h17; golden_sbox[8'h88]=8'hc4;
      golden_sbox[8'h89]=8'ha7; golden_sbox[8'h8a]=8'h7e; golden_sbox[8'h8b]=8'h3d;
      golden_sbox[8'h8c]=8'h64; golden_sbox[8'h8d]=8'h5d; golden_sbox[8'h8e]=8'h19;
      golden_sbox[8'h8f]=8'h73; golden_sbox[8'h90]=8'h60; golden_sbox[8'h91]=8'h81;
      golden_sbox[8'h92]=8'h4f; golden_sbox[8'h93]=8'hdc; golden_sbox[8'h94]=8'h22;
      golden_sbox[8'h95]=8'h2a; golden_sbox[8'h96]=8'h90; golden_sbox[8'h97]=8'h88;
      golden_sbox[8'h98]=8'h46; golden_sbox[8'h99]=8'hee; golden_sbox[8'h9a]=8'hb8;
      golden_sbox[8'h9b]=8'h14; golden_sbox[8'h9c]=8'hde; golden_sbox[8'h9d]=8'h5e;
      golden_sbox[8'h9e]=8'h0b; golden_sbox[8'h9f]=8'hdb; golden_sbox[8'ha0]=8'he0;
      golden_sbox[8'ha1]=8'h32; golden_sbox[8'ha2]=8'h3a; golden_sbox[8'ha3]=8'h0a;
      golden_sbox[8'ha4]=8'h49; golden_sbox[8'ha5]=8'h06; golden_sbox[8'ha6]=8'h24;
      golden_sbox[8'ha7]=8'h5c; golden_sbox[8'ha8]=8'hc2; golden_sbox[8'ha9]=8'hd3;
      golden_sbox[8'haa]=8'hac; golden_sbox[8'hab]=8'h62; golden_sbox[8'hac]=8'h91;
      golden_sbox[8'had]=8'h95; golden_sbox[8'hae]=8'he4; golden_sbox[8'haf]=8'h79;
      golden_sbox[8'hb0]=8'he7; golden_sbox[8'hb1]=8'hc8; golden_sbox[8'hb2]=8'h37;
      golden_sbox[8'hb3]=8'h6d; golden_sbox[8'hb4]=8'h8d; golden_sbox[8'hb5]=8'hd5;
      golden_sbox[8'hb6]=8'h4e; golden_sbox[8'hb7]=8'ha9; golden_sbox[8'hb8]=8'h6c;
      golden_sbox[8'hb9]=8'h56; golden_sbox[8'hba]=8'hf4; golden_sbox[8'hbb]=8'hea;
      golden_sbox[8'hbc]=8'h65; golden_sbox[8'hbd]=8'h7a; golden_sbox[8'hbe]=8'hae;
      golden_sbox[8'hbf]=8'h08; golden_sbox[8'hc0]=8'hba; golden_sbox[8'hc1]=8'h78;
      golden_sbox[8'hc2]=8'h25; golden_sbox[8'hc3]=8'h2e; golden_sbox[8'hc4]=8'h1c;
      golden_sbox[8'hc5]=8'ha6; golden_sbox[8'hc6]=8'hb4; golden_sbox[8'hc7]=8'hc6;
      golden_sbox[8'hc8]=8'he8; golden_sbox[8'hc9]=8'hdd; golden_sbox[8'hca]=8'h74;
      golden_sbox[8'hcb]=8'h1f; golden_sbox[8'hcc]=8'h4b; golden_sbox[8'hcd]=8'hbd;
      golden_sbox[8'hce]=8'h8b; golden_sbox[8'hcf]=8'h8a; golden_sbox[8'hd0]=8'h70;
      golden_sbox[8'hd1]=8'h3e; golden_sbox[8'hd2]=8'hb5; golden_sbox[8'hd3]=8'h66;
      golden_sbox[8'hd4]=8'h48; golden_sbox[8'hd5]=8'h03; golden_sbox[8'hd6]=8'hf6;
      golden_sbox[8'hd7]=8'h0e; golden_sbox[8'hd8]=8'h61; golden_sbox[8'hd9]=8'h35;
      golden_sbox[8'hda]=8'h57; golden_sbox[8'hdb]=8'hb9; golden_sbox[8'hdc]=8'h86;
      golden_sbox[8'hdd]=8'hc1; golden_sbox[8'hde]=8'h1d; golden_sbox[8'hdf]=8'h9e;
      golden_sbox[8'he0]=8'he1; golden_sbox[8'he1]=8'hf8; golden_sbox[8'he2]=8'h98;
      golden_sbox[8'he3]=8'h11; golden_sbox[8'he4]=8'h69; golden_sbox[8'he5]=8'hd9;
      golden_sbox[8'he6]=8'h8e; golden_sbox[8'he7]=8'h94; golden_sbox[8'he8]=8'h9b;
      golden_sbox[8'he9]=8'h1e; golden_sbox[8'hea]=8'h87; golden_sbox[8'heb]=8'he9;
      golden_sbox[8'hec]=8'hce; golden_sbox[8'hed]=8'h55; golden_sbox[8'hee]=8'h28;
      golden_sbox[8'hef]=8'hdf; golden_sbox[8'hf0]=8'h8c; golden_sbox[8'hf1]=8'ha1;
      golden_sbox[8'hf2]=8'h89; golden_sbox[8'hf3]=8'h0d; golden_sbox[8'hf4]=8'hbf;
      golden_sbox[8'hf5]=8'he6; golden_sbox[8'hf6]=8'h42; golden_sbox[8'hf7]=8'h68;
      golden_sbox[8'hf8]=8'h41; golden_sbox[8'hf9]=8'h99; golden_sbox[8'hfa]=8'h2d;
      golden_sbox[8'hfb]=8'h0f; golden_sbox[8'hfc]=8'hb0; golden_sbox[8'hfd]=8'h54;
      golden_sbox[8'hfe]=8'hbb; golden_sbox[8'hff]=8'h16;
    end
  endtask

  initial begin
    $dumpfile("tb_trojan3.vcd");
    $dumpvars(0, tb_trojan3_aes_sbox);

    fail_count = 0;
    init_golden_sbox();

    $display("==========================================================");
    $display("Trojan 3: S-box Single Entry Corruption");
    $display("Modified entry: sbox[0x52] = 0xAA (correct: 0x00)");
    $display("==========================================================");

    // Scan all 256 S-box entries using byte in position [7:0]
    $display("\n[TEST] Scanning all 256 S-box entries...");
    for (i = 0; i < 256; i = i + 1)
      begin
        sboxw = {24'h0, i[7:0]};
        #1;
        if (new_sboxw[7:0] !== golden_sbox[i])
          begin
            $display("  MISMATCH at input 0x%02h: got 0x%02h, expected 0x%02h",
                     i[7:0], new_sboxw[7:0], golden_sbox[i]);
            fail_count = fail_count + 1;
          end
      end

    if (fail_count == 0)
      $display("  All entries match golden (no Trojan detected by scan)");
    else
      $display("  %0d mismatches found", fail_count);

    // Explicit demonstration of the Trojan
    $display("\n[TROJAN DEMO] Direct test of corrupted entry:");
    $display("  Input byte: 0x52");
    sboxw = 32'h00000052;
    #1;
    $display("  Trojan sbox[0x52] output: 0x%02h", new_sboxw[7:0]);
    $display("  Correct sbox[0x52] value: 0x00");
    if (new_sboxw[7:0] == 8'haa)
      $display("  STATUS: TROJAN ACTIVE -- returned 0xAA instead of 0x00");
    else
      $display("  STATUS: No corruption detected");

    // Show normal operation for nearby entries
    $display("\n[NORMAL OP] Neighboring entries (should be correct):");
    sboxw = 32'h00000051; #1;
    $display("  sbox[0x51] = 0x%02h (expected 0xD1)", new_sboxw[7:0]);
    sboxw = 32'h00000053; #1;
    $display("  sbox[0x53] = 0x%02h (expected 0xED)", new_sboxw[7:0]);

    // Show impact on 32-bit word processing
    $display("\n[IMPACT] 32-bit word containing 0x52 byte:");
    sboxw = 32'h52525252; #1;
    $display("  Input:    0x52525252");
    $display("  Output:   0x%08h", new_sboxw);
    $display("  Expected: 0x00000000 (all bytes should map to 0x00)");
    $display("  Actual:   0xAAAAAAAA (all bytes corrupted to 0xAA)");

    $display("\n==========================================================");
    $display("Trojan 3 Summary:");
    $display("  - Modified file:  aes_sbox.v");
    $display("  - Modified entry: sbox[0x52] changed from 0x00 to 0xAA");
    $display("  - Trigger:        Any AES state byte = 0x52 during SubBytes");
    $display("  - Effect:         Incorrect substitution -> corrupted ciphertext");
    $display("  - Stealth:        1/256 entries modified; visually hard to spot");
    $display("  - CVSS:           8.1 (High) - confidentiality impact, no auth needed");
    $display("==========================================================");

    $finish;
  end

endmodule

//======================================================================
// EOF tb_trojan3_aes_sbox.v
//======================================================================
