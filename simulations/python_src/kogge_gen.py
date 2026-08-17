import math

def generate_kogge_stone(width=256):
    stages = int(math.log2(width))
    filename = f"kogge_stone_{width}.sv"

    with open(filename, "w") as fh:
        # 1. Module Definition and Ports
        fh.write(f"module kogge_stone_{width} (\n")
        fh.write(f"    input logic [{width-1}:0] a, b,\n")
        fh.write(f"    output logic [{width-1}:0] sum\n")
        fh.write(");\n\n")

        # 2. Internal Wire Declarations
        fh.write("    // Propagate and Generate Wire Declarations\n")
        for i in range(stages + 1):
            fh.write(f"    logic [{width-1}:0] g_{i}, p_{i};\n")
        fh.write("\n")

        # 3. Preprocessing
        fh.write("    // Preprocessing Stage (Stage 0)\n")
        fh.write("    assign g_0 = a & b;\n")
        fh.write("    assign p_0 = a ^ b;\n\n")

        # 4. Prefix Network Generation
        fh.write("    // Logarithmic Prefix Network\n")
        for i in range(1, stages + 1):
            fh.write(f"    // Stage {i}\n")
            shift = 2**(i-1)
            
            # Bits that do not shift past the boundary simply pass the previous stage values
            fh.write(f"    assign g_{i}[{shift-1}:0] = g_{i-1}[{shift-1}:0];\n")
            fh.write(f"    assign p_{i}[{shift-1}:0] = p_{i-1}[{shift-1}:0];\n")
            
            # Bits that shift compute the new generate and propagate logic via vector operations
            fh.write(f"    assign g_{i}[{width-1}:{shift}] = g_{i-1}[{width-1}:{shift}] | (p_{i-1}[{width-1}:{shift}] & g_{i-1}[{width-1-shift}:0]);\n")
            fh.write(f"    assign p_{i}[{width-1}:{shift}] = p_{i-1}[{width-1}:{shift}] & p_{i-1}[{width-1-shift}:0];\n\n")

        # 5. Postprocessing
        fh.write("    // Postprocessing (Sum Calculation)\n")
        fh.write("    // The carry in for bit 0 is implicitly 0, so sum[0] is just p_0[0]\n")
        fh.write("    assign sum[0] = p_0[0];\n")
        fh.write(f"    assign sum[{width-1}:1] = p_0[{width-1}:1] ^ g_{stages}[{width-2}:0];\n\n")

        fh.write("endmodule\n")

if __name__ == "__main__":
    generate_kogge_stone(256)
    print("Code generation complete: kogge_stone_256.sv written.")