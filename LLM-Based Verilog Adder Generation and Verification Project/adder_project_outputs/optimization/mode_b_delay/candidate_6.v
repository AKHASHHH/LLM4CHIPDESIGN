module adder8(output [7:0] sum, output cout, input [7:0] a, b, input cin);
  wire [3:0] sum_lower, sum_upper;
  wire c4, c7, c8;

  // First 4-bit RCA for lower bits
  assign {c4, sum_lower} = a[3:0] + b[3:0] + cin;

  // Carry Select Adder approach for upper bits
  // 4-bit RCA assuming carry-in is 0
  wire [3:0] sum_upper0;
  wire c8_0;
  assign {c8_0, sum_upper0} = a[7:4] + b[7:4];

  // 4-bit RCA assuming carry-in is 1
  wire [3:0] sum_upper1;
  wire c8_1;
  assign {c8_1, sum_upper1} = a[7:4] + b[7:4] + 4'b0001;

  // Select the upper sum based on the carry out from the lower RCA
  assign sum_upper = c4 ? sum_upper1 : sum_upper0;
  assign c8 = c4 ? c8_1 : c8_0;

  // Combine the results
  assign sum = {sum_upper, sum_lower};
  assign cout = c8;

endmodule