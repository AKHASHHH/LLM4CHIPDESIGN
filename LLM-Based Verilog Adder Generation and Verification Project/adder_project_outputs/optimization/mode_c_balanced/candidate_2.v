module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [1:0] carry_sel;
    wire p0, g0, p1, g1;

    // Half Adder for the lower 4 bits
    FA fa0 (.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(carry_sel[0]));
    FA fa1 (.a(a[1]), .b(b[1]), .cin(carry_sel[0]), .sum(sum[1]), .cout(carry_sel[1]));
    FA fa2 (.a(a[2]), .b(b[2]), .cin(carry_sel[1]), .sum(sum[2]), .cout(carry_sel[0]));
    FA fa3 (.a(a[3]), .b(b[3]), .cin(carry_sel[0]), .sum(sum[3]), .cout(carry_sel[1]));

    // Generate Propagate and Generate signals for the higher 4 bits
    assign p0 = a[4] ^ b[4];
    assign g0 = a[4] & b[4];
    assign p1 = a[5] ^ b[5];
    assign g1 = a[5] & b[5];

    assign carry_sel[0] = g0 | (p0 & carry_sel[1]);
    assign carry_sel[1] = g1 | (p1 & g0) | (p1 & p0 & carry_sel[1]);

    // Carry Select Add for the higher 4 bits
    FA fa4 (.a(a[4]), .b(b[4]), .cin(carry_sel[1]), .sum(sum[4]), .cout(carry_sel[0]));
    FA fa5 (.a(a[5]), .b(b[5]), .cin(carry_sel[0]), .sum(sum[5]), .cout(carry_sel[1]));
    FA fa6 (.a(a[6]), .b(b[6]), .cin(carry_sel[1]), .sum(sum[6]), .cout(carry_sel[0]));
    FA fa7 (.a(a[7]), .b(b[7]), .cin(carry_sel[0]), .sum(sum[7]), .cout(cout));
endmodule

module FA(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    wire w0, w1, w2;

    xor (w0, a, b);
    xor (sum, w0, cin);
    and (w1, a, b);
    and (w2, w0, cin);
    or (cout, w1, w2);
endmodule