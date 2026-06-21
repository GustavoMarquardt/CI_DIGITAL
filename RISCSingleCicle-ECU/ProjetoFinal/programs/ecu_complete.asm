# ECU Control Program - Simplified with correct addresses
.text
.globl main

main:
    # Inicialização
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)
    addi x4, x0, 64        # x4 = base lookup table

main_loop:
    # Leitura dos Sensores
    lw x10, 0(x2)          # x10 = RPM
    lw x11, 4(x2)          # x11 = TPS
    lw x12, 8(x2)          # x12 = Temp Motor
    lw x13, 12(x2)         # x13 = Temp Ar
    lw x14, 16(x2)         # x14 = MAP
    
check_safety:
    # Inicializar flags
    addi x20, x0, 0
    
    # Verificar RPM > 6500 (overrev)
    addi x21, x0, 1820     # Aproximação de 6500
    addi x21, x21, 1820
    addi x21, x21, 1820
    addi x21, x21, 1040    # x21 = 6500
    sub x22, x10, x21
    blt x22, x0, check_temp
    addi x20, x20, 1
    
check_temp:
    # Verificar Temp > 120
    addi x21, x0, 120
    sub x22, x12, x21
    blt x22, x0, safety_ok
    addi x20, x20, 2
    
safety_ok:
    sw x20, 16(x3)         # Salvar flags
    
calculate_ignition:
    # Normalizar RPM: idx = RPM / 1000
    addi x21, x0, 1000
    div x22, x10, x21
    
    # Limitar a 7
    addi x21, x0, 7
    blt x22, x21, rpm_ok
    addi x22, x0, 7
rpm_ok:
    
    # Normalizar TPS: idx = TPS / 14
    addi x21, x0, 14
    div x23, x11, x21
    
    # Limitar a 7
    addi x21, x0, 7
    blt x23, x21, tps_ok
    addi x23, x0, 7
tps_ok:
    
    # Calcular offset na lookup table
    addi x21, x0, 8
    mul x24, x22, x21
    add x24, x24, x23
    add x24, x24, x4
    
    # Carregar avanço base
    lw x25, 0(x24)
    
    # Correção por temperatura (motor frio = -3 graus)
    addi x21, x0, 60
    sub x26, x12, x21
    bge x26, x0, temp_correction_done
    addi x25, x25, -3
    
temp_correction_done:
    # Limitar entre 5 e 35
    addi x21, x0, 5
    bge x25, x21, check_max_advance
    addi x25, x0, 5
    
check_max_advance:
    addi x21, x0, 35
    blt x25, x21, advance_ok
    addi x25, x0, 35
    
advance_ok:
    # Se flags != 0, usar avanço mínimo
    beq x20, x0, save_advance
    addi x25, x0, 5
    
save_advance:
    sw x25, 0(x3)
    
calculate_injection:
    lw x26, 8(x0)          # tempo_base = 1000
    
    # tempo = (MAP * 10) + base
    addi x21, x0, 10
    mul x27, x14, x21
    add x27, x27, x26
    
    # Correção por motor frio (+30%)
    addi x21, x0, 60
    sub x28, x12, x21
    bge x28, x0, check_overrev
    
    # Aumentar 30%
    addi x21, x0, 30
    mul x28, x27, x21
    addi x21, x0, 100
    div x28, x28, x21
    add x27, x27, x28
    
check_overrev:
    # Se overrev, cortar injeção
    andi x21, x20, 1
    beq x21, x0, save_injection
    addi x27, x0, 0
    
save_injection:
    sw x27, 4(x3)
    
    # Loop infinito
    jal x0, main_loop
