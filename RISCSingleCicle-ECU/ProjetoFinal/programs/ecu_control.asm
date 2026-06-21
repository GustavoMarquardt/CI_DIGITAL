# ECU Control Program - Single Cylinder Engine
# Controle de ignição e injeção para motor monocilíndrico
# RISC-V Assembly

# Mapeamento de Memória:
# Sensores (leitura):
#   0x1000: RPM (16 bits)
#   0x1004: TPS (8 bits)
#   0x1008: Temperatura Motor (8 bits)
#   0x100C: Temperatura Ar (8 bits)
#   0x1010: MAP (8 bits)
#   0x1014: TDC (1 bit)
#
# Atuadores (escrita):
#   0x2000: Avanço Ignição (8 bits)
#   0x2004: Tempo Injeção (16 bits)
#   0x2008: Trigger Ignição (1 bit)
#   0x2010: Safety Flags (8 bits)
#
# Constantes em Memória:
#   0x0000: Lambda estequiométrico * 10 (147)
#   0x0004: Lambda potência * 10 (125)
#   0x0008: Tempo base injeção (1000)
#   0x000C: RPM limite (6500)
#   0x0010: Temperatura limite (120)
#   0x0014: Temperatura enriquecimento (60)
#
# Lookup Table:
#   0x0100-0x01FC: Tabela 8x8 de avanço (endereços 64-127)

.text
.globl main

main:
    # Inicialização
    # Construir 0x1000 (4096) = 2047 + 2047 + 2
    addi x2, x0, 2047      # x2 = 2047
    addi x2, x2, 2047      # x2 = 4094
    addi x2, x2, 2         # x2 = 4096 (0x1000) = base endereço sensores
    
    # Construir 0x2000 (8192) = 2047 + 2047 + 2047 + 2047 + 4
    addi x3, x0, 2047      # x3 = 2047
    addi x3, x3, 2047      # x3 = 4094
    addi x3, x3, 2047      # x3 = 6141
    addi x3, x3, 2047      # x3 = 8188
    addi x3, x3, 4         # x3 = 8192 (0x2000) = base endereço atuadores
    
    addi x4, x0, 256       # x4 = 0x100 byte = início da lookup (word 64) na data_memory

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
    # Construir constantes (hardcoded para evitar problemas de memória)
    # RPM limite = 6500 = 2047 + 2047 + 2047 + 359
    addi x15, x0, 2047     # x15 = 2047
    addi x15, x15, 2047    # x15 = 4094
    addi x15, x15, 2047    # x15 = 6141
    addi x15, x15, 359     # x15 = 6500 (RPM limite)
    
    # Temp limite = 120
    addi x16, x0, 120      # x16 = 120 (Temp limite)
    
    addi x20, x0, 0        # x20 = safety_flags (iniciar zerado)
    
    # Verificar RPM > 6500 (overrev)
    sub x21, x10, x15      # x21 = RPM - 6500
    blt x21, x0, check_temp  # Se negativo (RPM < 6500), pular
    addi x20, x20, 1       # Setar flag bit 0 (overrev)
    
check_temp:
    # Verificar Temp > 120°C
    sub x21, x12, x16      # x21 = Temp - 120
    blt x21, x0, safety_ok # Se negativo (Temp < 120), pular
    addi x20, x20, 2       # Setar flag bit 1 (overheat)
    
safety_ok:
    # Escrever safety flags
    sw x20, 16(x3)         # Salvar em 0x2010
    
    #========================================
    # 3. Cálculo do Avanço de Ignição
    #========================================
calculate_ignition:
    # Normalizar RPM para índice 0-7
    # RPM / 625 aproximadamente (1000->1, 1500->2, 2000->3, etc)
    # Simplificação: RPM / 1000 para obter índice aproximado
    
    addi x21, x0, 1000     # Divisor
    divu x22, x10, x21     # x22 = RPM / 1000 (índice aproximado)
    
    # Limitar índice RPM a 0-7
    addi x21, x0, 7
    blt x22, x21, rpm_ok
    addi x22, x0, 7        # Máximo índice 7
rpm_ok:
    
    # Normalizar TPS para índice 0-7
    # TPS / 12.5 aproximadamente
    # Simplificação: TPS / 14 (0->0, 14->1, 28->2, etc)
    addi x21, x0, 14       # Divisor
    divu x23, x11, x21     # x23 = TPS / 14 (índice aproximado)
    
    # Limitar índice TPS a 0-7
    addi x21, x0, 7
    blt x23, x21, tps_ok
    addi x23, x0, 7        # Máximo índice 7
tps_ok:
    
    # Calcular endereço na lookup table (byte): 0x100 + 4 * ((idx_rpm * 8) + idx_tps)
    addi x21, x0, 8
    mul x24, x22, x21      # x24 = idx_rpm * 8
    add x24, x24, x23      # índice linear 0..63 em words
    add x24, x24, x24      # x24*2
    add x24, x24, x24      # x24*4 (= <<2)
    add x24, x24, x4       # endereço absoluto
    
    # Carregar valor da tabela
    lw x25, 0(x24)         # x25 = avanço de ignição base
    
    # Correção por temperatura
    # Se temp < 60°C, reduzir avanço em 2-3 graus
    addi x21, x0, 60       # x21 = 60 (temp enriquecimento)
    sub x26, x12, x21      # x26 = temp_motor - 60
    bge x26, x0, temp_correction_done  # Se temp >= 60, não corrigir
    
    # Temperatura baixa: reduzir avanço
    addi x25, x25, -3      # Reduzir 3 graus
    
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
    # Se overrev ou overheat, usar avanço mínimo
    beq x20, x0, save_advance  # Se flags = 0, salvar normal
    addi x25, x0, 5        # Usar avanço mínimo por segurança
    
save_advance:
    sw x25, 0(x3)          # Salvar avanço em 0x2000
    
    #========================================
    # 4. Cálculo do Tempo de Injeção
    #========================================
calculate_injection:
    # Algoritmo simplificado:
    # tempo_base = (MAP * fator) / RPM
    # Fator para ajustar proporção
    
    addi x26, x0, 1000     # x26 = tempo_base (1000 us)
    
    # tempo = (MAP * 10) + base
    addi x21, x0, 10
    mul x27, x14, x21      # x27 = MAP * 10
    add x27, x27, x26      # x27 = (MAP * 10) + 1000
    
    # Correção por temperatura do ar
    # Se temp ar < 20°C, aumentar tempo (ar frio = mais combustível)
    addi x21, x0, 20
    sub x28, x13, x21      # x28 = temp_ar - 20
    bge x28, x0, motor_temp_correction
    
    # Ar frio: aumentar 10%
    addi x21, x0, 10
    mul x28, x27, x21
    addi x21, x0, 100
    div x28, x28, x21      # x28 = 10% do tempo
    add x27, x27, x28      # Adicionar correção
    
motor_temp_correction:
    # Se motor frio (< 60°C), enriquecer (aumentar 20%)
    addi x21, x0, 60       # x21 = 60
    sub x28, x12, x21      # x28 = temp_motor - 60
    bge x28, x0, injection_limits
    
    # Motor frio: aumentar 20%
    addi x21, x0, 20
    mul x28, x27, x21
    addi x21, x0, 100
    div x28, x28, x21      # x28 = 20% do tempo
    add x27, x27, x28      # Adicionar correção
    
injection_limits:
    # Se overrev (flag bit 0), cortar injeção
    andi x21, x20, 1       # Testar bit 0
    beq x21, x0, save_injection
    addi x27, x0, 0        # Cortar injeção (rev limiter)
    
save_injection:
    sw x27, 4(x3)          # Salvar tempo em 0x2004
    # (sem espera TDC na simulação — sensor TDC é lento; volta ao loop principal)
    jal x0, main_loop

# Fim do programa
