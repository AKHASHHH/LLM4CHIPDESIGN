module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [3:0] p, g, c;

    // Generate propagate and generate signals for the lower 4 bits
    assign p = a[3:0] ^ b[3:0];
    assign g = a[3:0] & b[3:0];

    // Carry look-ahead logic
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    wire carry_out_3 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);

    // Sum for lower 4 bits
    assign sum[3:0] = p ^ c[3:0];

    // Ripple Carry Adder for upper 4 bits
    wire carry_out_4;
    assign {carry_out_4, sum[7:4]} = a[7:4] + b[7:4] + carry_out_3;

    // Final carry out
    assign cout = carry_out_4;
endmodule