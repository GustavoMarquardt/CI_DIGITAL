# Programa ECU - Modo normal apenas (sem safety)
.text
.globl main

main:
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)
    
    # Delay
    addi x0, x0, 0
    addi x0, x0, 0
    
    # Ler sensores
    lw x10, 0(x2)          # x10 = RPM
    lw x11, 4(x2)          # x11 = TPS
    lw x12, 8(x2)          # x12 = Temp Motor
    lw x13, 16(x2)         # x13 = MAP
    
    # Escrever flags = 0 (sem safety)
    addi x20, x0, 0
    sw x20, 16(x3)
    
    # Calcular avanço usando lookup table
    # rpm_idx = min(RPM/1000, 7)
    addi x21, x0, 1000
    divu x22, x10, x21
    addi x21, x0, 7
    blt x22, x21, rpm_ok_normal
    addi x22, x0, 7
rpm_ok_normal:
    
    # tps_idx = min(TPS/14, 7)
    addi x21, x0, 14
    divu x23, x11, x21
    addi x21, x0, 7
    blt x23, x21, tps_ok_normal
    addi x23, x0, 7
tps_ok_normal:
    
    # offset = 64 + (rpm_idx * 8) + tps_idx
    addi x21, x0, 8
    mul x24, x22, x21
    add x24, x24, x23
    addi x24, x24, 64
    
    # Ler avanço da lookup
    lw x25, 0(x24)
    
    # Limitar 5-35
    addi x21, x0, 5
    bge x25, x21, check_max_normal
    addi x25, x0, 5
check_max_normal:
    addi x21, x0, 35
    blt x25, x21, save_adv_normal
    addi x25, x0, 35
    
save_adv_normal:
    sw x25, 0(x3)
    
    # Calcular injeção: (MAP * 10) + 1000
    addi x21, x0, 10
    mul x26, x13, x21
    addi x21, x0, 1000
    add x26, x26, x21
    
    # Se motor frio, aumentar 30%
    addi x21, x0, 60
    bge x12, x21, save_inj_normal
    addi x21, x0, 30
    mul x27, x26, x21
    addi x21, x0, 100
    divu x27, x27, x21
    add x26, x26, x27
    
save_inj_normal:
    sw x26, 4(x3)

halt_normal:
    beq x0, x0, halt_normal
