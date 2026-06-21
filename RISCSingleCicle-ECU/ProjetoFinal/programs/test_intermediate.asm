# Teste intermediário - Ler sensores e escrever valores calculados simples
.text
.globl main

main:
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)

loop:
    # Ler RPM
    lw x10, 0(x2)          # x10 = RPM
    
    # Escrever avanço = 12 (fixo)
    addi x11, x0, 12
    sw x11, 0(x3)          # Salvar em 0x200
    
    # Ler MAP
    lw x12, 16(x2)         # x12 = MAP
    
    # Calcular injeção: MAP * 10 + 1000
    addi x13, x0, 10
    mul x14, x12, x13      # x14 = MAP * 10
    addi x15, x0, 1000
    add x14, x14, x15      # x14 = (MAP*10) + 1000
    sw x14, 4(x3)          # Salvar em 0x204
    
    # Escrever flags = 0
    addi x16, x0, 0
    sw x16, 16(x3)         # Salvar em 0x210
    
    jal x0, loop
