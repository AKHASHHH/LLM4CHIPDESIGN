module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [4:0] carry;

    // Generate partial sum and carry
    assign {carry[0], sum[3:0]} = a[3:0] + b[3:0] + cin;
    assign sum[7:4] = a[7:4] ^ b[7:4] ^ carry[3:0];
    assign carry[4] = (a[7] & b[7]) | (a[7] & carry[3]) | (b[7] & carry[3]);

    // Final carry out
    assign cout = carry[4];
endmodule