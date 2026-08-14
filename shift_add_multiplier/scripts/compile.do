#############################################################################
# scripts/compile.do -- compile-only, for a quick syntax / elaboration check
#
# Builds the work library in ../sim but does NOT simulate. Fast way to catch
# syntax errors while editing the RTL or testbench.
#
# Usage (run from the shift_add_multiplier/ directory):
#   vsim -c -do scripts/compile.do
#############################################################################

# ---- locate project root from the launch directory ----
# Run from shift_add_multiplier/ (has src/, tb/), or from the repo root above it.
set ROOT [pwd]
if {![file isdirectory $ROOT/src]} {
    if {[file isdirectory $ROOT/shift_add_multiplier/src]} {
        set ROOT $ROOT/shift_add_multiplier
    } else {
        error "compile.do: launch from the shift_add_multiplier/ directory (no src/ found under [pwd])"
    }
}
set SRC  $ROOT/src
set TB   $ROOT/tb
set SIM  $ROOT/sim

# ---- keep every artifact inside sim/ ----
file mkdir $SIM
cd $SIM
transcript file transcript.log

# ---- fresh work library ----
if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

# ---- compile only; a syntax error aborts the vlog command, which we trap ----
set ok [expr {![catch {vlog -sv -work work \
    $SRC/shift_add_mult.sv $TB/shift_add_mult_tb.sv} msg]}]

# ---- remove the startup transcript Questa opens in the launch dir ----
catch {file delete -force $ROOT/transcript}

if {$ok} {
    puts "########## COMPILE OK ##########"
    quit -code 0
} else {
    puts "########## COMPILE FAILED ##########"
    puts $msg
    quit -code 1
}
