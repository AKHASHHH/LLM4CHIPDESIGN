module testbench;
  reg [7:0] a, b;
  wire [7:0] sum;
  wire cout;
  
  wire [7:0] G, P;
  wire [7:0] g1, p1;
  wire [7:0] g2, p2;
  wire [3:0] g3, p3;
  wire [7:0] C;
  
  integer i, passed, failed;
  
  // Instantiate the DUT
  KSA8 dut (
    .a(a),
    .b(b),
    .sum(sum),
    .cout(cout)
  );

  initial begin
    passed = 0;
    failed = 0;
    
    // Test vectors
    for (i = 0; i < 256; i = i + 13) begin
      a = i[7:0];
      b = ~i[7:0]; // Just a pattern for testing, can be randomized or specific test cases
      
      #10; // Wait for the design to stabilize
      
      // Display signal values
      $display("A=%b, B=%b, SUM=%b, COUT=%b", a, b, sum, cout);
      $display("G=%b, P=%b", G, P);
      $display("g1=%b, p1=%b", g1, p1);
      $display("g2=%b, p2=%b", g2, p2);
      $display("g3=%b, p3=%b", g3, p3);
      $display("C =%b", C);

      // Checking results
      if ({cout, sum} == a + b) begin
        passed = passed + 1;
        $display("Test #%0d: PASS", i);
      end else begin
        failed = failed + 1;
        $display("Test #%0d: FAIL", i);
      end
    end
    
    // Display final results
    $display("\nTest Summary:");
    $display("Total Tests: %0d", passed + failed);
    $display("Passed: %0d", passed);
    $display("Failed: %0d", failed);
    
    $stop;
  end

endmodule