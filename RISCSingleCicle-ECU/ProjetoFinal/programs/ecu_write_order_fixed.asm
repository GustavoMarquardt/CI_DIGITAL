# Programa ECU - ORDEM CORRETA DE ESCRITAS
.text
.globl main

main:
    # Verificar se já executou (usando x31)
    bne x31, x0, halt_permanent
    addi x31, x0, 1
    
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)
    
    # Delay
    addi x0, x0, 0
    addi x0, x0, 0
    
    # === LEITURA DOS SENSORES ===
    lw x10, 0(x2)          # x10 = RPM
    lw x11, 4(x2)          # x11 = TPS
    lw x12, 8(x2)          # x12 = Temp Motor
    lw x13, 16(x2)         # x13 = MAP
    
    # === VERIFICAÇÃO DE SEGURANÇA (CALCULAR MAS NÃO ESCREVER AINDA) ===
    addi x20, x0, 0
    
    # RPM > 6500?
    addi x21, x0, 2047
    addi x21, x21, 2047
    addi x21, x21, 2047
    addi x21, x21, 359     # x21 = 6500
    blt x10, x21, check_temp
    addi x20, x20, 1
    
check_temp:
    # Temp > 120?
    addi x21, x0, 120
    blt x12, x21, safety_done
    addi x20, x20, 2
    
safety_done:
    # NÃO escrever flags ainda - guardar em x20
    bne x20, x0, safety_mode
    
    # === MODO NORMAL ===
normal_mode:
    # rpm_idx = min(RPM/1000, 7)
    addi x21, x0, 1000
    divu x22, x10, x21
    addi x21, x0, 7
    blt x22, x21, rpm_ok
    addi x22, x0, 7
rpm_ok:
    
    # tps_idx = min(TPS/14, 7)
    addi x21, x0, 14
    divu x23, x11, x21
    addi x21, x0, 7
    blt x23, x21, tps_ok
    addi x23, x0, 7
tps_ok:
    
    # offset = 64 + (rpm_idx * 8) + tps_idx
    addi x21, x0, 8
    mul x24, x22, x21
    add x24, x24, x23
    addi x24, x24, 64
    
    # Ler avanço da lookup table
    lw x25, 0(x24)
    
    # Limitar entre 5 e 35
    addi x21, x0, 5
    bge x25, x21, check_max_adv
    addi x25, x0, 5
check_max_adv:
    addi x21, x0, 35
    blt x25, x21, calc_injection
    addi x25, x0, 35
    
calc_injection:
    # Calcular injeção: (MAP * 10) + 1000
    addi x21, x0, 10
    mul x26, x13, x21
    addi x21, x0, 1000
    add x26, x26, x21
    
    # Se motor frio, aumentar 30%
    addi x21, x0, 60
    bge x12, x21, write_outputs
    addi x21, x0, 30
    mul x27, x26, x21
    addi x21, x0, 100
    divu x27, x27, x21
    add x26, x26, x27
    
write_outputs:
    # ESCREVER NA ORDEM: Avanço -> Injeção -> Flags
    sw x25, 0(x3)          # Escrever avanço
    sw x26, 4(x3)          # Escrever injeção
    sw x20, 16(x3)         # Escrever flags (0 = sem erros)
    beq x0, x0, halt_permanent
    
    # === MODO SEGURANÇA ===
safety_mode:
    andi x21, x20, 1
    beq x21, x0, check_overheat_mode
    
    # OVERREV
    addi x25, x0, 5
    addi x26, x0, 0
    sw x25, 0(x3)          # Escrever avanço
    sw x26, 4(x3)          # Escrever injeção
    sw x20, 16(x3)         # Escrever flags
    beq x0, x0, halt_permanent
    
check_overheat_mode:
    andi x21, x20, 2
    beq x21, x0, halt_permanent
    
    # OVERHEAT
    addi x25, x0, 8
    addi x21, x0, 10
    mul x26, x13, x21
    addi x21, x0, 1000
    add x26, x26, x21
    sw x25, 0(x3)          # Escrever avanço
    sw x26, 4(x3)          # Escrever injeção
    sw x20, 16(x3)         # Escrever flags

halt_permanent:
    beq x0, x0, halt_permanent
