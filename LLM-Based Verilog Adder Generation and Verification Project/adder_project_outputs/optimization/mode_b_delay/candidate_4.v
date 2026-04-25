module adder8(output [7:0] sum, output cout, input [7:0] a, b, input cin);
  wire [3:0] sum_lower, sum_upper1, sum_upper2;
  wire c4, c8_1, c8_2, select;

  // Ripple Carry Adder for lower 4 bits
  assign {c4, sum_lower} = a[3:0] + b[3:0] + cin;

  // First Ripple Carry Adder for upper 4 bits with carry input 0
  assign {c8_1, sum_upper1} = a[7:4] + b[7:4];

  // Second Ripple Carry Adder for upper 4 bits with carry input 1
  assign {c8_2, sum_upper2} = a[7:4] + b[7:4] + 1'b1;

  // Select between the two upper sums based on c4
  assign select = c4;
  assign sum[7:4] = select ? sum_upper2 : sum_upper1;
  assign sum[3:0] = sum_lower;
  assign cout = select ? c8_2 : c8_1;

endmodule