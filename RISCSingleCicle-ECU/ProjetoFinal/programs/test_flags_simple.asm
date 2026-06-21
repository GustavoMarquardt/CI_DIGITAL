# Teste super simples: ler RPM e Temp e verificar limites
.text
.globl main

main:
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)
    
    # Delay
    addi x0, x0, 0
    addi x0, x0, 0
    
    # Ler RPM
    lw x10, 0(x2)          # x10 = RPM
    
    # Ler Temp
    lw x12, 8(x2)          # x12 = Temp Motor
    
    # Inicializar flags = 0
    addi x20, x0, 0
    
    # Verificar RPM > 6500
    addi x21, x0, 2047
    addi x21, x21, 2047
    addi x21, x21, 2047
    addi x21, x21, 359     # x21 = 6500
    blt x10, x21, check_temp_simple
    addi x20, x20, 1       # Setar bit 0
    
check_temp_simple:
    # Verificar Temp > 120
    addi x21, x0, 120
    blt x12, x21, save_flags_simple
    addi x20, x20, 2       # Setar bit 1
    
save_flags_simple:
    sw x20, 16(x3)         # Salvar flags
    
    # Escrever avanço fixo = 12
    addi x25, x0, 12
    sw x25, 0(x3)
    
    # Escrever injeção fixa = 1300
    addi x26, x0, 1300
    sw x26, 4(x3)

halt_simple:
    beq x0, x0, halt_simple
