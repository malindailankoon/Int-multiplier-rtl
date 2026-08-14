module shift_add_mult #(
    parameter int DATA_WIDTH = 32
)(
    input logic clk, rst,
    input logic [DATA_WIDTH-1:0] a, b,
    input logic in_valid,
    output logic in_ready,
    output logic [2*DATA_WIDTH-1: 0] p,
    output logic out_valid,
    input logic out_ready    
);

    localparam int N = $clog2(DATA_WIDTH+1);


    logic [DATA_WIDTH:0] A, sum, A_next;
    logic [DATA_WIDTH-1: 0] Q, M, Q_next;
    logic [N-1: 0] count;
    logic [2*DATA_WIDTH:0] pair_shifted;


    typedef enum logic[1:0] {S_IDLE, S_CALC, S_DONE} state_t;
    state_t state;

    assign out_valid = (state == S_DONE);
    assign in_ready = (state == S_IDLE);
    assign p = {A[DATA_WIDTH-1:0], Q};

    

    always_comb begin
        if (Q[0] == 1) begin
            sum = A + M;
        end
        else begin
            sum = A;
        end

        pair_shifted = {sum, Q} >> 1;

        A_next = pair_shifted[2*DATA_WIDTH:DATA_WIDTH];
        Q_next = pair_shifted[DATA_WIDTH-1:0];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            A <= '0;
            Q <= '0;
            M <= '0;
            state <= S_IDLE;
            count <= '0;
        end else begin
            unique case (state)
                S_IDLE: begin
                    if (in_valid) begin
                        Q <= a;
                        M <= b;
                        A <= '0;
                        state <= S_CALC;
                        count <= '0;
                    end
                end
                
                S_CALC: begin
                    Q <= Q_next;
                    A <= A_next;
                    count <= count + 1;
                    if (count == DATA_WIDTH-1) begin
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    if (out_ready)
                        state <= S_IDLE;
                end

                default: state <= S_IDLE;
                
            endcase
        end
    end


endmodule