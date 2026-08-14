module add4(
    input logic [3:0] a,
    input logic [3:0] b,
    input logic cin,
    output logic [3:0] s,
    output logic cout
);

    logic [4:0] C ;
    logic [3:0] G ;
    logic [3:0] P ;

    assign C[0] = cin;
    assign cout = C[4];

    genvar i;

    
    generate
        for (i=0; i<4; i++) begin
            assign P[i] = a[i]^b[i];
            assign G[i] = a[i]&b[i];
            assign C[i+1] = G[i] | P[i]&C[i];
        end
    endgenerate
    


    generate
        for (i=0; i<4; i++) begin
            fa u_fa(
                .a(a[i]),
                .b(b[i]),
                .cin(C[i]),
                .s(s[i]),
                .cout()
            );
        end
    endgenerate


endmodule