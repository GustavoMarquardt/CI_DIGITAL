# Quick Start Guide - ECU Single-Cycle

Guia rápido para compilar e executar o projeto.

## 🚀 Início Rápido

### Opção 1: Simulação com ModelSim/QuestaSim

```bash
# 1. Navegue até o diretório do projeto
cd c:\dev\CI_DIGITAL\RISCSingleCicle-ECU\ProjetoFinal

# 2. Compile todos os módulos
vlog módulos/*.v

# 3. Compile o testbench desejado
vlog testbenches/cpu_complete_tb.v

# 4. Execute a simulação
vsim -c cpu_complete_tb -do "run -all; quit"
```

### Opção 2: Simulação Automotiva Completa

```bash
# Compilar módulos + testbench automotivo
vlog módulos/*.v testbenches/ecu_automotive_tb.v

# Executar (modo console)
vsim -c ecu_automotive_tb -do "run -all; quit"

# OU executar com GUI e waveforms
vsim ecu_automotive_tb
# No TCL console:
add wave -r /*
run -all
```

### Opção 3: Testar I/O Controller

```bash
# Compilar
vlog módulos/io_controller.v testbenches/io_controller_tb.v

# Executar
vsim -c io_controller_tb -do "run -all; quit"
```

## 📝 Modificar o Programa Assembly

### 1. Editar Assembly

Edite `programs/ecu_control.asm` com seu programa.

### 2. Montar para Código de Máquina

```bash
python tools/assembler.py programs/ecu_control.asm programs/output.v
```

### 3. Copiar para Instruction Memory

Copie o código gerado e cole no bloco `initial` de `módulos/instruction_memory.v`:

```verilog
initial begin
    // Cole aqui as instruções geradas pelo assembler
    instruction[0] = 32'b...;
    instruction[1] = 32'b...;
    // ...
end
```

### 4. Recompilar e Testar

```bash
vlog módulos/*.v testbenches/ecu_automotive_tb.v
vsim -c ecu_automotive_tb -do "run -all; quit"
```

## 🔍 Verificar Resultados

### Saída do Console

A simulação imprime informações úteis:

```
========================================================================
     ECU AUTOMOTIVE TESTBENCH - Motor Monocilíndrico
========================================================================

CENÁRIO 1: MARCHA LENTA (IDLE)
Objetivo: Validar operação estável em marcha lenta
Condições: RPM=800, TPS=0%, Temp=90°C

T=100 | RPM=800 TPS=0 TempM=90 TempA=25 MAP=30 | Adv=12 Inj=1300 Trig=0 Flags=0
✓ PASS: Avanço de ignição adequado para marcha lenta
...
```

### Waveforms (GTKWave ou ModelSim GUI)

Se executou com GUI, você pode visualizar:
- Sinais de sensores ao longo do tempo
- Valores calculados de avanço e injeção
- Triggers de ignição
- Safety flags

## 🎛️ Cenários de Teste Disponíveis

O `ecu_automotive_tb.v` testa automaticamente 6 cenários:

1. **IDLE (0)** - Marcha lenta estável
2. **COLD_START (1)** - Arranque a frio
3. **ACCELERATION (2)** - Aceleração 0→100%
4. **CRUISE (3)** - Cruzeiro constante
5. **OVERREV (4)** - Teste de limitador
6. **OVERHEAT (5)** - Proteção térmica

Para testar cenário específico, modifique o testbench:

```verilog
// Em ecu_automotive_tb.v
test_scenario = 3'd2; // ACCELERATION
```

## 🛠️ Customizar Lookup Table

### Método 1: Usar Gerador Automático

```bash
python tools/lookup_table_generator.py
```

Copie a saída para o bloco `initial` de `data_memory.v`.

### Método 2: Editar Manualmente

Edite diretamente em `módulos/data_memory.v`:

```verilog
// Endereços 64-127 (Lookup Table)
Memory_cell[64] = 32'd10;  // RPM=1000, TPS=0%, Avanço=10°
Memory_cell[65] = 32'd12;  // RPM=1000, TPS=14%, Avanço=12°
// ...
```

## 🐛 Troubleshooting

### Erro: "Unknown instruction"

**Problema**: O assembler não reconhece a instrução.

**Solução**: Verifique se a instrução está na lista suportada (ISA_reference.md).

### Erro: Compilation failed

**Problema**: Erro de sintaxe em Verilog.

**Solução**: 
1. Verifique se todos os arquivos `.v` estão presentes
2. Verifique sintaxe (ponto e vírgula, parênteses)
3. Certifique-se de que não há erros de digitação

### Simulação trava/congela

**Problema**: Loop infinito ou clock não está rodando.

**Solução**:
1. Verifique se o clock está definido no testbench
2. Adicione `$finish` após tempo razoável
3. Use `run 10000` ao invés de `run -all` para limitar tempo

### Valores estranhos nos sensores

**Problema**: Sensor_simulator não está gerando valores corretos.

**Solução**: Verifique se `test_scenario` está setado corretamente e se o módulo está instanciado.

## 📊 Monitorar Execução

### Adicionar Displays Customizados

No testbench, adicione:

```verilog
always @(posedge clk) begin
    $display("RPM=%d, Avanço=%d°", sensor_rpm, ignition_advance);
end
```

### Salvar Waveforms

```bash
# No início do testbench
initial begin
    $dumpfile("simulation.vcd");
    $dumpvars(0, ecu_automotive_tb);
end

# Depois da simulação, abrir com GTKWave
gtkwave simulation.vcd
```

## 🎯 Próximos Passos

1. ✅ **Simular** - Execute todos os testbenches
2. ✅ **Validar** - Verifique se todos os PASS aparecem
3. ✅ **Experimentar** - Modifique valores na lookup table
4. ✅ **Expandir** - Adicione novos sensores ou algoritmos
5. 📌 **Sintetizar** (opcional) - Teste em FPGA real

## 📚 Documentação Adicional

- `README.md` - Visão geral completa do projeto
- `docs/ISA_reference.md` - Todas as instruções suportadas
- `docs/memory_map.md` - Endereços de sensores e atuadores
- `docs/automotive_algorithms.md` - Detalhes dos algoritmos

## 💡 Dicas

1. **Começe Simples**: Teste primeiro o `cpu_complete_tb.v` antes do automotivo
2. **Use Waveforms**: Visualize sinais para entender o comportamento
3. **Debug Incremental**: Teste cada módulo separadamente antes de integrar
4. **Documente**: Adicione comentários ao modificar o código
5. **Version Control**: Use git para rastrear mudanças

## 🎓 Para Apresentação/Relatório

Demonstrações sugeridas:

1. **Demonstração Básica**: Mostrar execução de instruções (cpu_complete_tb)
2. **Demonstração I/O**: Leitura de sensores e escrita em atuadores
3. **Demonstração Automotiva**: 6 cenários completos com resultados
4. **Demonstração de Segurança**: Over-rev e overheat em ação
5. **Análise de Waveforms**: Mostrar sincronização com TDC e trigger de ignição

---

**Tempo Estimado de Simulação**: ~2-5 segundos por cenário

**Sucesso**: Todos os testes devem mostrar "✓ PASS" na saída
