`timescale 1ns/1ps

// =============================================================================
// shift_add_mult_tb.sv  --  self-checking testbench for shift_add_mult
//
// Sweep DATA_WIDTH per SIMULATION RUN by overriding the top param, e.g.:
//   iverilog -g2012 -Pshift_add_mult_tb.DATA_WIDTH=8 \
//            -o sim tb/shift_add_mult_tb.sv src/shift_add_mult.sv && vvp sim
//   (loop 4 8 16 32 in a run script to cover several widths)
//
// Optional plusargs:  +SEED=<n>   +DUMP   (writes dump.vcd)
//
// Methodology note: the DUT is reset ONCE, then every case runs back-to-back
// with no reset in between -- on purpose. A shift-add multiplier that fails to
// clear its accumulator on load only misbehaves from the 2nd multiply onward,
// so resetting between cases would hide that bug.
// =============================================================================

module shift_add_mult_tb #(parameter int DATA_WIDTH = 32);

    // ---- knobs ----
    localparam time CLK_PERIOD = 10ns;
    localparam time TIMEOUT    = 500us;
    localparam int  N_RAND     = 200;

    // ---- bookkeeping ----
    int errors = 0;
    int runs   = 0;

    // ---- types ----
    typedef logic [DATA_WIDTH-1:0]   word_t;
    typedef logic [2*DATA_WIDTH-1:0] dword_t;

    // ---- DUT signals ----
    logic   clk, rst;
    word_t  a, b;
    logic   in_valid, in_ready;
    dword_t p;
    logic   out_valid, out_ready;

    // ---- DUT ----
    shift_add_mult #(.DATA_WIDTH(DATA_WIDTH)) dut (
        .clk       (clk),
        .rst       (rst),
        .a         (a),
        .b         (b),
        .in_valid  (in_valid),
        .in_ready  (in_ready),
        .p         (p),
        .out_valid (out_valid),
        .out_ready (out_ready)
    );

    // ---- clock ----
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---- clocking block: drive/sample synchronously, race-free ----
    default clocking cb @(posedge clk);
        default input #1step output #1ns;
        input  in_ready, out_valid, p;
        output a, b, in_valid, out_ready;
    endclocking

    // ---- watchdog ----
    initial begin
        #(TIMEOUT);
        $fatal(1, "TIMEOUT: exceeded %0t without finishing", TIMEOUT);
    end

    // ---- optional waveform dump ----
    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile("dump.vcd");
            $dumpvars(0, shift_add_mult_tb);
        end
    end

    // ---- golden reference (full-width unsigned product) ----
    function automatic dword_t ref_prod(input word_t x, input word_t y);
        return dword_t'(x) * dword_t'(y);   // cast so the multiply is 2*W wide
    endfunction

    // ---- full-width random word ($urandom only returns 32 bits) ----
    function automatic word_t rand_word();
        word_t v = '0;
        for (int i = 0; i < DATA_WIDTH; i += 32)
            v |= word_t'($urandom()) << i;
        return v;
    endfunction

    // ---- reset once, park the TB-driven inputs low ----
    task automatic reset_dut();
        rst = 1'b1;
        cb.in_valid  <= 1'b0;
        cb.out_ready <= 1'b0;
        cb.a         <= '0;
        cb.b         <= '0;
        ##3;
        rst = 1'b0;
        @cb;
    endtask

    // ---- drive one multiply and check the result (NO reset inside) ----
    task automatic run_case(input word_t ain, input word_t bin, input string name);
        dword_t expected = ref_prod(ain, bin);

        // wait until the DUT can accept operands
        while (in_ready !== 1'b1) @cb;

        // present operands for exactly one accepted handshake cycle
        cb.a        <= ain;
        cb.b        <= bin;
        cb.in_valid <= 1'b1;
        @cb;
        cb.in_valid <= 1'b0;

        // wait for the result
        while (out_valid !== 1'b1) @cb;

        runs++;
        if (p !== expected) begin
            errors++;
            $error("[%0t] FAIL %-16s a=0x%0h b=0x%0h  got=0x%0h exp=0x%0h",
                   $time, name, ain, bin, p, expected);
        end else begin
            $display("[%0t] PASS %-16s a=0x%0h b=0x%0h  p=0x%0h",
                     $time, name, ain, bin, p);
        end

        // accept the result so the DUT returns to idle
        cb.out_ready <= 1'b1;
        @cb;
        cb.out_ready <= 1'b0;
    endtask

    // ---- test sequence ----
    initial begin
        int unsigned seed;
        word_t ra, rb;

        seed = 32'hC0FFEE;
        if ($value$plusargs("SEED=%d", seed))
            $display("Seed overridden from command line.");
        void'($urandom(seed));
        $display("=== shift_add_mult_tb  DATA_WIDTH=%0d  SEED=%0d ===",
                 DATA_WIDTH, seed);

        reset_dut();

        // directed corners
        run_case('0,          '0,          "zero_zero");
        run_case('0,          rand_word(), "zero_b");
        run_case(rand_word(), '0,          "a_zero");
        run_case(word_t'(1),  word_t'(1),  "one_one");
        run_case('1,          '1,          "max_max");
        run_case('1,          word_t'(1),  "max_one");
        run_case(word_t'(1),  '1,          "one_max");

        // back-to-back non-zero pair -- specifically exercises a DUT that
        // forgets to clear its accumulator on load (2nd multiply goes wrong)
        run_case(word_t'(15), word_t'(15), "b2b_15x15");
        run_case(word_t'(3),  word_t'(5),  "b2b_3x5");

        // random
        for (int t = 0; t < N_RAND; t++) begin
            ra = rand_word();
            rb = rand_word();
            run_case(ra, rb, $sformatf("rand_%0d", t));
        end

        // report
        if (errors == 0)
            $display("=== ALL %0d TESTS PASSED ===", runs);
        else
            $display("=== %0d of %0d TESTS FAILED ===", errors, runs);

        if (errors != 0) $fatal(1, "TESTBENCH FAILED (%0d errors)", errors);
        $finish;
    end

endmodule
