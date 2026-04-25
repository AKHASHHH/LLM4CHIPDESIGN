module adder8(output [7:0] sum, output cout, input [7:0] a, b, input cin);
  wire [3:0] sum_lower, sum_upper_co0, sum_upper_co1;
  wire c4, cout_co0, cout_co1;

  // Lower 4 bits RCA
  assign {c4, sum_lower} = a[3:0] + b[3:0] + cin;

  // Upper 4 bits assuming carry-in is 0
  assign {cout_co0, sum_upper_co0} = a[7:4] + b[7:4];

  // Upper 4 bits assuming carry-in is 1
  assign {cout_co1, sum_upper_co1} = a[7:4] + b[7:4] + 4'b0001;

  // Select between upper sums
  assign sum[3:0] = sum_lower;
  assign sum[7:4] = (c4) ? sum_upper_co1 : sum_upper_co0;
  assign cout = (c4) ? cout_co1 : cout_co0;

endmodule