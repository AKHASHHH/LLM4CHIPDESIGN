module adder8_tb;
  reg [7:0] a, b;
  reg cin;
  wire [7:0] sum;
  wire cout;
  reg [7:0] expected_sum;
  reg expected_cout;

  // Counters for test results
  integer total_tests = 0;
  integer passed_tests = 0;
  integer failed_tests = 0;

  // Instantiate the device under test (DUT)
  adder8 DUT (
    .a(a),
    .b(b),
    .cin(cin),
    .sum(sum),
    .cout(cout)
  );

  // Task to verify the adder result
  task verify;
    input [7:0] a_in, b_in;
    input cin_in;
    input [7:0] expected_sum_in;
    input expected_cout_in;

    begin
      a = a_in;
      b = b_in;
      cin = cin_in;
      expected_sum = expected_sum_in;
      expected_cout = expected_cout_in;

      #10; // delay for simulation

      // Monitor internal and output signals
      $display("Testing: a=%b, b=%b, cin=%b => sum=%b, cout=%b",
               a, b, cin, sum, cout);

      // Compare results
      if (sum === expected_sum && cout === expected_cout) begin
        $display("PASS");
        passed_tests = passed_tests + 1;
      end else begin
        $display("FAIL. Expected sum=%b, cout=%b. Got sum=%b, cout=%b",
                 expected_sum, expected_cout, sum, cout);
        failed_tests = failed_tests + 1;
      end

      total_tests = total_tests + 1;

    end
  endtask

  initial begin
    $display("Starting testbench");

    // Test vector 1
    verify(8'b00000000, 8'b00000000, 0, 8'b00000000, 0);
    
    // Test vector 2
    verify(8'b00000001, 8'b00000001, 0, 8'b00000010, 0);
    
    // Test vector 3
    verify(8'b00000010, 8'b00000010, 0, 8'b00000100, 0);
    
    // Test vector 4
    verify(8'b11111111, 8'b00000001, 0, 8'b00000000, 1);
    
    // Test vector 5
    verify(8'b10101010, 8'b01010101, 0, 8'b11111111, 0);
    
    // Test vector 6
    verify(8'b00001111, 8'b00001111, 0, 8'b00011110, 0);
    
    // Test vector 7
    verify(8'b10000000, 8'b10000000, 0, 8'b00000000, 1);
    
    // Test vector 8
    verify(8'b11110000, 8'b00001111, 0, 8'b11111111, 0);
    
    // Test vector 9
    verify(8'b00000001, 8'b00000001, 1, 8'b00000011, 0);
    
    // Test vector 10
    verify(8'b11111111, 8'b11111111, 0, 8'b11111110, 1);
    
    // Test vector 11
    verify(8'b11111111, 8'b11111111, 1, 8'b11111111, 1);
    
    // Test vector 12
    verify(8'b01111111, 8'b01111111, 0, 8'b11111110, 0);
    
    // Test vector 13
    verify(8'b01111111, 8'b10000000, 0, 8'b11111111, 0);
    
    // Test vector 14
    verify(8'b00000000, 8'b11111111, 0, 8'b11111111, 0);
    
    // Test vector 15
    verify(8'b11111111, 8'b00000000, 0, 8'b11111111, 0);
    
    // Test vector 16
    verify(8'b00000000, 8'b11111111, 1, 8'b00000000, 1);
    
    // Test vector 17
    verify(8'b11011011, 8'b00100100, 0, 8'b11111111, 0);
    
    // Test vector 18
    verify(8'b00010001, 8'b11101110, 0, 8'b11111111, 0);
    
    // Test vector 19
    verify(8'b11011011, 8'b00100101, 0, 8'b00000000, 1);
    
    // Test vector 20
    verify(8'b00011100, 8'b11100011, 1, 8'b00000000, 1);

    // Test summary
    $display("Test Summary:");
    $display("Total Tests: %d, Passed: %d, Failed: %d",
             total_tests, passed_tests, failed_tests);

    $finish;
  end
endmodule