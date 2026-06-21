# Mapa de Memória - ECU Single-Cycle

## Visão Geral

O processador ECU utiliza um esquema de endereçamento de 32 bits dividido em três regiões principais:

```
0x00000000 - 0x00000FFF: Data Memory (4KB)
0x00001000 - 0x00001FFF: Sensores (Read-Only)
0x00002000 - 0x00002FFF: Atuadores (Write/Read)
```

## Data Memory (0x0000 - 0x0FFF)

### Região de Constantes (0x0000 - 0x0014)

| Endereço | Conteúdo | Valor | Descrição |
|----------|----------|-------|-----------|
| 0x0000 | Lambda estequiométrico | 147 | Razão ar/combustível × 10 (14.7:1) |
| 0x0004 | Lambda potência | 125 | Razão rica × 10 (12.5:1) |
| 0x0008 | Tempo base injeção | 1000 | Tempo base em microsegundos |
| 0x000C | RPM limite | 6500 | Limitador de rotação (rev limiter) |
| 0x0010 | Temperatura limite | 120 | Limite de temperatura (°C) |
| 0x0014 | Temp. enriquecimento | 60 | Temperatura para enriquecimento (°C) |

### Região de Dados Gerais (0x0018 - 0x00FF)

Disponível para uso do programa (variáveis, stack, etc.)

### Lookup Table de Ignição (0x0100 - 0x01FC)

Tabela 8×8 de avanço de ignição (64 entradas × 4 bytes = 256 bytes)

**Estrutura:**
- Eixo RPM (8 valores): 1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000
- Eixo TPS (8 valores): 0%, 14%, 28%, 42%, 56%, 70%, 84%, 100%

**Cálculo de Endereço:**
```
endereço = 0x0100 + (idx_rpm × 8 + idx_tps) × 4
```

**Exemplo:**
```
RPM = 3000 (índice 4), TPS = 56% (índice 4)
Endereço = 0x0100 + (4 × 8 + 4) × 4 = 0x0100 + 144 = 0x0190
```

**Tabela Completa:**

```
       TPS:  0%   14%  28%  42%  56%  70%  84% 100%
RPM 1000:   10°  12°  14°  16°  18°  18°  19°  20°
RPM 1500:   11°  13°  15°  18°  19°  20°  20°  21°
RPM 2000:   13°  15°  17°  19°  21°  21°  22°  23°
RPM 2500:   14°  16°  18°  21°  22°  23°  23°  24°
RPM 3000:   16°  18°  20°  22°  24°  24°  25°  26°
RPM 4000:   19°  21°  23°  25°  27°  27°  28°  29°
RPM 5000:   22°  24°  26°  28°  30°  30°  31°  32°
RPM 6000:   25°  27°  29°  31°  33°  33°  34°  35°
```

## Sensores (Read-Only) - 0x1000+

### Endereços dos Sensores

| Endereço | Sensor | Bits | Faixa | Descrição |
|----------|--------|------|-------|-----------|
| 0x1000 | RPM | 16 | 0-7000 | Rotações por minuto do motor |
| 0x1004 | TPS | 8 | 0-100 | Throttle Position Sensor (% abertura) |
| 0x1008 | Temp Motor | 8 | 0-150 | Temperatura do líquido de arrefecimento (°C) |
| 0x100C | Temp Ar | 8 | -20-60 | Temperatura do ar admitido (°C) |
| 0x1010 | MAP | 8 | 0-100 | Manifold Absolute Pressure (kPa normalizado) |
| 0x1014 | TDC | 1 | 0-1 | Top Dead Center sensor (pulso) |

### Exemplo de Leitura

```assembly
    addi x2, x0, 0x1000     # Base dos sensores
    lw x10, 0(x2)           # x10 = RPM
    lw x11, 4(x2)           # x11 = TPS
    lw x12, 8(x2)           # x12 = Temp Motor
    lw x13, 12(x2)          # x13 = Temp Ar
    lw x14, 16(x2)          # x14 = MAP
    lw x15, 20(x2)          # x15 = TDC
```

## Atuadores (Write/Read) - 0x2000+

### Endereços dos Atuadores

| Endereço | Atuador | Bits | Faixa | Descrição |
|----------|---------|------|-------|-----------|
| 0x2000 | Avanço Ignição | 8 | 5-35 | Graus antes do TDC |
| 0x2004 | Tempo Injeção | 16 | 0-5000 | Duração do pulso do injetor (μs) |
| 0x2008 | Trigger Ignição | 1 | 0-1 | Sinal de disparo da bobina |
| 0x2010 | Safety Flags | 8 | - | Flags de segurança (read/write) |

### Safety Flags (0x2010)

| Bit | Nome | Descrição |
|-----|------|-----------|
| 0 | OVERREV | RPM acima do limite (6500) |
| 1 | OVERHEAT | Temperatura acima do limite (120°C) |
| 2 | TPS_ERROR | Erro no sensor TPS |
| 3 | RPM_ERROR | Erro no sensor RPM |
| 4-7 | RESERVED | Reservado para uso futuro |

### Exemplo de Escrita

```assembly
    addi x3, x0, 0x2000     # Base dos atuadores
    addi x20, x0, 25        # Avanço = 25°
    sw x20, 0(x3)           # Escrever avanço
    
    addi x21, x0, 1500      # Tempo inj = 1500μs
    sw x21, 4(x3)           # Escrever tempo injeção
    
    addi x22, x0, 1         # Trigger = 1
    sw x22, 8(x3)           # Disparar ignição
```

## Fluxo Típico de Controle

```
1. Ler Sensores (0x1000+)
   ├─ RPM, TPS, Temperaturas, MAP, TDC
   
2. Processar Dados
   ├─ Normalizar valores
   ├─ Consultar Lookup Table (0x0100+)
   ├─ Aplicar correções
   └─ Verificar limites de segurança
   
3. Escrever Atuadores (0x2000+)
   ├─ Avanço de ignição
   ├─ Tempo de injeção
   └─ Safety flags
   
4. Aguardar TDC e Disparar Ignição
   
5. Loop (voltar ao passo 1)
```

## Diagrama de Memória

```
┌─────────────────────────────────────┐ 0x00000000
│  Constantes (24 bytes)              │
├─────────────────────────────────────┤ 0x00000018
│                                     │
│  Dados Gerais (232 bytes)           │
│                                     │
├─────────────────────────────────────┤ 0x00000100
│                                     │
│  Lookup Table Ignição (256 bytes)   │
│  [Tabela 8x8 de avanço]             │
│                                     │
├─────────────────────────────────────┤ 0x00000200
│                                     │
│  Espaço Livre                       │
│                                     │
└─────────────────────────────────────┘ 0x00000FFF

┌─────────────────────────────────────┐ 0x00001000
│  SENSORES (Read-Only)               │
│  ├─ 0x1000: RPM                     │
│  ├─ 0x1004: TPS                     │
│  ├─ 0x1008: Temp Motor              │
│  ├─ 0x100C: Temp Ar                 │
│  ├─ 0x1010: MAP                     │
│  └─ 0x1014: TDC                     │
└─────────────────────────────────────┘ 0x00001FFF

┌─────────────────────────────────────┐ 0x00002000
│  ATUADORES (Write/Read)             │
│  ├─ 0x2000: Avanço Ignição          │
│  ├─ 0x2004: Tempo Injeção           │
│  ├─ 0x2008: Trigger Ignição         │
│  └─ 0x2010: Safety Flags            │
└─────────────────────────────────────┘ 0x00002FFF
```

## Notas Importantes

1. **Alinhamento**: Todos os acessos devem ser alinhados em 4 bytes (word-aligned).

2. **Endereçamento**: O processador usa endereçamento byte-addressable, mas a memória é organizada em words de 32 bits.

3. **I/O Memory-Mapped**: Endereços >= 0x1000 são automaticamente roteados para o I/O controller ao invés da data memory.

4. **Proteção**: Tentativas de escrita em endereços de sensores (0x1000+) são ignoradas silenciosamente.

5. **Valores Padrão**: Atuadores são inicializados com valores seguros no reset:
   - Avanço: 15°
   - Tempo injeção: 1000μs
   - Trigger: 0
   - Safety flags: 0
