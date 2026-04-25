module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [2:0] carry;

    // Use 2-bit Ripple Carry Adders and single-bit adders
    assign {carry[0], sum[1:0]} = a[1:0] + b[1:0] + cin;
    assign {carry[1], sum[3:2]} = a[3:2] + b[3:2] + carry[0];
    assign {carry[2], sum[5:4]} = a[5:4] + b[5:4] + carry[1];
    assign {cout, sum[7:6]} = a[7:6] + b[7:6] + carry[2];
endmodule