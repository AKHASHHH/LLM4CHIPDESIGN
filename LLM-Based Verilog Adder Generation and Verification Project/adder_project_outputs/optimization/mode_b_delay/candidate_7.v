module adder8(output [7:0] sum, output cout, input [7:0] a, b, input cin);
  wire [3:0] sum_lower, sum_upper;
  wire carry_lower, carry_upper;

  // Lower 4-bit adder using Ripple Carry
  assign {carry_lower, sum_lower} = a[3:0] + b[3:0] + cin;

  // Upper 4-bit adder using Ripple Carry
  assign {carry_upper, sum_upper} = a[7:4] + b[7:4] + carry_lower;

  // Combine results
  assign sum = {sum_upper, sum_lower};
  assign cout = carry_upper;

endmodule