#!/usr/bin/env python3
"""
Gerador de Lookup Table de Ignição para ECU
Gera valores de avanço de ignição baseados em RPM e TPS (carga)
"""

def generate_ignition_table():
    """
    Gera tabela 8x8 de avanço de ignição
    Eixo X (RPM): 1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000
    Eixo Y (TPS): 0%, 14%, 28%, 42%, 56%, 70%, 84%, 100%
    Valores: graus de avanço antes do TDC (5-35 graus)
    """
    
    # Índices da tabela
    rpm_values = [1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000]
    tps_values = [0, 14, 28, 42, 56, 70, 84, 100]
    
    print("// Lookup Table de Ignição - 8x8")
    print("// RPM (linhas): 1000, 1500, 2000, 2500, 3000, 4000, 5000, 6000")
    print("// TPS (colunas): 0%, 14%, 28%, 42%, 56%, 70%, 84%, 100%")
    print("// Endereço base: 64 (0x40)")
    print("// Endereço = 64 + (idx_rpm * 8) + idx_tps")
    print()
    
    table = []
    addr = 64  # Endereço inicial da tabela
    
    for i, rpm in enumerate(rpm_values):
        row = []
        for j, tps in enumerate(tps_values):
            # Algoritmo de cálculo do avanço:
            # - Baixo RPM + baixa carga: 10-15 graus
            # - Médio RPM + média carga: 15-25 graus
            # - Alto RPM + alta carga: 25-35 graus
            # Ajuste baseado em características típicas de motores
            
            base_advance = 10.0
            
            # Contribuição do RPM (quanto maior RPM, maior avanço)
            rpm_contribution = (rpm - 1000) / 5000 * 15  # 0 a 15 graus
            
            # Contribuição do TPS (quanto maior carga, mais avanço até certo ponto)
            if tps < 50:
                tps_contribution = tps / 50 * 8  # 0 a 8 graus
            else:
                tps_contribution = 8 + (tps - 50) / 50 * 2  # 8 a 10 graus
            
            # Cálculo final
            advance = base_advance + rpm_contribution + tps_contribution
            
            # Limitar entre 5 e 35 graus
            advance = max(5, min(35, advance))
            advance = int(advance)
            
            row.append(advance)
            
            # Gerar código Verilog
            print(f"    Memory_cell[{addr}] = 32'd{advance}; // RPM={rpm}, TPS={tps}%, Avanço={advance}°")
            addr += 1
        
        table.append(row)
    
    print()
    print("// Tabela em formato de matriz para visualização:")
    print("//      TPS:  0%   14%  28%  42%  56%  70%  84%  100%")
    for i, rpm in enumerate(rpm_values):
        print(f"// RPM {rpm:4d}: ", end="")
        for advance in table[i]:
            print(f"{advance:3d}° ", end="")
        print()

def generate_injection_constants():
    """
    Gera constantes para cálculo de tempo de injeção
    """
    print()
    print("// Constantes para cálculo de tempo de injeção")
    print("// Armazenadas em posições de memória específicas")
    print()
    print("    Memory_cell[120] = 32'd147;  // Lambda estequiométrico * 10 (14.7:1)")
    print("    Memory_cell[121] = 32'd125;  // Lambda para potência * 10 (12.5:1)")
    print("    Memory_cell[122] = 32'd1000; // Tempo base de injeção (us)")
    print("    Memory_cell[123] = 32'd6500; // RPM limite (rev limiter)")
    print("    Memory_cell[124] = 32'd120;  // Temperatura limite motor (°C)")
    print("    Memory_cell[125] = 32'd60;   // Temperatura para enriquecimento (°C)")

if __name__ == "__main__":
    print("=" * 70)
    print("Gerador de Lookup Table de Ignição - ECU Single-Cycle")
    print("=" * 70)
    print()
    generate_ignition_table()
    generate_injection_constants()
    print()
    print("=" * 70)
    print("Copie o código acima para o bloco 'initial' de data_memory.v")
    print("=" * 70)
