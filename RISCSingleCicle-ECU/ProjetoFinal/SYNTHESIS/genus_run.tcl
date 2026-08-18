# =============================================================================
# genus_run.tcl — Fluxo completo de síntese lógica para ECU RISC-V
# Execução: genus -legacy_ui -f genus_run.tcl
#           (ou: genus -f genus_run.tcl  no modo Cadence Flow)
# =============================================================================

source [file join [file dirname [info script]] setup.tcl]

puts "\n========================================="
puts " ECU RISC-V — Síntese Cadence Genus"
puts " Top: $TOP_MODULE | Clock: $CLK_PERIOD ns"
puts "=========================================\n"

# -----------------------------------------------------------------------------
# 1. Biblioteca de células tecnológicas
# -----------------------------------------------------------------------------
read_libs $LIB_FILE

# -----------------------------------------------------------------------------
# 2. Leitura do RTL
# Ordem: módulos base primeiro, depois módulos que os instanciam
# -----------------------------------------------------------------------------
set rtl_files [list \
    $RTL_DIR/carry_look_ahead.v   \
    $RTL_DIR/adder_PC.v           \
    $RTL_DIR/ALU.v                \
    $RTL_DIR/mux2x1_5bits.v       \
    $RTL_DIR/mux2x1_32bits.v      \
    $RTL_DIR/mux3x1_32bits.v      \
    $RTL_DIR/SignExtend.v          \
    $RTL_DIR/register_file.v       \
    $RTL_DIR/instruction_memory.v  \
    $RTL_DIR/data_memory.v         \
    $RTL_DIR/io_controller.v       \
    $RTL_DIR/sensor_simulator.v    \
    $RTL_DIR/tcu_incline_estimator.v \
    $RTL_DIR/tcu_controller.v      \
    $RTL_DIR/Main_Decoder.v        \
    $RTL_DIR/ULA_Decoder.v         \
    $RTL_DIR/Control_Unit.v        \
    $RTL_DIR/PC.v                  \
    $RTL_DIR/PC_IM.v               \
    $RTL_DIR/datapath1.v           \
    $RTL_DIR/datapath2.v           \
    $RTL_DIR/datapath3.v           \
    $RTL_DIR/cpu.v                 \
]

read_hdl -language verilog $rtl_files

# -----------------------------------------------------------------------------
# 3. Elaboração
# -----------------------------------------------------------------------------
elaborate $TOP_MODULE

# -----------------------------------------------------------------------------
# 4. Restrições de timing (SDC)
# -----------------------------------------------------------------------------
read_sdc [file join [file dirname [info script]] constraints.sdc]

# -----------------------------------------------------------------------------
# 5. Síntese (generic → map → optimize)
# -----------------------------------------------------------------------------
syn_generic
syn_map
syn_opt

# -----------------------------------------------------------------------------
# 6. Relatórios
# -----------------------------------------------------------------------------
puts "\n--- Relatório de Timing ---"
report_timing > $OUT_DIR/timing_report.txt
report_timing

puts "\n--- Relatório de Área ---"
report_area > $OUT_DIR/area_report.txt
report_area

puts "\n--- Relatório de Potência ---"
report_power > $OUT_DIR/power_report.txt

# -----------------------------------------------------------------------------
# 7. Escrita do netlist e SDC final
# -----------------------------------------------------------------------------
write_hdl > $OUT_DIR/cpu_netlist.v
write_sdc > $OUT_DIR/cpu_netlist.sdc

puts "\n========================================="
puts " Síntese concluída."
puts " Netlist: $OUT_DIR/cpu_netlist.v"
puts " SDC:     $OUT_DIR/cpu_netlist.sdc"
puts "=========================================\n"
