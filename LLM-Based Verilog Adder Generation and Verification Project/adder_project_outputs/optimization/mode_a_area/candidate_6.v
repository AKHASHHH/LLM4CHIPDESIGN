module adder8(
    input [7:0] a,
    input [7:0] b,
    input cin,
    output [7:0] sum,
    output cout
);
    wire [1:0] sum1, sum2;
    wire [1:0] c4;
    wire c3, c7_0, c7_1;

    // Lower 4-bit RCA
    assign {c3, sum[3:0]} = a[3:0] + b[3:0] + cin;

    // Upper 4-bit RCA with carry-select
    assign {c4[0], sum1} = a[5:4] + b[5:4] + c3;
    assign {c4[1], sum2} = a[5:4] + b[5:4] + 1'b0;

    assign sum[5:4] = c3 ? sum1 : sum2;
    
    // Final stage carry select
    assign {c7_0, sum[7:6]} = a[7:6] + b[7:6] + c4[0];
    assign {c7_1, sum[7:6]} = a[7:6] + b[7:6] + c4[1];

    assign cout = c3 ? c7_0 : c7_1;
endmodule