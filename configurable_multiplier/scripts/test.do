
set ROOT [pwd]
if {![file isdirectory $ROOT/src]} {
    error "test.do: run the script in configurable_multiplier folder"
}


set SIM $ROOT/sim
set SRC $ROOT/src
set TB $ROOT/tb


file mkdir $SIM
cd $SIM
transcript file transcript.log


if {[file isdirectory work]} {vdel -all -lib work}


vlib work 
vmap work work


set ok [expr {![catch {vlog -sv -work work +libext+.sv -y $SRC $TB/add4_tb.sv} msg]}]


catch {file delete -force $ROOT/transcript}


if {$ok} {
    puts "=== COMPILE OK ==="

    vsim work.add4_tb

    run -all

    quit -code 0
} else {
    puts "=== COMPILE FAILED ==="
    puts $msg
    quit -code 1
}