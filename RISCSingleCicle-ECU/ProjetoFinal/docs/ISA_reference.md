# ISA Reference - Processador RISC-V Single-Cycle ECU

## Instruções Implementadas

Este processador implementa um subconjunto do RISC-V com extensões para operações aritméticas necessárias ao controle automotivo.

### Tipo R - Operações entre Registradores

| Instrução | Formato | Opcode | Funct3 | Funct7 | Descrição |
|-----------|---------|--------|--------|--------|-----------|
| ADD | `add rd, rs1, rs2` | 0110011 | 000 | 0000000 | rd = rs1 + rs2 |
| SUB | `sub rd, rs1, rs2` | 0110011 | 000 | 0100000 | rd = rs1 - rs2 |
| MUL | `mul rd, rs1, rs2` | 0110011 | 001 | 0000001 | rd = rs1 * rs2 |
| DIV | `div rd, rs1, rs2` | 0110011 | 100 | 0000001 | rd = rs1 / rs2 |
| MOD | `rem rd, rs1, rs2` | 0110011 | 101 | 0000001 | rd = rs1 % rs2 |
| AND | `and rd, rs1, rs2` | 0110011 | 111 | 0000000 | rd = rs1 & rs2 |
| OR | `or rd, rs1, rs2` | 0110011 | 110 | 0000000 | rd = rs1 | rs2 |
| SLT | `slt rd, rs1, rs2` | 0110011 | 010 | 0000000 | rd = (rs1 < rs2) ? 1 : 0 |

### Tipo I - Operações Imediatas e Load

| Instrução | Formato | Opcode | Funct3 | Descrição |
|-----------|---------|--------|--------|-----------|
| ADDI | `addi rd, rs1, imm` | 0010011 | 000 | rd = rs1 + imm |
| ANDI | `andi rd, rs1, imm` | 0010011 | 111 | rd = rs1 & imm |
| LW | `lw rd, imm(rs1)` | 0000011 | 010 | rd = Mem[rs1 + imm] |

### Tipo S - Store

| Instrução | Formato | Opcode | Funct3 | Descrição |
|-----------|---------|--------|--------|-----------|
| SW | `sw rs2, imm(rs1)` | 0100011 | 010 | Mem[rs1 + imm] = rs2 |

### Tipo B - Branch (Desvios Condicionais)

| Instrução | Formato | Opcode | Funct3 | Descrição |
|-----------|---------|--------|--------|-----------|
| BEQ | `beq rs1, rs2, label` | 1100011 | 000 | if (rs1 == rs2) PC += offset |
| BNE | `bne rs1, rs2, label` | 1100011 | 001 | if (rs1 != rs2) PC += offset |
| BLT | `blt rs1, rs2, label` | 1100011 | 100 | if (rs1 < rs2) PC += offset |
| BGE | `bge rs1, rs2, label` | 1100011 | 101 | if (rs1 >= rs2) PC += offset |

### Tipo J - Jump

| Instrução | Formato | Opcode | Descrição |
|-----------|---------|--------|-----------|
| JAL | `jal rd, label` | 1101111 | rd = PC + 4; PC += offset |

## Registradores

O processador possui 32 registradores de propósito geral (x0-x31):

- **x0**: Sempre zero (zero register)
- **x1**: Endereço de retorno (ra - return address)
- **x2**: Stack pointer (sp)
- **x10-x17**: Argumentos e valores de retorno (a0-a7)
- **x20-x27**: Salvos (s0-s11)

## Formato das Instruções

### Tipo R
```
|   funct7   |  rs2  |  rs1  | funct3 |   rd   | opcode |
| 31      25 | 24 20 | 19 15 | 14  12 | 11   7 | 6    0 |
```

### Tipo I
```
|      imm[11:0]      |  rs1  | funct3 |   rd   | opcode |
| 31              20  | 19 15 | 14  12 | 11   7 | 6    0 |
```

### Tipo S
```
| imm[11:5] |  rs2  |  rs1  | funct3 |imm[4:0]| opcode |
| 31     25 | 24 20 | 19 15 | 14  12 | 11   7 | 6    0 |
```

### Tipo B
```
|imm[12|10:5]|  rs2  |  rs1  | funct3 |imm[4:1|11]| opcode |
| 31      25 | 24 20 | 19 15 | 14  12 | 11      7 | 6    0 |
```

### Tipo J
```
|        imm[20|10:1|11|19:12]          |   rd   | opcode |
| 31                                 12 | 11   7 | 6    0 |
```

## Convenções de Assembly

### Comentários
```assembly
# Isto é um comentário
```

### Labels
```assembly
main_loop:      # Define um label
    addi x1, x1, 1
    jal x0, main_loop  # Volta para o label
```

### Valores Imediatos
- Decimal: `10`, `255`, `-5`
- Hexadecimal: `0x10`, `0xFF`, `0x1000`
- Binário: `0b1010`, `0b11111111`

## Exemplos de Uso

### Exemplo 1: Loop Simples
```assembly
    addi x1, x0, 10     # x1 = 10 (contador)
loop:
    addi x1, x1, -1     # Decrementar
    bne x1, x0, loop    # Loop enquanto x1 != 0
```

### Exemplo 2: Cálculo com Multiplicação
```assembly
    addi x1, x0, 5      # x1 = 5
    addi x2, x0, 3      # x2 = 3
    mul x3, x1, x2      # x3 = 5 * 3 = 15
```

### Exemplo 3: Acesso à Memória
```assembly
    addi x1, x0, 100    # x1 = 100 (endereço)
    addi x2, x0, 42     # x2 = 42 (valor)
    sw x2, 0(x1)        # Mem[100] = 42
    lw x3, 0(x1)        # x3 = Mem[100] = 42
```

### Exemplo 4: Divisão com Proteção
```assembly
    addi x1, x0, 100    # Dividendo
    addi x2, x0, 5      # Divisor
    beq x2, x0, error   # Verificar divisão por zero
    div x3, x1, x2      # x3 = 100 / 5 = 20
    jal x0, continue
error:
    addi x3, x0, -1     # Valor de erro
continue:
    # continuar...
```

## Notas de Implementação

1. **Divisão por Zero**: A ALU retorna 0xFFFFFFFF para divisão por zero e 0 para módulo por zero.

2. **Overflow**: Não há tratamento de overflow - resultados usam apenas os 32 bits menos significativos.

3. **Single-Cycle**: Todas as instruções executam em 1 ciclo de clock.

4. **Memory-Mapped I/O**: Endereços >= 0x1000 são mapeados para I/O.
