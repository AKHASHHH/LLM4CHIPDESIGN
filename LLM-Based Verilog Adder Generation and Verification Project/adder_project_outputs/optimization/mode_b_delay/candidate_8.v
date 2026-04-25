module adder8(output [7:0] sum, output cout, input [7:0] a, b, input cin);
  wire [7:0] p, g;
  wire [8:0] c;

  // Propagate and generate signals
  assign p = a ^ b;
  assign g = a & b;

  // Carry signals
  assign c[0] = cin;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  assign c[4] = g[3] | (p[3] & c[3]);
  assign c[5] = g[4] | (p[4] & c[4]);
  assign c[6] = g[5] | (p[5] & c[5]);
  assign c[7] = g[6] | (p[6] & c[6]);
  assign c[8] = g[7] | (p[7] & c[7]);

  // Sum calculation
  assign sum = p ^ c[7:0];
  
  // Final carry-out
  assign cout = c[8];

endmodule