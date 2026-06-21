# Processador RISC-V Single-Cycle para ECU Automotiva

Projeto acadêmico de um processador RISC-V single-cycle aplicado ao controle eletrônico de motor monocilíndrico de combustão interna.

## 📋 Visão Geral

Este projeto implementa um processador RISC-V de ciclo único dedicado ao gerenciamento de parâmetros críticos de um motor a combustão:
- **Controle de Ponto de Ignição**: Cálculo dinâmico do avanço baseado em RPM, TPS e temperatura
- **Controle de Mistura Ar/Combustível**: Ajuste do tempo de injeção para otimizar combustão
- **Sistema de Segurança**: Proteção contra over-rev e superaquecimento

## 🏗️ Arquitetura

### Componentes Principais

```
┌──────────────────────────────────────────────┐
│              CPU Single-Cycle                │
│  ┌────────┐  ┌─────┐  ┌──────────────────┐  │
│  │   PC   │→ │ IM  │→ │  Control Unit    │  │
│  └────────┘  └─────┘  └──────────────────┘  │
│       ↓                      ↓               │
│  ┌────────┐  ┌─────┐  ┌──────────────────┐  │
│  │RegFile │←→│ ALU │←→│  Data Memory     │  │
│  └────────┘  └─────┘  └──────────────────┘  │
│                            ↕                 │
│                     ┌──────────────┐         │
│                     │ I/O Controller│        │
│                     └──────────────┘         │
└──────────────┬───────────────────────────────┘
               │
    ┌──────────┴──────────┐
    ↓                     ↓
┌─────────┐          ┌──────────┐
│Sensores │          │Atuadores │
└─────────┘          └──────────┘
```

### Instruções Suportadas

**Tipo R**: ADD, SUB, MUL, DIV, MOD, AND, OR, SLT  
**Tipo I**: ADDI, ANDI, LW  
**Tipo S**: SW  
**Tipo B**: BEQ, BNE, BLT, BGE  
**Tipo J**: JAL

## 📁 Estrutura do Projeto

```
ProjetoFinal/
├── módulos/
│   ├── cpu.v                    # CPU principal
│   ├── ALU.v                    # Unidade Aritmética (com MUL/DIV)
│   ├── Control_Unit.v           # Unidade de controle
│   ├── Main_Decoder.v           # Decodificador principal
│   ├── ULA_Decoder.v            # Decodificador da ALU
│   ├── data_memory.v            # Memória de dados + Lookup Table
│   ├── instruction_memory.v     # Memória de instruções
│   ├── io_controller.v          # Controlador I/O memory-mapped
│   ├── sensor_simulator.v       # Simulador de sensores automotivos
│   └── [outros módulos]
│
├── testbenches/
│   ├── cpu_complete_tb.v        # TB completo do processador
│   ├── io_controller_tb.v       # TB do I/O controller
│   └── ecu_automotive_tb.v      # TB automotivo com 6 cenários
│
├── programs/
│   └── ecu_control.asm          # Programa assembly da ECU
│
├── tools/
│   ├── assembler.py             # Montador RISC-V
│   └── lookup_table_generator.py # Gerador de tabela de ignição
│
└── docs/
    ├── ISA_reference.md         # Referência do ISA
    ├── memory_map.md            # Mapa de memória
    └── automotive_algorithms.md # Algoritmos de controle
```

## 🚀 Implementação Completa

### ✅ Fase 1 - Núcleo do Processador
- [x] ALU expandida com MUL, DIV, MOD
- [x] Suporte a BNE (Branch Not Equal)
- [x] Instruções: ADD, SUB, MUL, DIV, MOD, AND, OR, SLT, ADDI, LW, SW, BEQ, BNE, JAL
- [x] Testbench completo validando todas as operações

### ✅ Fase 2 - Interface com Sensores/Atuadores
- [x] Módulo `io_controller.v` com I/O memory-mapped
- [x] Mapeamento de endereços:
  - **0x1000+**: Sensores (RPM, TPS, Temp Motor, Temp Ar, MAP, TDC)
  - **0x2000+**: Atuadores (Avanço, Tempo Injeção, Trigger, Flags)
- [x] Simulador de sensores com 6 cenários de teste
- [x] Integração completa com CPU

### ✅ Fase 3 - Lógica de Controle Automotiva
- [x] Lookup Table 8×8 de ignição na memória
- [x] Programa assembly ECU com:
  - Leitura de sensores
  - Verificação de segurança
  - Cálculo de ignição (com lookup table)
  - Cálculo de injeção
  - Sincronização com TDC
- [x] Assembler Python completo
- [x] Testbench automotivo com 6 cenários:
  1. Marcha lenta (idle)
  2. Arranque a frio
  3. Aceleração gradual
  4. Regime de cruzeiro
  5. Proteção over-rev
  6. Proteção superaquecimento

## 🔧 Como Usar

### 1. Simulação Básica do Processador

```bash
# Compilar e simular com ModelSim/QuestaSim
vlog módulos/*.v testbenches/cpu_complete_tb.v
vsim -c cpu_complete_tb -do "run -all"
```

### 2. Montar Programa Assembly

```bash
# Converter assembly em código de máquina
python tools/assembler.py programs/ecu_control.asm output.v

# O código gerado pode ser copiado para instruction_memory.v
```

### 3. Simulação Automotiva Completa

```bash
# Simular ECU com sensores e atuadores
vlog módulos/*.v testbenches/ecu_automotive_tb.v
vsim -c ecu_automotive_tb -do "run -all"

# Gerar waveforms para análise
vsim ecu_automotive_tb
# No GUI: add wave -r /*
# run -all
```

### 4. Gerar Lookup Table Customizada

```bash
# Gerar nova tabela de ignição
python tools/lookup_table_generator.py > ignition_table.txt

# Copiar valores para data_memory.v
```

## 📊 Mapeamento de Memória

### Sensores (Read-Only)
| Endereço | Sensor | Descrição |
|----------|--------|-----------|
| 0x1000 | RPM | Rotações por minuto (0-7000) |
| 0x1004 | TPS | Posição acelerador (0-100%) |
| 0x1008 | Temp Motor | Temperatura motor (°C) |
| 0x100C | Temp Ar | Temperatura ar (°C) |
| 0x1010 | MAP | Pressão coletor (kPa) |
| 0x1014 | TDC | Sensor ponto morto superior |

### Atuadores (Write/Read)
| Endereço | Atuador | Descrição |
|----------|---------|-----------|
| 0x2000 | Avanço Ignição | Graus antes do TDC (5-35°) |
| 0x2004 | Tempo Injeção | Duração pulso injetor (μs) |
| 0x2008 | Trigger Ignição | Disparo da bobina (0/1) |
| 0x2010 | Safety Flags | Flags de segurança (8 bits) |

## 🎯 Algoritmos de Controle

### Ignição
1. Normalizar RPM e TPS para índices da tabela
2. Consultar lookup table 8×8
3. Aplicar correções por temperatura
4. Limitar entre 5° e 35°
5. Aplicar safety overrides se necessário

### Injeção
1. Calcular tempo base: `(MAP × 10) + 1000`
2. Correção por temperatura do ar (ar frio = +10%)
3. Correção por motor frio (< 60°C = +20%)
4. Rev limiter: cortar injeção se RPM > 6500

### Segurança
- **Over-Rev**: RPM > 6500 → corta injeção
- **Overheat**: Temp > 120°C → reduz avanço
- **Emergency**: Temp > 130°C → shutdown

## 📈 Resultados Esperados

### Performance
- **Clock**: 1 MHz recomendado
- **CPI**: 1 (single-cycle)
- **Latência**: < 1ms por ciclo de controle
- **Resolução Temporal**: 1μs

### Validação
- ✅ Todas as instruções testadas individualmente
- ✅ I/O memory-mapped funcional
- ✅ 6 cenários automotivos validados
- ✅ Safety systems respondendo corretamente

## 🔬 Cenários de Teste

1. **Idle**: RPM=800, validação de estabilidade
2. **Cold Start**: Temp=20°C, enriquecimento de mistura
3. **Acceleration**: 0→100% TPS, progressão de avanço
4. **Cruise**: RPM=3000 constante, estabilidade
5. **Over-Rev**: RPM>6500, ativação de limitador
6. **Overheat**: Temp>120°C, modo de segurança

## 📚 Documentação

- [`docs/ISA_reference.md`](docs/ISA_reference.md) - Conjunto de instruções completo
- [`docs/memory_map.md`](docs/memory_map.md) - Mapeamento detalhado de memória
- [`docs/automotive_algorithms.md`](docs/automotive_algorithms.md) - Algoritmos de controle

## 🛠️ Ferramentas Necessárias

- **Simulador**: ModelSim, QuestaSim, Vivado Simulator ou Verilator
- **Python 3**: Para assembler e geração de tabelas
- **GTKWave**: Para análise de waveforms (opcional)
- **FPGA** (opcional): Para síntese em hardware real

## 🎓 Propósito Acadêmico

Este projeto demonstra:
- Arquitetura de processadores RISC
- Sistemas embarcados de tempo real
- Controle eletrônico automotivo
- Design digital em Verilog/SystemVerilog
- Integração hardware-software

## 📝 Limitações e Extensões Futuras

### Limitações Atuais
- Controle open-loop (sem sensor Lambda)
- Motor monocilíndrico apenas
- Divisão inteira (sem ponto flutuante)
- Lookup direto (sem interpolação)

### Extensões Propostas
1. Pipeline de 5 estágios
2. Controle de 4 cilindros
3. Sensor Lambda + controle closed-loop
4. Knock detection
5. Idle speed control
6. Interface CAN bus
7. Síntese em FPGA

## 👥 Autor

Projeto desenvolvido para fins acadêmicos como demonstração de aplicação prática de arquitetura de processadores em contexto automotivo.

## 📄 Licença

Este projeto é de código aberto para fins educacionais.

---

**Status**: ✅ Implementação Completa - Todas as 3 fases concluídas
**Última Atualização**: Maio 2026
