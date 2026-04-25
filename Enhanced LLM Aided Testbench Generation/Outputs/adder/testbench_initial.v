module testbench;
    reg [3:0] a;
    reg [3:0] b;
    wire [3:0] sum;
    wire carry;

    // Instantiate the adder4bit module
    adder4bit uut (
        .a(a),
        .b(b),
        .sum(sum),
        .carry(carry)
    );

    initial begin
        // Test Case 1: Minimum boundary (a = 0, b = 0)
        a = 4'b0000; b = 4'b0000;
        #10 $display("Test 1: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Test Case 2: Maximum no-carry (a = 7, b = 8)
        a = 4'b0111; b = 4'b1000;
        #10 $display("Test 2: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Test Case 3: Maximum carry (a = 15, b = 1)
        a = 4'b1111; b = 4'b0001;
        #10 $display("Test 3: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Test Case 4: Typical case (a = 5, b = 3)
        a = 4'b0101; b = 4'b0011;
        #10 $display("Test 4: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Test Case 5: Edge case (a = 8, b = 8)
        a = 4'b1000; b = 4'b1000;
        #10 $display("Test 5: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Test Case 6: Random value (a = 10, b = 5)
        a = 4'b1010; b = 4'b0101;
        #10 $display("Test 6: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Test Case 7: Random value (a = 13, b = 4)
        a = 4'b1101; b = 4'b0100;
        #10 $display("Test 7: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Test Case 8: Random value (a = 3, b = 12)
        a = 4'b0011; b = 4'b1100;
        #10 $display("Test 8: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Test Case 9: Corner case (a = 15, b = 15)
        a = 4'b1111; b = 4'b1111;
        #10 $display("Test 9: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Test Case 10: Another edge case (a = 0, b = 15)
        a = 4'b0000; b = 4'b1111;
        #10 $display("Test 10: a = %b, b = %b, sum = %b, carry = %b", a, b, sum, carry);

        // Finish simulation
        $finish;
    end
endmodule