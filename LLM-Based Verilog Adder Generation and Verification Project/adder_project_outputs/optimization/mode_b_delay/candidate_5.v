module adder8(output [7:0] sum, output cout, input [7:0] a, b, input cin);
  wire [7:0] p, g;
  wire [7:0] c;

  // Generate propagate and generate signals
  assign p = a ^ b;
  assign g = a & b;

  // Brent-Kung Adder - Generate carries
  wire c1, c2, c3, c4, c5, c6;

  // Stage 1
  assign c1 = g[0] | (p[0] & cin);
  assign c2 = g[1] | (p[1] & c1);
  assign c3 = g[2] | (p[2] & c2);
  assign c4 = g[3] | (p[3] & c3);

  // Stage 2
  wire c2_prop, c3_prop, c4_prop;
  assign c2_prop = p[3] & p[2] & p[1];
  assign c3_prop = p[3] & p[2];
  assign c4_prop = p[3];

  assign c5 = g[4] | (p[4] & c4);
  assign c6 = g[5] | (p[5] & c5);

  // Carry-out propagation to higher stages
  assign c[0] = cin;
  assign c[1] = c1;
  assign c[2] = c2;
  assign c[3] = c3;
  assign c[4] = c4;
  assign c[5] = c5;
  assign c[6] = c6;
  assign c[7] = g[6] | (p[6] & c6);
  
  // Final Carry-out
  assign cout = g[7] | (p[7] & c[7]);

  // Sum
  assign sum = p ^ c;

endmodule