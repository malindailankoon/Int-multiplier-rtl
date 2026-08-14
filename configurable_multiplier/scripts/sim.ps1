param([switch]$comp_only)

$env:PATH = "C:\altera_pro\25.1.1\questa_fse\win64;$env:PATH"
$root = Split-path $PSScriptRoot -Parent
Set-location "$root"


if ($comp_only) {
    vsim -batch -do ./scripts/compile.do
} else {
    vsim -batch -do ./scripts/test.do
}


exit $LASTEXITCODE
