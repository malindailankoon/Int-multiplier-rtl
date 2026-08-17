# set whatever folder the script ran from into the variable ROOT
set ROOT [pwd] 

# file isdirectory returns True if there is a folder called src inside ROOT
if {![file isdirectory $ROOT/src]} {
# 
    if {[file isdirectory $ROOT/configurable_multiplier/src]} {
        set ROOT $ROOT/configurable_multiplier
    } else {
        error "compile.do: launch from the configurable_multiplier/ directory"
    }

}


set SRC $ROOT/src
set TB $ROOT/tb
set SIM $ROOT/sim


# creates sim folder if it doesnt already exist
file mkdir $SIM
cd $SIM
# the simulator's consolde output will be printed here
transcript file transcript.log


# checks if a compiled work library exists from a previous run, and deletes it
# -lib work => tells what to delete and what it is (-lib is for library)
# -all => delete the entire thing
if {[file isdirectory work]} {vdel -all -lib work}

# tells compiler to make a new directory to store the compiled design units
vlib work
# maps the logical library work in the hdl code to the work directory made above
vmap work work

# expr evalueats a boolean expression
set ok [expr {![catch {vlog -sv -work work +libext+.sv -y $SRC $SRC/mult_128.sv} msg]}]

# +libext+.sv: Specifies the exact file extension (.sv) the compiler must append to module names when searching for uncompiled sub-modules.
# -y $SRC: Specifies the directory path (stored in $SRC) where the compiler will actively search for the missing sub-module files.
# $TB/shift_add_mult_tb.sv: The explicit path to the testbench file. This serves as the starting point for the compiler to build the design hierarchy.



# remove the startup transcript questa opens in the launch dir
catch {file delete -force $ROOT/transcript}

if {$ok} {
    puts "### compile ok ###"
    quit -code 0
} else {
    puts "### compile failed ###"
    puts $msg
    quit -code 1
}



