# Programa de teste simples ECU
.text
.globl main

main:
    # Inicialização
    addi x2, x0, 4096      # x2 = 0x1000 (base sensores)
    addi x3, x0, 8192      # x3 = 0x2000 (base atuadores)
    addi x4, x0, 20        # x4 = avanço base (20 graus)
    addi x5, x0, 960       # x5 = tempo injeção base (960 us)

loop:
    # Ler sensores
    lw x10, 0(x2)          # x10 = RPM
    lw x11, 4(x2)          # x11 = TPS
    lw x12, 8(x2)          # x12 = Temp Motor
    
calc_advance:
    # Calcular avanço: base + (TPS / 10)
    addi x14, x0, 10
    div x15, x11, x14
    add x16, x4, x15       # avanço = 20 + TPS/10
    
    # Limitar avanço entre 10 e 35
    addi x14, x0, 10
    bge x16, x14, skip_min
    addi x16, x0, 10
skip_min:
    addi x14, x0, 35
    blt x16, x14, skip_max
    addi x16, x0, 35
skip_max:
    # Escrever avanço
    sw x16, 0(x3)
    
calc_injection:
    # Calcular tempo injeção: base + (TPS * 5)
    addi x14, x0, 5
    mul x17, x11, x14
    add x17, x5, x17
    
    # Escrever tempo injeção
    sw x17, 4(x3)
    
    # Flags sempre 0
    addi x14, x0, 0
    sw x14, 16(x3)
    
    # Loop
    jal x0, loop
