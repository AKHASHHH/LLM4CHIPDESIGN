module tb_priority_encoder_3bit;
    reg [2:0] in;
    wire [1:0] out;
    wire valid;
    integer passed_tests, failed_tests;

    // Instantiate the module under test
    priority_encoder_3bit uut (
        .in(in),
        .out(out),
        .valid(valid)
    );

    initial begin
        passed_tests = 0;
        failed_tests = 0;

        // Test pattern 1: All inputs are zero
        in = 3'b000;
        #10;
        $display("Test 1: in=000");
        #10;
        if (out === 2'b00 && valid === 1'b0) begin
            $display("✓ Test 1 Passed: out=00, valid=0");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 1 Failed: Expected out=00, valid=0, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Test pattern 2: Only bit 0 is set
        in = 3'b001;
        #10;
        $display("Test 2: in=001");
        #10;
        if (out === 2'b00 && valid === 1'b1) begin
            $display("✓ Test 2 Passed: out=00, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 2 Failed: Expected out=00, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Test pattern 3: Only bit 1 is set
        in = 3'b010;
        #10;
        $display("Test 3: in=010");
        #10;
        if (out === 2'b01 && valid === 1'b1) begin
            $display("✓ Test 3 Passed: out=01, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 3 Failed: Expected out=01, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Test pattern 4: Only bit 2 is set
        in = 3'b100;
        #10;
        $display("Test 4: in=100");
        #10;
        if (out === 2'b10 && valid === 1'b1) begin
            $display("✓ Test 4 Passed: out=10, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 4 Failed: Expected out=10, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Test pattern 5: Bits 0 and 1 are set
        in = 3'b011;
        #10;
        $display("Test 5: in=011");
        #10;
        if (out === 2'b01 && valid === 1'b1) begin
            $display("✓ Test 5 Passed: out=01, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 5 Failed: Expected out=01, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Test pattern 6: Bits 0 and 2 are set
        in = 3'b101;
        #10;
        $display("Test 6: in=101");
        #10;
        if (out === 2'b10 && valid === 1'b1) begin
            $display("✓ Test 6 Passed: out=10, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 6 Failed: Expected out=10, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Test pattern 7: Bits 1 and 2 are set
        in = 3'b110;
        #10;
        $display("Test 7: in=110");
        #10;
        if (out === 2'b10 && valid === 1'b1) begin
            $display("✓ Test 7 Passed: out=10, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 7 Failed: Expected out=10, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Test pattern 8: All bits are set
        in = 3'b111;
        #10;
        $display("Test 8: in=111");
        #10;
        if (out === 2'b10 && valid === 1'b1) begin
            $display("✓ Test 8 Passed: out=10, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 8 Failed: Expected out=10, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Additional random test pattern 9
        in = 3'b001;
        #10;
        $display("Test 9: in=001");
        #10;
        if (out === 2'b00 && valid === 1'b1) begin
            $display("✓ Test 9 Passed: out=00, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 9 Failed: Expected out=00, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Additional random test pattern 10
        in = 3'b010;
        #10;
        $display("Test 10: in=010");
        #10;
        if (out === 2'b01 && valid === 1'b1) begin
            $display("✓ Test 10 Passed: out=01, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 10 Failed: Expected out=01, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        // Additional random test pattern 11
        in = 3'b100;
        #10;
        $display("Test 11: in=100");
        #10;
        if (out === 2'b10 && valid === 1'b1) begin
            $display("✓ Test 11 Passed: out=10, valid=1");
            passed_tests = passed_tests + 1;
        end else begin
            $display("✗ Test 11 Failed: Expected out=10, valid=1, Got out=%b, valid=%b", out, valid);
            failed_tests = failed_tests + 1;
        end

        $display("Test Summary: Total=%0d, Passed=%0d, Failed=%0d", passed_tests + failed_tests, passed_tests, failed_tests);
        $finish;
    end
endmodule