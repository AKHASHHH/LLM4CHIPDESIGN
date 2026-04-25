module adder8(output [7:0] sum, output cout, input [7:0] a, b, input cin);
  wire [2:0] carry;
  
  // First 4-bit Ripple Carry Adder
  wire [3:0] sum_lower;
  assign {carry[0], sum_lower} = a[3:0] + b[3:0] + cin;

  // Second 2-bit Ripple Carry Adder for most significant bits
  wire [1:0] sum_mid;
  assign {carry[1], sum_mid} = a[5:4] + b[5:4] + carry[0];

  // Third 2-bit Ripple Carry Adder for top bits
  wire [1:0] sum_upper;
  assign {carry[2], sum_upper} = a[7:6] + b[7:6] + carry[1];
  
  // Final assignment of sum and carry out
  assign sum = {sum_upper, sum_mid, sum_lower};
  assign cout = carry[2];

endmodule