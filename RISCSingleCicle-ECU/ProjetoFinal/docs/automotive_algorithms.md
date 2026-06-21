# Algoritmos de Controle Automotivo - ECU Single-Cycle

## Visão Geral

Este documento descreve os algoritmos implementados para controle de ignição e injeção de combustível em um motor monocilíndrico de combustão interna.

## 1. Algoritmo de Controle de Ignição

### 1.1 Objetivo

Determinar o momento ideal para disparar a ignição (avanço de ignição) baseado nas condições operacionais do motor.

### 1.2 Parâmetros de Entrada

- **RPM**: Rotação do motor (500-7000 RPM)
- **TPS**: Posição do acelerador (0-100%)
- **Temperatura do Motor**: Temperatura do líquido de arrefecimento (0-150°C)
- **Temperatura do Ar**: Temperatura do ar admitido (-20 a 60°C)

### 1.3 Fluxo do Algoritmo

```
┌─────────────────────────────────┐
│  Ler Sensores (RPM, TPS, Temp)  │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Normalizar RPM para índice 0-7 │
│  idx_rpm = RPM / 1000           │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Normalizar TPS para índice 0-7 │
│  idx_tps = TPS / 14             │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Calcular endereço na tabela    │
│  addr = 64 + (idx_rpm×8+idx_tps)│
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Carregar avanço base da tabela │
│  advance = lookup_table[addr]   │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Aplicar Correção por Temp.     │
│  Se temp < 60°C: advance -= 3   │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Limitar entre 5° e 35°         │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Verificar Safety Flags         │
│  Se overrev/overheat: advance=5 │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Escrever avanço no atuador     │
└─────────────────────────────────┘
```

### 1.4 Lookup Table

A tabela 8×8 contém valores de avanço otimizados para diferentes condições:

**Princípios:**
1. **Baixo RPM + Baixa Carga**: Avanço moderado (10-15°) para estabilidade
2. **Alto RPM + Alta Carga**: Avanço elevado (25-35°) para máxima potência
3. **Progressão Suave**: Valores aumentam gradualmente para evitar knock

### 1.5 Correções por Temperatura

#### Motor Frio (< 60°C)
- **Problema**: Combustão menos eficiente, maior risco de batida de pino
- **Solução**: Reduzir avanço em 3°
- **Razão**: Combustível frio vaporiza mais lentamente

#### Motor Normal (60-100°C)
- **Ação**: Usar valor da tabela sem correção
- **Condição Ideal**: Melhor eficiência térmica

#### Motor Quente (> 100°C)
- **Problema**: Risco de detonação aumentado
- **Solução**: Manter ou aumentar avanço ligeiramente
- **Nota**: Sistema de segurança pode reduzir potência se > 120°C

### 1.6 Pseudocódigo

```python
def calculate_ignition_advance(rpm, tps, temp_motor):
    # Normalizar entradas
    idx_rpm = min(rpm // 1000, 7)
    idx_tps = min(tps // 14, 7)
    
    # Consultar tabela
    address = 64 + (idx_rpm * 8 + idx_tps)
    advance = lookup_table[address]
    
    # Correção por temperatura
    if temp_motor < 60:
        advance -= 3  # Motor frio
    
    # Limitar
    advance = max(5, min(35, advance))
    
    # Safety override
    if rpm > 6500 or temp_motor > 120:
        advance = 5  # Avanço mínimo por segurança
    
    return advance
```

## 2. Algoritmo de Controle de Injeção

### 2.1 Objetivo

Calcular a duração do pulso do injetor para manter a razão ar/combustível adequada.

### 2.2 Parâmetros de Entrada

- **MAP**: Pressão no coletor de admissão (kPa)
- **RPM**: Rotação do motor
- **TPS**: Posição do acelerador
- **Temperatura do Ar**: Para densidade do ar
- **Temperatura do Motor**: Para estado de aquecimento

### 2.3 Equações Base

#### Tempo de Injeção Base
```
tempo_base = constante × (MAP / RPM)
```

**Razão**: 
- MAP ↑ = mais ar = mais combustível necessário
- RPM ↑ = menos tempo por ciclo = pulso mais curto

#### Correção por Densidade do Ar
```
fator_ar = 1.0 + ((20 - temp_ar) × 0.02)
```

**Exemplo**:
- Temp_ar = 0°C: fator = 1.4 (40% mais combustível)
- Temp_ar = 20°C: fator = 1.0 (normal)
- Temp_ar = 40°C: fator = 0.6 (40% menos combustível)

#### Correção por Motor Frio
```
se temp_motor < 60°C:
    fator_motor = 1.2  (20% mais combustível)
senão:
    fator_motor = 1.0
```

### 2.4 Cálculo Final

```
tempo_injecao = tempo_base × fator_ar × fator_motor
```

### 2.5 Razões Ar/Combustível Target

| Condição | Lambda | Razão A/F | Descrição |
|----------|--------|-----------|-----------|
| Cruzeiro | 14.7:1 | Estequiométrico | Máxima eficiência |
| Potência | 12.5:1 | Rico | Máxima potência |
| Economia | 16:1 | Pobre | Economia (cuidado com EGT) |
| Partida Fria | 10:1 | Muito Rico | Facilita ignição |

### 2.6 Fluxo do Algoritmo

```
┌─────────────────────────────────┐
│  Ler MAP, RPM, Temperaturas     │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Calcular tempo base            │
│  base = (MAP × 10) + 1000       │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Correção por Temp. do Ar       │
│  Se ar frio: aumentar 10%       │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Correção por Temp. do Motor    │
│  Se motor frio: aumentar 20%    │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Verificar Safety Flags         │
│  Se overrev: cortar injeção (0) │
└────────────┬────────────────────┘
             │
             v
┌─────────────────────────────────┐
│  Escrever tempo no atuador      │
└─────────────────────────────────┘
```

### 2.7 Pseudocódigo

```python
def calculate_injection_time(map_sensor, rpm, temp_ar, temp_motor):
    # Base calculation
    tempo_base = 1000  # microseconds
    tempo = (map_sensor * 10) + tempo_base
    
    # Air temperature correction
    if temp_ar < 20:
        correction = tempo * 10 // 100  # 10%
        tempo += correction
    
    # Engine temperature correction
    if temp_motor < 60:
        correction = tempo * 20 // 100  # 20%
        tempo += correction
    
    # Safety limits
    if rpm > 6500:
        tempo = 0  # Rev limiter - fuel cut
    
    tempo = min(tempo, 5000)  # Maximum 5ms
    
    return tempo
```

## 3. Sistema de Segurança (Safety)

### 3.1 Proteções Implementadas

#### 3.1.1 Over-Rev (Limitador de RPM)

**Condição**: RPM > 6500

**Ações**:
1. Setar flag bit 0 (OVERREV)
2. Cortar injeção (tempo = 0)
3. Reduzir avanço para mínimo (5°)

**Objetivo**: Proteger motor de danos mecânicos

#### 3.1.2 Overheat (Superaquecimento)

**Condição**: Temp > 120°C

**Ações**:
1. Setar flag bit 1 (OVERHEAT)
2. Reduzir avanço para mínimo (5°)
3. Se temp > 130°C: modo emergência (desligar)

**Objetivo**: Prevenir dano térmico ao motor

#### 3.1.3 Sensor Fault Detection

**Validações**:
- TPS: 0-100% (fora disso = erro)
- RPM: 0-7000 (fora disso = erro)
- Temperaturas: -40 a 150°C

### 3.2 Modos de Operação

```
┌─────────────────────────────────┐
│       MODO NORMAL               │
│  - Todos sensores OK            │
│  - Parâmetros dentro da faixa   │
│  - Operação conforme algoritmos │
└────────────┬────────────────────┘
             │
             │ (RPM > 6500)
             v
┌─────────────────────────────────┐
│      MODO LIMITADO              │
│  - Rev limiter ativo            │
│  - Corte de injeção             │
│  - Retorna ao normal quando OK  │
└────────────┬────────────────────┘
             │
             │ (Temp > 120°C)
             v
┌─────────────────────────────────┐
│     MODO EMERGÊNCIA             │
│  - Redução de potência          │
│  - Avanço mínimo                │
│  - Alerta ao operador           │
└────────────┬────────────────────┘
             │
             │ (Temp > 130°C)
             v
┌─────────────────────────────────┐
│      SHUTDOWN                   │
│  - Desligar motor               │
│  - Proteção total               │
└─────────────────────────────────┘
```

## 4. Sincronização com TDC

### 4.1 Importância

O sensor TDC (Top Dead Center) indica quando o pistão está no ponto morto superior. A ignição deve ocorrer **antes** do TDC pelo valor do avanço calculado.

### 4.2 Timing

```
    Ciclo de 4 Tempos
    
    ↑ TDC (0°)
    │         ← Ignição ocorre aqui (ex: -25°)
    │
    ├─────────── Compressão
    │
    │
    ├─────────── Explosão/Expansão
    │
    ↓ PMI (180°)
```

### 4.3 Algoritmo de Sincronização

```assembly
wait_tdc:
    lw x21, 0x1014      # Ler sensor TDC
    beq x21, x0, wait_tdc  # Loop até TDC = 1
    
    # TDC detectado - disparar ignição
    addi x21, x0, 1
    sw x21, 0x2008      # Trigger = 1
    
    # Delay curto
    nop
    nop
    
    # Desligar trigger
    addi x21, x0, 0
    sw x21, 0x2008      # Trigger = 0
```

### 4.4 Considerações de Tempo Real

Para motor a 6000 RPM:
- Período = 10ms por revolução
- 1° = 27.8μs
- Avanço de 30° = 833μs antes do TDC

**Requisito**: O processador deve calcular avanço e injeção em menos de 1ms para garantir resposta adequada.

## 5. Calibração e Tuning

### 5.1 Ajuste da Lookup Table

Para otimizar desempenho:

1. **Dyno Testing**: Testar motor em dinamômetro
2. **Otimização por Célula**: Ajustar cada entrada da tabela
3. **Critérios**: Máxima potência sem knock
4. **Ferramentas**: Software de edição de mapas

### 5.2 Fatores de Correção

Podem ser ajustados conforme características do motor:

```verilog
// Na data_memory
Memory_cell[0] = 32'd147;  // Lambda target
Memory_cell[2] = 32'd1000; // Tempo base injeção
Memory_cell[5] = 32'd60;   // Threshold enriquecimento
```

### 5.3 Logs e Diagnóstico

Para análise pós-teste, monitorar:
- Valores de sensores ao longo do tempo
- Avanço calculado vs aplicado
- Safety flags ativadas
- Temperatura vs tempo

## 6. Limitações e Melhorias Futuras

### 6.1 Limitações Atuais

1. **Controle Open-Loop**: Sem feedback de Lambda (sensor O2)
2. **Interpolação**: Lookup direto sem interpolação entre pontos
3. **Divisão Inteira**: Sem ponto flutuante
4. **Single-Cylinder**: Apenas 1 cilindro

### 6.2 Melhorias Propostas

1. **Closed-Loop Control**: Adicionar sensor Lambda
2. **Interpolação Linear**: Suavizar transições
3. **Knock Detection**: Sensor de detonação
4. **Multi-Cylinder**: Sequenciamento de 4 cilindros
5. **Adaptive Learning**: Ajuste automático de mapas
6. **Idle Speed Control**: Controle de marcha lenta

## Referências

- SAE J1979 - OBD-II Standards
- Bosch Automotive Handbook
- RISC-V Instruction Set Manual
- Engine Management: Advanced Tuning (Greg Banish)
