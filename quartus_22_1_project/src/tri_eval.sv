module tri_eval(
    input logic a,b,c,
    output logic[2:0] evl
);

 // eval => <1'sign_bit><2'number>
 // sign_bit = 1 => negative

    always_comb begin
        unique case ({a,b,c})
            3'b000: evl = 3'b000;
            3'b001: evl = 3'b001;
            3'b010: evl = 3'b001;
            3'b011: evl = 3'b010;
            3'b100: evl = 3'b110;
            3'b101: evl = 3'b101;
            3'b110: evl = 3'b101;
            3'b111: evl = 3'b000;
            default: evl = 3'b000;
        endcase
    end

endmodule