# ECU Control Program - Corrigido para funcionar
.text
.globl main

main:
    # Inicialização
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)
    addi x4, x0, 64        # x4 = base lookup table

main_loop:
    # 1. Leitura dos Sensores
    lw x10, 0(x2)          # x10 = RPM
    lw x11, 4(x2)          # x11 = TPS
    lw x12, 8(x2)          # x12 = Temp Motor
    lw x14, 16(x2)         # x14 = MAP
    
    # 2. Verificação de Segurança
    addi x20, x0, 0        # x20 = flags (inicializar em 0)
    
    # Verificar RPM > 6500
    # Como 6500 > 2047, vamos construir com múltiplas somas
    addi x21, x0, 2047
    addi x21, x21, 2047
    addi x21, x21, 2047
    addi x21, x21, 359     # x21 = 6500
    
    # Se RPM >= 6500, setar flag bit 0
    blt x10, x21, check_temp
    addi x20, x20, 1       # Setar bit 0 (overrev)
    
check_temp:
    # Verificar Temp > 120
    addi x21, x0, 120
    blt x12, x21, safety_ok
    addi x20, x20, 2       # Setar bit 1 (overheat)
    
safety_ok:
    sw x20, 16(x3)         # Salvar flags em 0x210
    
    # 3. Cálculo do Avanço
    # Normalizar RPM para índice 0-7
    addi x21, x0, 1000
    divu x22, x10, x21     # x22 = RPM / 1000
    
    # Limitar a 7
    addi x21, x0, 7
    blt x22, x21, rpm_ok
    addi x22, x0, 7
rpm_ok:
    
    # Normalizar TPS para índice 0-7
    addi x21, x0, 14
    divu x23, x11, x21     # x23 = TPS / 14
    
    # Limitar a 7
    addi x21, x0, 7
    blt x23, x21, tps_ok
    addi x23, x0, 7
tps_ok:
    
    # Calcular offset: 64 + (rpm_idx * 8) + tps_idx
    addi x21, x0, 8
    mul x24, x22, x21
    add x24, x24, x23
    add x24, x24, x4
    
    # Carregar avanço da lookup table
    lw x25, 0(x24)
    
    # Correção por temperatura
    # Se temp < 60, reduzir 3 graus
    addi x21, x0, 60
    bge x12, x21, temp_ok
    addi x25, x25, -3
    
temp_ok:
    # Limitar entre 5 e 35
    addi x21, x0, 5
    bge x25, x21, check_max
    addi x25, x0, 5
    
check_max:
    addi x21, x0, 35
    blt x25, x21, advance_ok
    addi x25, x0, 35
    
advance_ok:
    # Se flags != 0, usar avanço mínimo (5 graus)
    beq x20, x0, save_advance
    addi x25, x0, 5
    
save_advance:
    sw x25, 0(x3)          # Salvar em 0x200
    
    # 4. Cálculo da Injeção
    lw x26, 8(x0)          # x26 = tempo_base = 1000
    
    # tempo = (MAP * 10) + base
    addi x21, x0, 10
    mul x27, x14, x21
    add x27, x27, x26
    
    # Se motor frio (temp < 60), aumentar 30%
    addi x21, x0, 60
    bge x12, x21, check_overrev
    
    # Aumentar 30%
    addi x21, x0, 30
    mul x28, x27, x21
    addi x21, x0, 100
    divu x28, x28, x21
    add x27, x27, x28
    
check_overrev:
    # Se overrev (bit 0 das flags), cortar injeção
    andi x21, x20, 1
    beq x21, x0, save_injection
    addi x27, x0, 0        # Cortar
    
save_injection:
    sw x27, 4(x3)          # Salvar em 0x204
    
    # Loop infinito
    jal x0, main_loop
