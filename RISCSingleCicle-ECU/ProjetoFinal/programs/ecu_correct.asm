# ECU Control Program - Versão Corrigida e Testada
.text
.globl main

main:
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)
    addi x4, x0, 64        # x4 = inicio lookup table (address 64)

main_loop:
    # === 1. LEITURA DOS SENSORES ===
    lw x10, 0(x2)          # x10 = RPM (16 bits lower)
    lw x11, 4(x2)          # x11 = TPS
    lw x12, 8(x2)          # x12 = Temp Motor
    lw x14, 16(x2)         # x14 = MAP
    
    # === 2. VERIFICAÇÃO DE SEGURANÇA ===
    addi x20, x0, 0        # x20 = flags (inicializar em 0)
    
    # RPM > 6500?
    addi x21, x0, 2047
    addi x21, x21, 2047
    addi x21, x21, 2047
    addi x21, x21, 359     # x21 = 6500
    blt x10, x21, check_temp
    addi x20, x20, 1       # Setar bit 0 (overrev)
    
check_temp:
    # Temp > 120?
    addi x21, x0, 120
    blt x12, x21, safety_done
    addi x20, x20, 2       # Setar bit 1 (overheat)
    
safety_done:
    sw x20, 16(x3)         # Salvar flags
    
    # Se flags != 0, usar valores de segurança
    bne x20, x0, safety_mode
    
    # === 3. MODO NORMAL - CÁLCULO DO AVANÇO ===
    # Normalizar RPM para índice: rpm_idx = min(RPM/1000, 7)
    addi x21, x0, 1000
    divu x22, x10, x21     # x22 = RPM / 1000
    
    addi x21, x0, 7
    blt x22, x21, rpm_idx_ok
    addi x22, x0, 7
rpm_idx_ok:
    
    # Normalizar TPS para índice: tps_idx = min(TPS/14, 7)
    addi x21, x0, 14
    divu x23, x11, x21     # x23 = TPS / 14
    
    addi x21, x0, 7
    blt x23, x21, tps_idx_ok
    addi x23, x0, 7
tps_idx_ok:
    
    # Calcular offset: 64 + (rpm_idx * 8) + tps_idx
    addi x21, x0, 8
    mul x24, x22, x21      # x24 = rpm_idx * 8
    add x24, x24, x23      # x24 = (rpm_idx * 8) + tps_idx
    add x24, x24, x4       # x24 = 64 + offset
    
    # Carregar avanço da lookup table
    lw x25, 0(x24)         # x25 = advance
    
    # Correção por temperatura
    addi x21, x0, 60
    bge x12, x21, temp_normal
    # Motor frio: reduzir 3 graus
    addi x25, x25, -3
    
temp_normal:
    # Limitar entre 5 e 35
    addi x21, x0, 5
    bge x25, x21, check_max_adv
    addi x25, x0, 5
    
check_max_adv:
    addi x21, x0, 35
    blt x25, x21, save_adv
    addi x25, x0, 35
    
save_adv:
    sw x25, 0(x3)          # Salvar avanço em 0x200
    
    # === 4. CÁLCULO DA INJEÇÃO ===
    lw x26, 8(x0)          # x26 = tempo_base = 1000 (mem[2])
    
    # tempo = (MAP * 10) + base
    addi x21, x0, 10
    mul x27, x14, x21      # x27 = MAP * 10
    add x27, x27, x26      # x27 = (MAP*10) + 1000
    
    # Se motor frio (temp < 60), aumentar 30%
    addi x21, x0, 60
    bge x12, x21, save_inj
    
    # Aumentar 30%: inj = inj + (inj * 30 / 100)
    addi x21, x0, 30
    mul x28, x27, x21      # x28 = inj * 30
    addi x21, x0, 100
    divu x28, x28, x21     # x28 = (inj * 30) / 100
    add x27, x27, x28      # x27 = inj + correção
    
save_inj:
    sw x27, 4(x3)          # Salvar injeção em 0x204
    jal x0, main_loop      # Loop
    
safety_mode:
    # Modo de segurança: avanço mínimo, injeção cortada se overrev
    addi x25, x0, 5        # Avanço = 5
    sw x25, 0(x3)
    
    # Se overrev (bit 0), cortar injeção
    andi x21, x20, 1
    bne x21, x0, cut_injection
    
    # Senão, manter injeção mínima
    lw x27, 8(x0)          # x27 = 1000
    sw x27, 4(x3)
    jal x0, main_loop
    
cut_injection:
    addi x27, x0, 0        # Injeção = 0
    sw x27, 4(x3)
    jal x0, main_loop
