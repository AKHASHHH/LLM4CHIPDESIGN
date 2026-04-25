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

module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [3:0] carry;

    // Carry select adder approach with two 4-bit RCA
    FA fa0 (.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(carry[0]));
    FA fa1 (.a(a[1]), .b(b[1]), .cin(carry[0]), .sum(sum[1]), .cout(carry[1]));
    FA fa2 (.a(a[2]), .b(b[2]), .cin(carry[1]), .sum(sum[2]), .cout(carry[2]));
    FA fa3 (.a(a[3]), .b(b[3]), .cin(carry[2]), .sum(sum[3]), .cout(carry[3]));

    FA fa4 (.a(a[4]), .b(b[4]), .cin(carry[3]), .sum(sum[4]), .cout(carry[0]));
    FA fa5 (.a(a[5]), .b(b[5]), .cin(carry[0]), .sum(sum[5]), .cout(carry[1]));
    FA fa6 (.a(a[6]), .b(b[6]), .cin(carry[1]), .sum(sum[6]), .cout(carry[2]));
    FA fa7 (.a(a[7]), .b(b[7]), .cin(carry[2]), .sum(sum[7]), .cout(cout));
endmodule