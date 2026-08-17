module mult_128_top(
    input logic clk, rst,
    input logic [4:0] a_addr, b_addr, wrt_addr,
    output logic valid_out
);

    logic [255:0] a_pipe, b_pipe, out_pipe, a, b, o, o_pipe;
    
    reg_file u_reg(
        .clk(clk),
        .rd_addr1(a_addr), 
        .rd_addr2(b_addr), 
        .wrt_addr(wrt_addr), 
        .wrt_en(1'b1), 
        .data_in(o_pipe),
        .rd1(a), 
        .rd2(b)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            a_pipe <= '0;
            b_pipe <= '0;
            o_pipe <= '0;
        end else begin
            a_pipe <= a;
            b_pipe <= b;
            o_pipe <= o;
        end
    end
    
    mult_128 u_mult(
        .multiplicand(a_pipe[127:0]), 
        .multiplier(b_pipe[127:0]), 
        .out(o)
    );
    
    // XOR reduction forces synthesis of all internal multiplier logic
    assign valid_out = ^o_pipe;

endmodule