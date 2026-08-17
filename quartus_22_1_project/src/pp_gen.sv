module pp_gen(
    input logic[2:0] evl,
    input logic signed [127:0] multiplicand_in,
    output logic signed [128:0] pp_out,
    output logic add_1
);

    always_comb begin
        add_1 = 0;
        unique case (evl)
            3'b000: pp_out = '0; // 0
            3'b001: pp_out = multiplicand_in; // +1
            3'b101: begin // -1
                    pp_out = (~multiplicand_in);
                    add_1 = 1;
            end
            3'b010: pp_out = multiplicand_in <<< 1'b1;  // +2
            3'b110: begin   // -2
                    pp_out = ~(multiplicand_in <<< 1'b1);
                    add_1 = 1;
            end
            default: begin
                    pp_out = '0;
                    add_1 = 0;
            end
        endcase
    end

endmodule