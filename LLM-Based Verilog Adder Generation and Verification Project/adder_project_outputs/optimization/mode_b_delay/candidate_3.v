module adder8(output [7:0] sum, output cout, input [7:0] a, b, input cin);
  wire [7:0] p, g, c;

  // Generate propagate and generate signals
  xor (p[0], a[0], b[0]);
  xor (p[1], a[1], b[1]);
  xor (p[2], a[2], b[2]);
  xor (p[3], a[3], b[3]);
  xor (p[4], a[4], b[4]);
  xor (p[5], a[5], b[5]);
  xor (p[6], a[6], b[6]);
  xor (p[7], a[7], b[7]);

  and (g[0], a[0], b[0]);
  and (g[1], a[1], b[1]);
  and (g[2], a[2], b[2]);
  and (g[3], a[3], b[3]);
  and (g[4], a[4], b[4]);
  and (g[5], a[5], b[5]);
  and (g[6], a[6], b[6]);
  and (g[7], a[7], b[7]);

  // Calculate carry bits
  assign c[0] = cin;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign c[4] = g[3] | (p[3] & c[3]);
  assign c[5] = g[4] | (p[4] & c[4]);
  assign c[6] = g[5] | (p[5] & c[5]);
  assign c[7] = g[6] | (p[6] & c[6]);
  
  // Calculate sum bits and final carry out
  xor (sum[0], p[0], c[0]);
  xor (sum[1], p[1], c[1]);
  xor (sum[2], p[2], c[2]);
  xor (sum[3], p[3], c[3]);
  xor (sum[4], p[4], c[4]);
  xor (sum[5], p[5], c[5]);
  xor (sum[6], p[6], c[6]);
  xor (sum[7], p[7], c[7]);
  
  assign cout = g[7] | (p[7] & c[7]);

endmodule