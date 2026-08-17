module reg_file(
    input logic clk,
    input logic [4:0] rd_addr1, rd_addr2,
    input logic [4:0] wrt_addr, 
    input logic [255:0] data_in,
    input logic wrt_en,
    output logic [255:0] rd1, rd2
);

    logic [255:0] buffer [31:0];
    
    initial begin
        $readmemh("init_data.mem", buffer);
    end
    
    assign rd1 = buffer[rd_addr1];
    assign rd2 = buffer[rd_addr2];
    
    always_ff @(posedge clk) begin
        if (wrt_en) begin
            buffer[wrt_addr] <= data_in;
        end
    end

endmodule