# =============================================================================
# constraints.sdc — Restrições de timing para ECU RISC-V (Cadence Genus)
# Módulo top: cpu
# Clock alvo: 50 MHz (período 20 ns)
# =============================================================================

# -----------------------------------------------------------------------------
# Clock principal
# -----------------------------------------------------------------------------
create_clock -name clk -period 20.0 [get_ports clk]

set_clock_transition     0.1  [get_clocks clk]
set_clock_uncertainty    0.5  [get_clocks clk]
set_clock_latency        1.0  [get_clocks clk]

# -----------------------------------------------------------------------------
# Restrições de entrada (input delays)
# Assume que sinais chegam no máximo 3 ns após a borda do clock
# -----------------------------------------------------------------------------
set INPUT_DELAY 3.0

set_input_delay $INPUT_DELAY -clock clk [get_ports rst]

# Sensores ECU
set_input_delay $INPUT_DELAY -clock clk [get_ports {sensor_rpm[*]}]
set_input_delay $INPUT_DELAY -clock clk [get_ports {sensor_tps[*]}]
set_input_delay $INPUT_DELAY -clock clk [get_ports {sensor_temp_motor[*]}]
set_input_delay $INPUT_DELAY -clock clk [get_ports {sensor_temp_ar[*]}]
set_input_delay $INPUT_DELAY -clock clk [get_ports {sensor_map[*]}]
set_input_delay $INPUT_DELAY -clock clk [get_ports sensor_tdc]

# Sinais TCU (câmbio automático)
set_input_delay $INPUT_DELAY -clock clk [get_ports {vehicle_speed[*]}]
set_input_delay $INPUT_DELAY -clock clk [get_ports brake]
set_input_delay $INPUT_DELAY -clock clk [get_ports {drive_mode[*]}]

# -----------------------------------------------------------------------------
# Restrições de saída (output delays)
# Atuadores precisam de sinal estável 3 ns antes da próxima borda
# -----------------------------------------------------------------------------
set OUTPUT_DELAY 3.0

set_output_delay $OUTPUT_DELAY -clock clk [get_ports {ignition_advance[*]}]
set_output_delay $OUTPUT_DELAY -clock clk [get_ports {injection_time[*]}]
set_output_delay $OUTPUT_DELAY -clock clk [get_ports ignition_trigger]
set_output_delay $OUTPUT_DELAY -clock clk [get_ports {safety_flags[*]}]

# -----------------------------------------------------------------------------
# Carga de saída (estimativa para driving load externo)
# -----------------------------------------------------------------------------
set_load 0.1 [all_outputs]

# -----------------------------------------------------------------------------
# Driving cell nas entradas (estimativa)
# Ajuste para a célula real da biblioteca tecnológica
# -----------------------------------------------------------------------------
# set_driving_cell -lib_cell <BUFX4> [all_inputs]

# -----------------------------------------------------------------------------
# Área máxima (0 = sem restrição — Genus otimiza timing primeiro)
# -----------------------------------------------------------------------------
set_max_area 0
