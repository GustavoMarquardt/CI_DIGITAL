# Teste: escrever flags=0 diretamente
.text
.globl main

main:
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)
    
    # Escrever flags = 0 DIRETAMENTE
    addi x20, x0, 0
    sw x20, 16(x3)
    
    # Escrever avanço = 12
    addi x25, x0, 12
    sw x25, 0(x3)
    
    # Escrever injeção = 1300
    addi x26, x0, 1300
    sw x26, 4(x3)

halt_direct:
    beq x0, x0, halt_direct
