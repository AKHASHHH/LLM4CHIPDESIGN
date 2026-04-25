module testbench;
  reg [7:0] a, b;
  reg cin;
  wire [7:0] sum;
  wire cout;
  wire [7:0] c, g, p;
  wire [14:8] g1, p1;
  wire [20:15] g2, p2;
  wire [24:21] g3, p3;

  integer i, j, k;
  integer pass_count = 0;
  integer test_count = 0;

  adder8 DUT(.sum(sum), .cout(cout), .a(a), .b(b), .cin(cin));

  initial begin
    $display("Starting Testbench...");
    
    for (i = 0; i < 4; i = i + 1) begin
      for (j = 0; j < 4; j = j + 1) begin
        for (k = 0; k < 2; k = k + 1) begin
          a = i; b = j; cin = k;
          #10;
          test_count = test_count + 1;

          // Compute expected result
          reg [8:0] expected_sum;
          expected_sum = a + b + cin;

          // Display test case details
          $display("Test %0d: a=%0b, b=%0b, cin=%0b | sum(DUT)=%0b, cout(DUT)=%0b", test_count, a, b, cin, sum, cout);
          $display("Internal Signals: c=%0b, g=%0b, p=%0b", c, g, p);
          $display("                : g1=%0b, p1=%0b", g1, p1);
          $display("                : g2=%0b, p2=%0b", g2, p2);
          $display("                : g3=%0b, p3=%0b", g3, p3);

          // Check result
          if (sum === expected_sum[7:0] && cout === expected_sum[8]) begin
            $display("Result: PASS\n");
            pass_count = pass_count + 1;
          end else begin
            $display("Result: FAIL\n");
          end
        end
      end
    end

    $display("Test Summary: Total Tests = %0d, Passed = %0d, Failed = %0d", test_count, pass_count, test_count - pass_count);
    $stop;
  end
endmodule