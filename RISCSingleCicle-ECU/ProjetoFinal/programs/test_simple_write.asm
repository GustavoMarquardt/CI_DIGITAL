# Programa super simples - apenas escrever valores fixos
.text
.globl main

main:
    # Escrever valores FIXOS diretamente
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)
    addi x10, x0, 12       # Avanco = 12
    addi x11, x0, 1300     # Injecao parte 1
    addi x11, x11, 1300    # Injecao = 1300
    addi x12, x0, 0        # Flags = 0
    
    # Salvar nos atuadores
    sw x10, 0(x3)          # Salvar avanco em 0x200
    sw x11, 4(x3)          # Salvar injecao em 0x204
    sw x12, 16(x3)         # Salvar flags em 0x210
    
    # Loop infinito
loop:
    jal x0, loop
