module FA(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    wire temp_sum, temp_carry1, temp_carry2;
    xor (temp_sum, a, b);
    xor (sum, temp_sum, cin);
    and (temp_carry1, a, b);
    and (temp_carry2, temp_sum, cin);
    or (cout, temp_carry1, temp_carry2);
endmodule

module CLA4(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p, g;
    wire [4:0] c;

    assign p = a ^ b;
    assign g = a & b;

    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);

    assign sum = p ^ c[3:0];
    assign cout = c[4];
endmodule

module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire c;

    CLA4 cla_low (.a(a[3:0]), .b(b[3:0]), .cin(cin), .sum(sum[3:0]), .cout(c));
    CLA4 cla_high (.a(a[7:4]), .b(b[7:4]), .cin(c), .sum(sum[7:4]), .cout(cout));
endmodule