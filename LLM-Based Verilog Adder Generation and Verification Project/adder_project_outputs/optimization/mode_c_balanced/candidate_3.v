module FA(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign {cout, sum} = a + b + cin;
endmodule

module CLA4(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] p, g;
    wire [2:0] carry;

    assign p = a ^ b;
    assign g = a & b;

    assign carry[0] = g[0] | (p[0] & cin);
    assign carry[1] = g[1] | (p[1] & carry[0]);
    assign carry[2] = g[2] | (p[2] & carry[1]);
    assign cout = g[3] | (p[3] & carry[2]);

    assign sum = p ^ {carry[2], carry[1], carry[0], cin};
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