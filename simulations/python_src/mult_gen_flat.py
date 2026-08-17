import sys

def generate_dadda_multiplier():
    # 1. Initialize the 256-column matrix as a list of lists.
    columns = [[] for _ in range(256)]

    # 2. Populate the initial matrix based on Radix-4 Booth shifting rules
    for i in range(64):
        # 128 Data bits
        for j in range(128):
            col_idx = 2 * i + j
            if col_idx < 256:
                columns[col_idx].append(f"partial_products[{i}][{j}]")
        
        # Inverted MSB (129th bit)
        col_msb = 2 * i + 128
        if col_msb < 256:
            columns[col_msb].append(f"~partial_products[{i}][128]")
            
        # Constant 1 for modified sign extension
        col_const = 2 * i + 129
        if col_const < 256:
            columns[col_const].append("1'b1")
            
        # add_1 signal for two's complement completion
        col_add = 2 * i
        if col_add < 256:
            columns[col_add].append(f"add_signals[{i}]")

    # Single Anchor constant for Row 0
    columns[128].append("1'b1")

    # 3. Define the strict Dadda stage limits
    dadda_limits = [63, 42, 28, 19, 13, 9, 6, 4, 3, 2]
    
    wire_declarations = []
    assignments = []
    
    fa_count = 0
    ha_count = 0
    
    # 4. Process the reduction tree stage by stage
    for stage_idx, limit in enumerate(dadda_limits):
        next_columns = [[] for _ in range(256)]
        
        for c in range(256):
            # Compress using the mathematically accurate total next-stage height
            while (len(columns[c]) + len(next_columns[c])) > limit:
                # If exactly 1 bit over limit, use a Half Adder
                if (len(columns[c]) + len(next_columns[c])) == limit + 1:
                    in1 = columns[c].pop()
                    in2 = columns[c].pop()
                    
                    sum_wire = f"s{stage_idx}_c{c}_ha{ha_count}"
                    carry_wire = f"c{stage_idx}_c{c}_ha{ha_count}"
                    
                    wire_declarations.append(f"logic {sum_wire}, {carry_wire};")
                    assignments.append(f"    assign {sum_wire} = {in1} ^ {in2};")
                    assignments.append(f"    assign {carry_wire} = {in1} & {in2};")
                    
                    next_columns[c].append(sum_wire)
                    if c + 1 < 256:
                        next_columns[c+1].append(carry_wire)
                        
                    ha_count += 1
                    
                # If 2 or more bits over limit, use a Full Adder
                else:
                    in1 = columns[c].pop()
                    in2 = columns[c].pop()
                    in3 = columns[c].pop()
                    
                    sum_wire = f"s{stage_idx}_c{c}_fa{fa_count}"
                    carry_wire = f"c{stage_idx}_c{c}_fa{fa_count}"
                    
                    wire_declarations.append(f"logic {sum_wire}, {carry_wire};")
                    assignments.append(f"    assign {sum_wire} = {in1} ^ {in2} ^ {in3};")
                    assignments.append(f"    assign {carry_wire} = ({in1} & {in2}) | ({in2} & {in3}) | ({in1} & {in3});")
                    
                    next_columns[c].append(sum_wire)
                    if c + 1 < 256:
                        next_columns[c+1].append(carry_wire)
                        
                    fa_count += 1
            
            # Any wires not consumed by adders pass directly to the next stage
            for wire in columns[c]:
                next_columns[c].append(wire)
                
        # Advance the matrix state to the next stage
        columns = next_columns

    # 5. Route the final 2 rows into a fast Carry Propagate Adder
    final_assigns = []
    final_assigns.append("    logic [255:0] final_op_a, final_op_b;\n")
    
    for c in range(256):
        if len(columns[c]) == 2:
            final_assigns.append(f"    assign final_op_a[{c}] = {columns[c][0]};")
            final_assigns.append(f"    assign final_op_b[{c}] = {columns[c][1]};")
        elif len(columns[c]) == 1:
            final_assigns.append(f"    assign final_op_a[{c}] = {columns[c][0]};")
            final_assigns.append(f"    assign final_op_b[{c}] = 1'b0;")
        else:
            final_assigns.append(f"    assign final_op_a[{c}] = 1'b0;")
            final_assigns.append(f"    assign final_op_b[{c}] = 1'b0;")


    # testing the system without any final adder structure       
    # final_assigns.append("\n    assign out = final_op_a + final_op_b;")

    # kogge stone adder for the final adder
    final_assigns.append("\n    kogge_stone_256 u_cpa (.a(final_op_a), .b(final_op_b), .sum(out));")

    # 6. Write everything to the SystemVerilog file
    with open("mult_128.sv", "w") as fh:
        # Header and Front-End Instantiations
        fh.write(
"""module mult_128(
    input logic signed [127:0] multiplier, multiplicand,
    output logic signed [255:0] out
);

    logic [2:0] recoded_multiplier [63:0];
    logic [128:0] prepended_multiplier;
    assign prepended_multiplier = {multiplier, 1'b0};

    genvar i;
    generate
        for (i=1; i<=64; i++) begin : gen_eval
            tri_eval t_eval(.a(prepended_multiplier[2*i]), .b(prepended_multiplier[2*i-1]), .c(prepended_multiplier[2*i-2]), .evl(recoded_multiplier[i-1]));
        end
    endgenerate

    logic signed [128:0] partial_products [63:0]; 
    logic add_signals [63:0];
                                                
    generate
        for (i=0; i<64; i++) begin : gen_pp
            pp_gen u_pp(.evl(recoded_multiplier[i]), .multiplicand_in(multiplicand), .pp_out(partial_products[i]), .add_1(add_signals[i]));
        end
    endgenerate

""")
        # Dadda Tree Wire Declarations
        fh.write("    // Dadda Tree Internal Wires\n    ")
        fh.write("\n    ".join(wire_declarations) + "\n\n")
        
        # Dadda Tree Continuous Assignments
        fh.write("    // Dadda Tree Continuous Assignments\n")
        fh.write("\n".join(assignments) + "\n\n")
        
        # Final Addition
        fh.write("    // Final Carry Propagate Addition\n")
        fh.write("\n".join(final_assigns) + "\n")
        
        fh.write("endmodule\n")

if __name__ == "__main__":
    generate_dadda_multiplier()
    print("Code generation complete: mult_128.sv written.")