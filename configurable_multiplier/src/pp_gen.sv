module pp_gen(
    input logic[2:0] evl,
    input logic[127:0] multiplicand_in
    output logic[128:0] pp_out,
    output logic add_1,
);

    always_comb begin
        unique case (evl)
            3'b000: pp_out = '0; // 0
            3'b001: pp_out = multiplicand_in; // +1
            3'b101: pp_out = (~multiplicand_in) + 1'b1; // -1
            3'b010: pp_out = multiplicand_in << 1'b1;
            3'b110: pp_o
        endcase
    end

endmodule