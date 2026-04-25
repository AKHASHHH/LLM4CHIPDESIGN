module testbench;
    reg [7:0] a;
    reg [7:0] b;
    reg cin;
    wire [7:0] sum;
    wire cout;
    
    RCA8 rca (.a(a), .b(b), .sum(sum), .cout(cout));

    integer pass_count = 0;
    integer fail_count = 0;

    initial begin
        // Test 1
        a = 8'h00; b = 8'h00; cin = 0; #10;
        if (sum === 8'h00 && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 2
        a = 8'hFF; b = 8'h01; cin = 0; #10;
        if (sum === 8'h00 && cout === 1) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 3
        a = 8'h0F; b = 8'h01; cin = 0; #10;
        if (sum === 8'h10 && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 4
        a = 8'hF0; b = 8'h10; cin = 0; #10;
        if (sum === 8'h00 && cout === 1) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 5
        a = 8'h05; b = 8'h0A; cin = 0; #10;
        if (sum === 8'h0F && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 6
        a = 8'hA5; b = 8'h5A; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 7
        a = 8'h55; b = 8'hAA; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 8
        a = 8'h81; b = 8'h7F; cin = 0; #10;
        if (sum === 8'h00 && cout === 1) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 9
        a = 8'h3C; b = 8'hC3; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 10
        a = 8'hBE; b = 8'h41; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 11
        a = 8'h12; b = 8'hED; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 12
        a = 8'h66; b = 8'h99; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 13
        a = 8'h77; b = 8'h88; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 14
        a = 8'h11; b = 8'hEF; cin = 0; #10;
        if (sum === 8'h00 && cout === 1) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 15
        a = 8'h23; b = 8'hDC; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 16
        a = 8'hAB; b = 8'h54; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 17
        a = 8'hFE; b = 8'h01; cin = 1; #10;
        if (sum === 8'h00 && cout === 1) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 18
        a = 8'h80; b = 8'h80; cin = 0; #10;
        if (sum === 8'h00 && cout === 1) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 19
        a = 8'hFF; b = 8'h00; cin = 0; #10;
        if (sum === 8'hFF && cout === 0) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        // Test 20
        a = 8'h01; b = 8'hFF; cin = 1; #10;
        if (sum === 8'h01 && cout === 1) begin $display("PASS"); pass_count = pass_count + 1; end else begin $display("FAIL"); fail_count = fail_count + 1; end

        $display("Test Summary: %0d PASS, %0d FAIL", pass_count, fail_count);
    end
endmodule