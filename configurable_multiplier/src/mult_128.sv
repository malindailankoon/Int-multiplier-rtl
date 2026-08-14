module mult_128(
    input logic[127:0] multiplier, multiplicand,
    output logic[255:0] out
);

    logic [2:0] recoded_multiplier [63:0];
    logic [128:0] prepended_multiplier;
    assign prepended_multiplier = {multiplier, 1'b0};

    genvar i;
    generate
        for (i=1; i<=64; i++) begin
            tri_eval t_eval(.a(prepended_multiplier[2*i]), .b(prepended_multiplier[2*i-1]), .c(prepended_multiplier[2*i-2]), .evl(recoded_multiplier[i-1]));
        end
    endgenerate

endmodule