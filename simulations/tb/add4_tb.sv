`timescale 1ns/1ps

module add4_tb;

    localparam int N_RAND = 50;

    int errors = 0;
    int runs = 0;

    logic [3:0] a, b, s;
    logic cin, cout;
    
    add4 dut(.*);

    // FIX: Explicitly declared the type for 'b' for maximum compiler compatibility
    function automatic void ref_add(
        input  logic [3:0] a, 
        input  logic [3:0] b,
        input  logic       cin, 
        output logic [3:0] s,
        output logic       cout
    );
        {cout, s} = a + b + cin;
    endfunction

    function automatic logic[3:0] rand_num();
        // FIX: Removed the invalid cast. The 32-bit random number will 
        // automatically truncate to fit the 4-bit function return type.
        return $urandom();
    endfunction


    task automatic check(input logic[3:0] test_a, input logic[3:0] test_b, input logic test_cin, input string name);
        logic [3:0] expected_sum;
        logic       expected_cout;

        // Calculate expected values
        ref_add(test_a, test_b, test_cin, expected_sum, expected_cout);

        // Drive testbench signals
        a   = test_a;
        b   = test_b;
        cin = test_cin;

        // Advance simulation time to allow DUT to evaluate
        #1; 

        // Evaluate results
        if (s == expected_sum && cout == expected_cout) begin
            $display("PASS %s a=%d, b=%d, cin=%b", name, a, b, cin);
        end else begin
            errors++;
            $display("FAIL %s a=%d, b=%d, cin=%b: got_sum=%d, exp_sum=%d, got_co=%b, exp=%b", 
                     name, a, b, cin, s, expected_sum, cout, expected_cout);
        end
        
        runs++;
    endtask
    
    initial begin
        int unsigned seed;
        logic [3:0] ra, rb;

        seed = 32'hC0FFEE;
        if ($value$plusargs("SEED=%d", seed))
            $display("seed overridden from commandline");
        void'($urandom(seed));
        $display("===add4_tb seed=%d ===", seed);

        check('0,           '0,           1'b0, "zero_zero_cin0");
        check('0,           '0,           1'b1, "zero_zero_cin1");

        check('0,           rand_num(),   1'b0, "zero_b_cin0");
        check('0,           rand_num(),   1'b1, "zero_b_cin1");

        check(rand_num(),   '0,           1'b0, "a_zero_cin0");
        check(rand_num(),   '0,           1'b1, "a_zero_cin1");

        // FIX: Replaced the invalid logic[3:0]'(1) casts with standard sized literals (4'd1)
        check(4'd1,         4'd1,         1'b0, "one_one_cin0");
        check(4'd1,         4'd1,         1'b1, "one_one_cin1");

        check('1,           '1,           1'b0, "max_max_cin0");
        check('1,           '1,           1'b1, "max_max_cin1");

        check('1,           4'd1,         1'b0, "max_one_cin0");
        check('1,           4'd1,         1'b1, "max_one_cin1");

        check(4'd1,         '1,           1'b0, "one_max_cin0");
        check(4'd1,         '1,           1'b1, "one_max_cin1");

        for (int i=0; i<N_RAND; i++) begin
            ra = rand_num();
            rb = rand_num();
            check(ra, rb, 1'b0, $sformatf("rand_%0d_with_cin0", i));
            check(ra, rb, 1'b1, $sformatf("rand_%0d_with_cin1", i));
        end

        if (errors == 0)
            $display("=== ALL TESTS PASSED ===");
        else 
            $display("=== %0d of %0d TESTS FAILED ===", errors, runs);

        $finish;
    end

endmodule