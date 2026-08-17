#############################################################################
# scripts/run.do -- compile + simulate shift_add_mult (single configuration)
#
# All build/sim artifacts (work lib, transcript, wlf, vcd) go to ../sim.
#
# Usage (run from the shift_add_multiplier/ directory):
#   vsim -c -do scripts/run.do
#   vsim -c -do "set WIDTH 8;  do scripts/run.do"
#   vsim -c -do "set WIDTH 16; set SEED 1; set DUMP 1; do scripts/run.do"
#
# Overridable knobs (set before 'do scripts/run.do'):
#   WIDTH  DATA_WIDTH parameter override        (default 32)
#   SEED   +SEED plusarg for the TB             (default: TB's own default)
#   DUMP   1 => pass +DUMP so the TB writes dump.vcd  (default 0)
#############################################################################

# ---- locate project root from the launch directory ----
# Run from shift_add_multiplier/ (has src/, tb/), or from the repo root above it.
set ROOT [pwd]
if {![file isdirectory $ROOT/src]} {
    if {[file isdirectory $ROOT/shift_add_multiplier/src]} {
        set ROOT $ROOT/shift_add_multiplier
    } else {
        error "run.do: launch from the shift_add_multiplier/ directory (no src/ found under [pwd])"
    }
}
set SRC  $ROOT/src
set TB   $ROOT/tb
set SIM  $ROOT/sim

# ---- defaults ----
if {![info exists WIDTH]} { set WIDTH 32 }
if {![info exists SEED]}  { set SEED  "" }
if {![info exists DUMP]}  { set DUMP  0  }

# ---- keep every artifact inside sim/ ----
file mkdir $SIM
cd $SIM
transcript file transcript.log

# ---- fresh work library ----
if {[file isdirectory work]} { vdel -all -lib work }
vlib work
vmap work work

# ---- compile ----
vlog -sv -work work $SRC/shift_add_mult.sv $TB/shift_add_mult_tb.sv

# ---- assemble plusargs ----
set plus {}
if {$SEED ne ""} { lappend plus +SEED=$SEED }
if {$DUMP}       { lappend plus +DUMP }

# ---- simulate; -onfinish stop makes $finish return here instead of exiting ----
vsim -c -onfinish stop -wlf vsim.wlf -work work -gDATA_WIDTH=$WIDTH {*}$plus shift_add_mult_tb
run -all

# ---- remove the startup transcript Questa opens in the launch dir ----
catch {file delete -force $ROOT/transcript}
quit -f
