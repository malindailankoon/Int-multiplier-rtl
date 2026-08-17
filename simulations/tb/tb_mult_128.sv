`timescale 1ns/1ps

module tb_mult_128();

    // Internal signals matching DUT ports
    logic signed [127:0] multiplier;
    logic signed [127:0] multiplicand;
    logic signed [255:0] out;
    
    // DUT Instantiation
    mult_128 dut (
        .multiplier(multiplier),
        .multiplicand(multiplicand),
        .out(out)
    );

    // Function to generate 128-bit random data
    function logic [127:0] rand_128();
        return {$urandom(), $urandom(), $urandom(), $urandom()};
    endfunction

    // Self-checking task
    task test_case(input logic signed [127:0] a, input logic signed [127:0] b);
        logic signed [255:0] expected;
        
        multiplier = a;
        multiplicand = b;
        
        // Wait 10ns for combinational logic propagation
        #10; 
        
        // Calculate expected mathematical result
        expected = a * b;
        
        // Verify structural output against expected result
        if (out !== expected) begin
            $display("FAIL: Hardware mismatch detected at time %0t", $time);
            $display("Multiplier  : %h", a);
            $display("Multiplicand: %h", b);
            $display("Expected    : %h", expected);
            $display("Actual      : %h", out);
            $stop;
        end
    endtask

    // Test Sequence execution
    initial begin
        int i;
        $display("Starting 128-bit multiplier verification...");

        // 1. Directed Corner Cases
        // Zeros
        test_case(128'sd0, 128'sd0);
        
        // Basic ones and negative ones
        test_case(128'sd1, 128'sd1);
        test_case(-128'sd1, 128'sd1);
        test_case(-128'sd1, -128'sd1);
        
        // Maximum positive value (0 followed by all 1s)
        test_case({1'b0, {127{1'b1}}}, {1'b0, {127{1'b1}}});
        
        // Minimum negative value (1 followed by all 0s)
        test_case({1'b1, {127{1'b0}}}, {1'b1, {127{1'b0}}});
        
        // Max positive * Min negative
        test_case({1'b0, {127{1'b1}}}, {1'b1, {127{1'b0}}});
        
        // Alternating bit patterns
        test_case(128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA, 128'h55555555555555555555555555555555);

        // 2. Randomized Testing
        // Execute 10,000 random test vectors
        for (i = 0; i < 10000; i++) begin
            test_case(rand_128(), rand_128());
        end

        $display("Verification Complete: All test cases passed successfully.");
        $finish;
    end

endmodule