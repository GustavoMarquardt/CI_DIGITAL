# Rodar testbench ecu_automotive: compila, simula, grava log (sobrescreve a cada execução).
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

$iverilog = $null
$vvp      = $null
$candidates = @('C:\iverilog\bin', 'C:\iverilog')
if ($env:IVL_ROOT) {
    $iv = $env:IVL_ROOT.TrimEnd('\', '/')
    $candidates = @((Join-Path $iv 'bin'), $iv) + $candidates
}
foreach ($dir in $candidates) {
    $i = Join-Path $dir 'iverilog.exe'
    $v = Join-Path $dir 'vvp.exe'
    if (Test-Path $i) { $iverilog = $i; $vvp = $v; break }
}
if (-not $iverilog) {
    $ic = Get-Command iverilog -ErrorAction SilentlyContinue
    $vc = Get-Command vvp -ErrorAction SilentlyContinue
    if ($ic -and $vc) { $iverilog = $ic.Source; $vvp = $vc.Source }
}
if (-not $iverilog) {
    Write-Error 'iverilog não encontrado. Instale o Icarus Verilog ou defina IVL_ROOT.' -ErrorAction Stop
}

$modsDir = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue | Where-Object {
    Test-Path (Join-Path $_.FullName 'cpu.v')
} | Select-Object -First 1 -ExpandProperty FullName
if (-not $modsDir) { Write-Error 'Pasta de modulos Verilog nao encontrada (esperado cpu.v).' -ErrorAction Stop }

$mods    = @(Get-ChildItem -Path $modsDir -Filter '*.v' | ForEach-Object { $_.FullName })
$tb      = Join-Path $root 'testbenches\ecu_automotive_tb.v'
$vvpOut  = Join-Path $root 'ecu_automotive_run.vvp'
$logFile = Join-Path $root 'ecu_automotive_test.log'

& $iverilog -g2012 -o $vvpOut @mods $tb
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Redireciona toda a saída para o .txt (substitui o arquivo a cada run)
& $vvp $vvpOut *> $logFile

Write-Host "Log completo: $logFile"
Get-Content $logFile -Tail 35

exit $LASTEXITCODE
