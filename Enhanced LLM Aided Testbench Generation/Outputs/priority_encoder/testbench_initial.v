module tb_priority_encoder_3bit;
    reg [2:0] in;
    wire [1:0] out;
    wire valid;

    // Instantiate the module under test
    priority_encoder_3bit uut (
        .in(in),
        .out(out),
        .valid(valid)
    );

    initial begin
        // Test pattern 1: All inputs are zero
        in = 3'b000;
        #10;
        $display("Test 1: in=000");

        // Test pattern 2: Only bit 0 is set
        in = 3'b001;
        #10;
        $display("Test 2: in=001");

        // Test pattern 3: Only bit 1 is set
        in = 3'b010;
        #10;
        $display("Test 3: in=010");

        // Test pattern 4: Only bit 2 is set
        in = 3'b100;
        #10;
        $display("Test 4: in=100");

        // Test pattern 5: Bits 0 and 1 are set
        in = 3'b011;
        #10;
        $display("Test 5: in=011");

        // Test pattern 6: Bits 0 and 2 are set
        in = 3'b101;
        #10;
        $display("Test 6: in=101");

        // Test pattern 7: Bits 1 and 2 are set
        in = 3'b110;
        #10;
        $display("Test 7: in=110");

        // Test pattern 8: All bits are set
        in = 3'b111;
        #10;
        $display("Test 8: in=111");

        // Additional random test pattern 9
        in = 3'b001;
        #10;
        $display("Test 9: in=001");

        // Additional random test pattern 10
        in = 3'b010;
        #10;
        $display("Test 10: in=010");

        // Additional random test pattern 11
        in = 3'b100;
        #10;
        $display("Test 11: in=100");

        $finish;
    end
endmodule