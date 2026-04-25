module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [3:0] p, g, c;

    // Generate propagate and generate signals
    assign p = a[3:0] ^ b[3:0];
    assign g = a[3:0] & b[3:0];

    // Carry look-ahead logic
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    
    // Sum for lower 4 bits
    assign sum[3:0] = p ^ c[3:0];

    // Use a simple ripple-carry for the upper 4 bits
    assign {cout, sum[7:4]} = a[7:4] + b[7:4] + c[3];
endmodule