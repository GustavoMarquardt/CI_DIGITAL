# Programa ECU Completo - VERSÃO FINAL CORRIGIDA
.text
.globl main

main:
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)
    
    # Delay para estabilização
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    
    # === LEITURA DOS SENSORES ===
    lw x10, 0(x2)          # x10 = RPM (16 bits lower)
    lw x11, 4(x2)          # x11 = TPS
    lw x12, 8(x2)          # x12 = Temp Motor
    lw x13, 16(x2)         # x13 = MAP
    
    # === VERIFICAÇÃO DE SEGURANÇA ===
    addi x20, x0, 0        # x20 = flags (inicializar em 0)
    
    # Verificar RPM > 6500
    addi x21, x0, 2047
    addi x21, x21, 2047
    addi x21, x21, 2047
    addi x21, x21, 359     # x21 = 6500
    blt x10, x21, check_temp
    addi x20, x20, 1       # Setar bit 0 (overrev)
    
check_temp:
    # Verificar Temp > 120
    addi x21, x0, 120
    blt x12, x21, safety_done
    addi x20, x20, 2       # Setar bit 1 (overheat)
    
safety_done:
    # Salvar flags
    sw x20, 16(x3)
    
    # Se tem flags, usar modo segurança
    bne x20, x0, safety_mode
    
    # === MODO NORMAL ===
normal_mode:
    # Calcular avanço usando lookup table
    # rpm_idx = min(RPM/1000, 7)
    addi x21, x0, 1000
    divu x22, x10, x21     # x22 = RPM / 1000
    addi x21, x0, 7
    blt x22, x21, rpm_ok
    addi x22, x0, 7
rpm_ok:
    
    # tps_idx = min(TPS/14, 7)
    addi x21, x0, 14
    divu x23, x11, x21     # x23 = TPS / 14
    addi x21, x0, 7
    blt x23, x21, tps_ok
    addi x23, x0, 7
tps_ok:
    
    # offset = 64 + (rpm_idx * 8) + tps_idx
    addi x21, x0, 8
    mul x24, x22, x21      # x24 = rpm_idx * 8
    add x24, x24, x23      # x24 = offset + tps_idx
    addi x24, x24, 64      # x24 = 64 + offset (endereço final)
    
    # Ler avanço da lookup table
    lw x25, 0(x24)         # x25 = advance (lê de Memory_cell[64+offset])
    
    # Limitar entre 5 e 35
    addi x21, x0, 5
    bge x25, x21, check_max_adv
    addi x25, x0, 5
check_max_adv:
    addi x21, x0, 35
    blt x25, x21, save_advance
    addi x25, x0, 35
    
save_advance:
    sw x25, 0(x3)          # Salvar avanço em 0x200
    
    # Calcular injeção: (MAP * 10) + 1000
    addi x21, x0, 10
    mul x26, x13, x21      # x26 = MAP * 10
    addi x21, x0, 1000
    add x26, x26, x21      # x26 = (MAP*10) + 1000
    
    # Se motor frio (temp < 60), aumentar 30%
    addi x21, x0, 60
    bge x12, x21, save_injection
    
    # Calcular 30% de aumento: inj = inj + (inj * 30 / 100)
    addi x21, x0, 30
    mul x27, x26, x21      # x27 = inj * 30
    addi x21, x0, 100
    divu x27, x27, x21     # x27 = (inj * 30) / 100
    add x26, x26, x27      # x26 = inj + correção
    
save_injection:
    sw x26, 4(x3)          # Salvar injeção em 0x204
    beq x0, x0, halt
    
    # === MODO SEGURANÇA ===
safety_mode:
    # Verificar se é overrev (bit 0)
    andi x21, x20, 1
    beq x21, x0, check_overheat_mode
    
    # OVERREV: avanço mínimo e cortar injeção
    addi x25, x0, 5        # Avanço = 5 graus
    sw x25, 0(x3)
    addi x26, x0, 0        # Injeção = 0 (cortar)
    sw x26, 4(x3)
    beq x0, x0, halt
    
check_overheat_mode:
    # Verificar se é overheat (bit 1)
    andi x21, x20, 2
    beq x21, x0, halt
    
    # OVERHEAT: avanço reduzido
    addi x25, x0, 8        # Avanço = 8 graus (<=10)
    sw x25, 0(x3)
    
    # Manter injeção normal
    addi x21, x0, 10
    mul x26, x13, x21      # x26 = MAP * 10
    addi x21, x0, 1000
    add x26, x26, x21      # x26 = (MAP*10) + 1000
    sw x26, 4(x3)

halt:
    # Loop infinito - NÃO reescreve valores
    beq x0, x0, halt
