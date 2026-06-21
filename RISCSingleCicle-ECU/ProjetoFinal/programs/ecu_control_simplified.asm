# ECU Control Program - Single Cylinder Engine (Simplified)
# Controle de ignição e injeção para motor monocilíndrico
# RISC-V Assembly

.text
.globl main

main:
    # Inicialização
    addi x2, x0, 4096      # x2 = 0x1000 (base endereço sensores)
    addi x3, x0, 8192      # x3 = 0x2000 (base endereço atuadores)
    addi x4, x0, 64        # x4 = base lookup table (endereço 64)

main_loop:
    #========================================
    # 1. Leitura dos Sensores
    #========================================
    lw x10, 0(x2)          # x10 = RPM (endereço 0x1000)
    lw x11, 4(x2)          # x11 = TPS (endereço 0x1004)
    lw x12, 8(x2)          # x12 = Temp Motor (endereço 0x1008)
    lw x13, 12(x2)         # x13 = Temp Ar (endereço 0x100C)
    lw x14, 16(x2)         # x14 = MAP (endereço 0x1010)
    
    #========================================
    # 2. Verificação de Segurança
    #========================================
check_safety:
    # Carregar constantes
    lw x15, 12(x0)         # x15 = RPM limite (6500)
    lw x16, 16(x0)         # x16 = Temp limite (120°C)
    
    addi x20, x0, 0        # x20 = safety_flags (iniciar zerado)
    
    # Verificar RPM > 6500 (overrev)
    addi x21, x0, 6500     # x21 = 6500
    sub x22, x10, x21      # x22 = RPM - 6500
    blt x22, x0, check_temp  # Se negativo (RPM < 6500), pular
    addi x20, x20, 1       # Setar flag bit 0 (overrev)
    
check_temp:
    # Verificar Temp > 120°C
    addi x21, x0, 120      # x21 = 120
    sub x22, x12, x21      # x22 = Temp - 120
    blt x22, x0, safety_ok # Se negativo (Temp < 120), pular
    addi x20, x20, 2       # Setar flag bit 1 (overheat)
    
safety_ok:
    # Escrever safety flags
    sw x20, 16(x3)         # Salvar em 0x2010
    
    #========================================
    # 3. Cálculo do Avanço de Ignição
    #========================================
calculate_ignition:
    # Normalizar RPM para índice 0-7
    # RPM / 1000 para obter índice aproximado
    addi x21, x0, 1000     # Divisor
    divu x22, x10, x21     # x22 = RPM / 1000
    
    # Limitar índice RPM a 0-7
    addi x21, x0, 7
    blt x22, x21, rpm_ok
    addi x22, x0, 7        # Máximo índice 7
rpm_ok:
    
    # Normalizar TPS para índice 0-7
    addi x21, x0, 14       # Divisor
    divu x23, x11, x21     # x23 = TPS / 14
    
    # Limitar índice TPS a 0-7
    addi x21, x0, 7
    blt x23, x21, tps_ok
    addi x23, x0, 7        # Máximo índice 7
tps_ok:
    
    # Calcular endereço na lookup table
    addi x21, x0, 8
    mul x24, x22, x21      # x24 = idx_rpm * 8
    add x24, x24, x23      # x24 = (idx_rpm * 8) + idx_tps
    add x24, x24, x4       # x24 = 64 + offset
    
    # Carregar valor da tabela
    lw x25, 0(x24)         # x25 = avanço de ignição base
    
    # Correção por temperatura (motor frio = menos avanço)
    addi x21, x0, 60
    sub x26, x12, x21      # x26 = temp_motor - 60
    bge x26, x0, temp_correction_done
    
    # Temperatura baixa: reduzir avanço em 3 graus
    addi x25, x25, -3
    
temp_correction_done:
    # Limitar avanço entre 5 e 35 graus
    addi x21, x0, 5
    bge x25, x21, check_max_advance
    addi x25, x0, 5        # Mínimo 5 graus
    
check_max_advance:
    addi x21, x0, 35
    blt x25, x21, advance_ok
    addi x25, x0, 35       # Máximo 35 graus
    
advance_ok:
    # Se overrev ou overheat (flags != 0), usar avanço mínimo
    beq x20, x0, save_advance
    addi x25, x0, 5        # Usar avanço mínimo por segurança
    
save_advance:
    sw x25, 0(x3)          # Salvar avanço em 0x2000
    
    #========================================
    # 4. Cálculo do Tempo de Injeção
    #========================================
calculate_injection:
    lw x26, 8(x0)          # x26 = tempo_base (1000 us)
    
    # tempo = (MAP * 10) + base
    addi x21, x0, 10
    mul x27, x14, x21      # x27 = MAP * 10
    add x27, x27, x26      # x27 = (MAP * 10) + 1000
    
    # Correção por temperatura do motor frio (< 60°C)
    addi x21, x0, 60
    sub x28, x12, x21      # x28 = temp_motor - 60
    bge x28, x0, check_overrev
    
    # Motor frio: aumentar 30%
    addi x21, x0, 30
    mul x28, x27, x21
    addi x21, x0, 100
    div x28, x28, x21      # x28 = 30% do tempo
    add x27, x27, x28      # Adicionar correção
    
check_overrev:
    # Se overrev (flag bit 0), cortar injeção
    andi x21, x20, 1       # Testar bit 0
    beq x21, x0, save_injection
    addi x27, x0, 0        # Cortar injeção (rev limiter)
    
save_injection:
    sw x27, 4(x3)          # Salvar tempo em 0x2004
    
    #========================================
    # Loop Infinito
    #========================================
    jal x0, main_loop      # Voltar ao início
