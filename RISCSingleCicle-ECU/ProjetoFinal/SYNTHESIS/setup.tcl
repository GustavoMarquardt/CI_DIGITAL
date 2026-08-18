# =============================================================================
# setup.tcl — Configuração de caminhos para síntese Cadence Genus
# EDITE as variáveis abaixo conforme o ambiente do servidor/lab
# =============================================================================

# Caminho para a biblioteca de células tecnológicas (.lib)
# Exemplos comuns em labs universitários:
#   /cadence/libraries/tsmc180nm/slow.lib
#   /eda/pdk/nangate45/NangateOpenCellLibrary_typical.lib
set LIB_PATH "/path/to/technology/library"
set LIB_FILE "$LIB_PATH/typical.lib"

# Diretórios do projeto (relativos a este script — não edite)
set SCRIPT_DIR [file dirname [file normalize [info script]]]
set RTL_DIR    "$SCRIPT_DIR/../RTL"
set UMV_DIR    "$SCRIPT_DIR/../UMV"
set OUT_DIR    "$SCRIPT_DIR/netlist"

# Nome do módulo top-level
set TOP_MODULE "cpu"

# Frequência alvo: 50 MHz => período 20 ns
set CLK_PERIOD 20.0
set CLK_NAME   "clk"
