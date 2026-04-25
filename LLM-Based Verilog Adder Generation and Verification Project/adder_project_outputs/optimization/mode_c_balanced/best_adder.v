module HA(
    input a,
    input b,
    output sum,
    output cout
);
    xor (sum, a, b);
    and (cout, a, b);
endmodule

module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [2:0] carry_out;

    // First level addition
    HA ha0 (.a(a[0]), .b(b[0]), .sum(sum[0]), .cout(carry_out[0]));
    HA ha1 (.a(a[1]), .b(b[1]), .sum(sum[1]), .cout(carry_out[1]));
    HA ha2 (.a(a[2]), .b(b[2]), .sum(sum[2]), .cout(carry_out[2]));
    HA ha3 (.a(a[3]), .b(b[3]), .sum(sum[3]), .cout(cout));

    // Second level adding carries (reusing wires)
    assign sum[4] = carry_out[0] ^ cin;
    assign sum[5] = carry_out[1] ^ carry_out[0];
    assign sum[6] = carry_out[2] ^ carry_out[1];
    assign sum[7] = cout ^ carry_out[2];
    assign cout = cout & carry_out[2];
endmodule