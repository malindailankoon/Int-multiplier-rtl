module two_comp(
    input logic[127:0] in,
    output logic[127:0] out,
    output logic add_one
);

    logic[127:0] flipped;
    assign flipped = ~in;

    

endmodule