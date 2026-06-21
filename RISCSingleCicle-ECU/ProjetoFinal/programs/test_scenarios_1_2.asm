# Programa para testar Cenários 1 e 2
.text
.globl main

main:
    addi x2, x0, 256       # x2 = 0x100 (base sensores)
    addi x3, x0, 512       # x3 = 0x200 (base atuadores)

    # Ler sensores
    lw x10, 0(x2)          # x10 = RPM
    lw x11, 8(x2)          # x11 = Temp Motor
    lw x12, 16(x2)         # x12 = MAP
    
    # === AVANÇO DE IGNIÇÃO ===
    # Escrever avanço = 12 (adequado para marcha lenta e motor frio)
    addi x13, x0, 12
    sw x13, 0(x3)          # Salvar em 0x200
    
    # === INJEÇÃO ===
    # Calcular injeção base: MAP * 10 + 1000
    addi x14, x0, 10
    mul x15, x12, x14      # x15 = MAP * 10
    addi x16, x0, 1000
    add x15, x15, x16      # x15 = (MAP*10) + 1000
    
    # Verificar se motor está frio (temp < 60°C)
    addi x17, x0, 60
    bge x11, x17, motor_quente
    
motor_frio:
    # Aumentar injeção em 30%
    # inj = inj + (inj * 30 / 100)
    addi x18, x0, 30
    mul x19, x15, x18      # x19 = inj * 30
    addi x20, x0, 100
    divu x19, x19, x20     # x19 = (inj * 30) / 100
    add x15, x15, x19      # x15 = inj + correção
    
motor_quente:
    sw x15, 4(x3)          # Salvar injeção em 0x204
    
    # === FLAGS ===
    # Escrever flags = 0 (sem erros)
    addi x21, x0, 0
    sw x21, 16(x3)         # Salvar em 0x210

stop:
    # Loop NOP infinito
    addi x0, x0, 0
    jal x0, stop
