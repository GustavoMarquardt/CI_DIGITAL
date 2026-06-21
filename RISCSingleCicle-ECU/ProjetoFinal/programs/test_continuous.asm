# Programa que executa continuamente e atualiza valores
.text
.globl main

main:
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)

loop:
    # Ler MAP
    lw x10, 16(x2)         # x10 = MAP
    
    # Calcular injeção base: MAP * 10 + 1000
    addi x11, x0, 10
    mul x12, x10, x11      # x12 = MAP * 10
    addi x13, x0, 1000
    add x12, x12, x13      # x12 = (MAP*10) + 1000
    
    # Aumentar 30%
    addi x14, x0, 30
    mul x15, x12, x14      # x15 = inj * 30
    addi x16, x0, 100
    divu x15, x15, x16     # x15 = (inj * 30) / 100
    add x12, x12, x15      # x12 = inj + correção
    
    # Escrever injeção
    sw x12, 4(x3)
    
    # Escrever avanço = 12
    addi x17, x0, 12
    sw x17, 0(x3)
    
    # Escrever flags = 0
    addi x18, x0, 0
    sw x18, 16(x3)
    
    # Repetir
    jal x0, loop
