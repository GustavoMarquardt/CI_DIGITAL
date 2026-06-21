# Teste: escrever uma vez e parar
.text
.globl main

main:
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)

    # Ler sensores
    lw x10, 0(x2)          # x10 = RPM
    lw x12, 16(x2)         # x12 = MAP
    
    # Escrever avanço = 12
    addi x11, x0, 12
    sw x11, 0(x3)
    
    # Calcular injeção: MAP * 10 + 1000
    addi x13, x0, 10
    mul x14, x12, x13      # x14 = MAP * 10
    addi x15, x0, 1000
    add x14, x14, x15      # x14 = (MAP*10) + 1000
    sw x14, 4(x3)
    
    # Escrever flags = 0
    addi x16, x0, 0
    sw x16, 16(x3)

stop:
    # Loop NOP infinito (não modifica nada)
    addi x0, x0, 0
    jal x0, stop
