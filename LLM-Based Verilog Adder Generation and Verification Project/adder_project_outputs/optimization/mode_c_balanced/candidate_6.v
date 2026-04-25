module HA(
    input a,
    input b,
    output sum,
    output cout
);
    xor (sum, a, b);
    and (cout, a, b);
endmodule

module CSLA(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [3:0] sum0, sum1;
    wire cout0, cout1;

    FA fa0_0 (.a(a[0]), .b(b[0]), .cin(1'b0), .sum(sum0[0]), .cout(cout0));
    FA fa0_1 (.a(a[0]), .b(b[0]), .cin(1'b1), .sum(sum1[0]), .cout(cout1));
    assign sum[0] = cin ? sum1[0] : sum0[0];

    FA fa1_0 (.a(a[1]), .b(b[1]), .cin(cout0), .sum(sum0[1]), .cout(cout0));
    FA fa1_1 (.a(a[1]), .b(b[1]), .cin(cout1), .sum(sum1[1]), .cout(cout1));
    assign sum[1] = cin ? sum1[1] : sum0[1];

    FA fa2_0 (.a(a[2]), .b(b[2]), .cin(cout0), .sum(sum0[2]), .cout(cout0));
    FA fa2_1 (.a(a[2]), .b(b[2]), .cin(cout1), .sum(sum1[2]), .cout(cout1));
    assign sum[2] = cin ? sum1[2] : sum0[2];

    FA fa3_0 (.a(a[3]), .b(b[3]), .cin(cout0), .sum(sum0[3]), .cout(cout0));
    FA fa3_1 (.a(a[3]), .b(b[3]), .cin(cout1), .sum(sum1[3]), .cout(cout1));
    assign {cout, sum[3]} = cin ? {cout1, sum1[3]} : {cout0, sum0[3]};
endmodule

module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire c;

    CSLA csla_low (.a(a[3:0]), .b(b[3:0]), .cin(cin), .sum(sum[3:0]), .cout(c));
    CSLA csla_high (.a(a[7:4]), .b(b[7:4]), .cin(c), .sum(sum[7:4]), .cout(cout));
endmodule

module FA(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    wire temp;

    xor (temp, a, b);
    xor (sum, temp, cin);
    assign cout = (a & b) | (temp & cin);
endmodule