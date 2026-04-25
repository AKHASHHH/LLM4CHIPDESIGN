module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [3:0] sum0, sum1;
    wire c3, c7_0, c7_1;

    // Lower 4 bits - RCA
    assign {c3, sum0} = a[3:0] + b[3:0] + cin;

    // Upper 4 bits - Carry-select
    assign {c7_0, sum1} = a[7:4] + b[7:4] + 0;
    assign {c7_1, sum1} = a[7:4] + b[7:4] + 1;
    
    // Select appropriate sum and carry based on c3
    assign sum[3:0] = sum0;
    assign sum[7:4] = c3 ? sum1 : sum1;
    assign cout = c3 ? c7_1 : c7_0;
endmodule