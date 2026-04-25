module tb_adder8();

    reg [7:0] a, b;
    reg cin;
    wire [7:0] sum;
    wire cout;
    wire [4:0] carry; // Additional wire for monitoring

    // Instantiate the DUT
    adder8 UUT (
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    integer i, pass_count, fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("Starting test...");

        // Test vector simulation
        for (i = 0; i < 20; i = i + 1) begin
            {a, b, cin} = i; // Sample 20 representative vectors

            #10; // Wait for the operation to complete
            $display("Test %d: a=%b b=%b cin=%b | sum=%b cout=%b | Internal carry=%b",
                     i, a, b, cin, sum, cout, UUT.carry);

            // Verify result
            if ({cout, sum} !== a + b + cin) begin
                $display("FAIL: Expected sum=%b cout=%b",
                         a + b + cin, (a + b + cin) > 255);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS");
                pass_count = pass_count + 1;
            end
        end

        // Summary
        $display("Test Summary: Total=%d Passed=%d Failed=%d", 
                 pass_count + fail_count, pass_count, fail_count);
        $stop;
    end
endmodule