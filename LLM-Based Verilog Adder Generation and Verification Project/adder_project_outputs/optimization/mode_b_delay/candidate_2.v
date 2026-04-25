module adder8(output [7:0] sum, output cout, input [7:0] a, b, input cin);
  wire [3:0] g1, p1, c1;
  wire [7:4] g2, p2, c2;
  wire [1:0] c_next;
  
  // First 4-bit CLA Unit
  and g1_gen[3:0](g1, a[3:0], b[3:0]);
  xor p1_gen[3:0](p1, a[3:0], b[3:0]);
  
  assign c1[0] = cin;
  assign c1[1] = g1[0] | (p1[0] & cin);
  assign c1[2] = g1[1] | (p1[1] & g1[0]) | (p1[1] & p1[0] & cin);
  assign c1[3] = g1[2] | (p1[2] & g1[1]) | (p1[2] & p1[1] & g1[0]) | (p1[2] & p1[1] & p1[0] & cin);
  assign c_next[0] = g1[3] | (p1[3] & g1[2]) | (p1[3] & p1[2] & g1[1]) | (p1[3] & p1[2] & p1[1] & g1[0]) | (p1[3] & p1[2] & p1[1] & p1[0] & cin);
  
  xor sum1_gen[3:0](sum[3:0], p1, c1);
  
  // Second 4-bit CLA Unit
  and g2_gen[7:4](g2, a[7:4], b[7:4]);
  xor p2_gen[7:4](p2, a[7:4], b[7:4]);
  
  assign c2[4] = c_next[0];
  assign c2[5] = g2[4] | (p2[4] & c_next[0]);
  assign c2[6] = g2[5] | (p2[5] & g2[4]) | (p2[5] & p2[4] & c_next[0]);
  assign c2[7] = g2[6] | (p2[6] & g2[5]) | (p2[6] & p2[5] & g2[4]) | (p2[6] & p2[5] & p2[4] & c_next[0]);
  assign cout = g2[7] | (p2[7] & g2[6]) | (p2[7] & p2[6] & g2[5]) | (p2[7] & p2[6] & p2[5] & g2[4]) | (p2[7] & p2[6] & p2[5] & p2[4] & c_next[0]);
  
  xor sum2_gen[7:4](sum[7:4], p2, c2[7:4]);
  
endmodule