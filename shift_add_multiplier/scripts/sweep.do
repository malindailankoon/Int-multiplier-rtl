#############################################################################
# scripts/sweep.do -- compile once, simulate across several DATA_WIDTHs
#
# All build/sim artifacts go to ../sim.
#
# Usage (run from the shift_add_multiplier/ directory):
#   vsim -c -do scripts/sweep.do
#   vsim -c -do "set WIDTHS {4 8 16 32 48 64}; do scripts/sweep.do"
#############################################################################

# ---- locate project root from the launch directory ----
# Run from shift_add_multiplier/ (has src/, tb/), or from the repo root above it.
set ROOT [pwd]
if {![file isdirectory $ROOT/src]} {
    if {[file isdirectory $ROOT/shift_add_multiplier/src]} {
        set ROOT $ROOT/shift_add_multiplier
    } else {
        error "sweep.do: launch from the shift_add_multiplier/ directory (no src/ found under [pwd])"
    }
}
set SRC  $ROOT/src
set TB   $ROOT/tb
set SIM  $ROOT/sim

# ---- widths to sweep (overridable) ----
if {![info exists WIDTHS]} { set WIDTHS {4 8 16 24 32} }

# ---- keep every artifact inside sim/ ----
file mkdir $SIM
cd $SIM
transcript file transcript.log

# ---- fresh work library ----
if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

# ---- compile once (DATA_WIDTH is overridden per-run at elaboration) ----
vlog -sv -work work $SRC/shift_add_mult.sv $TB/shift_add_mult_tb.sv

# ---- run each width; -onfinish stop lets the loop continue past $finish ----
foreach W $WIDTHS {
    puts "==================== DATA_WIDTH = $W ===================="
    vsim -c -onfinish stop -work work -gDATA_WIDTH=$W shift_add_mult_tb
    run -all
}

# ---- remove the startup transcript Questa opens in the launch dir ----
catch {file delete -force $ROOT/transcript}
quit -f
