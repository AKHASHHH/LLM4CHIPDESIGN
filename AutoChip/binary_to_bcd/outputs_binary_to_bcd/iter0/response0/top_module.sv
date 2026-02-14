module top_module (
    input  [4:0] binary_input,
    output [7:0] bcd_output
);

// Wires to hold the intermediate results of the conversion
wire [3:0] tens;
wire [3:0] units;

// Calculate tens and units using division and modulo operations
assign tens = binary_input / 10;
assign units = binary_input % 10;

// Concatenate tens and units to form the final BCD output
assign bcd_output = {tens, units};

endmodule
