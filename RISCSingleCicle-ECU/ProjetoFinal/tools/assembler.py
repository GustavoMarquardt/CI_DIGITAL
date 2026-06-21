#!/usr/bin/env python3
"""
Assembler RISC-V Simplificado para ECU Single-Cycle
Converte assembly RISC-V em código de máquina hexadecimal
Suporta: ADD, SUB, MUL, DIV, AND, OR, SLT, ADDI, LW, SW, BEQ, BNE, JAL
"""

import re
import sys

class RISCVAssembler:
    def __init__(self):
        self.labels = {}
        self.instructions = []
        self.address = 0
        
    def parse_register(self, reg):
        """Converte nome de registrador para número"""
        if reg.startswith('x'):
            return int(reg[1:])
        # Aliases comuns
        aliases = {
            'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
            't0': 5, 't1': 6, 't2': 7,
            's0': 8, 'fp': 8, 's1': 9,
            'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13,
            'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17,
            's2': 18, 's3': 19, 's4': 20, 's5': 21,
            's6': 22, 's7': 23, 's8': 24, 's9': 25,
            's10': 26, 's11': 27,
            't3': 28, 't4': 29, 't5': 30, 't6': 31
        }
        return aliases.get(reg, 0)
    
    def encode_r_type(self, opcode, rd, rs1, rs2, funct3, funct7):
        """Codifica instrução tipo R"""
        return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    
    def encode_i_type(self, opcode, rd, rs1, imm, funct3):
        """Codifica instrução tipo I"""
        imm = imm & 0xFFF  # 12 bits
        return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode
    
    def encode_s_type(self, opcode, rs1, rs2, imm, funct3):
        """Codifica instrução tipo S"""
        imm = imm & 0xFFF
        imm_11_5 = (imm >> 5) & 0x7F
        imm_4_0 = imm & 0x1F
        return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode
    
    def encode_b_type(self, opcode, rs1, rs2, imm, funct3):
        """Codifica instrução tipo B (branch)"""
        imm = imm & 0x1FFF
        imm_12 = (imm >> 12) & 0x1
        imm_10_5 = (imm >> 5) & 0x3F
        imm_4_1 = (imm >> 1) & 0xF
        imm_11 = (imm >> 11) & 0x1
        return (imm_12 << 31) | (imm_10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_1 << 8) | (imm_11 << 7) | opcode
    
    def encode_j_type(self, opcode, rd, imm):
        """Codifica instrução tipo J (JAL)"""
        imm = imm & 0x1FFFFF
        imm_20 = (imm >> 20) & 0x1
        imm_10_1 = (imm >> 1) & 0x3FF
        imm_11 = (imm >> 11) & 0x1
        imm_19_12 = (imm >> 12) & 0xFF
        return (imm_20 << 31) | (imm_19_12 << 12) | (imm_11 << 20) | (imm_10_1 << 21) | (rd << 7) | opcode
    
    def assemble_instruction(self, line, address):
        """Monta uma linha de assembly"""
        # Remover comentários e espaços extras
        line = re.sub(r'#.*', '', line).strip()
        if not line:
            return None
        
        parts = re.split(r'[,\s()]+', line)
        parts = [p for p in parts if p]
        
        if not parts:
            return None
        
        opcode = parts[0].lower()
        
        try:
            # Tipo R: ADD, SUB, MUL, DIV, AND, OR, SLT
            if opcode == 'add':
                rd, rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2]), self.parse_register(parts[3])
                return self.encode_r_type(0b0110011, rd, rs1, rs2, 0b000, 0b0000000)
            
            elif opcode == 'sub':
                rd, rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2]), self.parse_register(parts[3])
                return self.encode_r_type(0b0110011, rd, rs1, rs2, 0b000, 0b0100000)
            
            elif opcode == 'mul':
                rd, rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2]), self.parse_register(parts[3])
                return self.encode_r_type(0b0110011, rd, rs1, rs2, 0b001, 0b0000001)
            
            elif opcode == 'div':
                rd, rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2]), self.parse_register(parts[3])
                return self.encode_r_type(0b0110011, rd, rs1, rs2, 0b100, 0b0000001)
            
            elif opcode == 'divu':
                rd, rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2]), self.parse_register(parts[3])
                return self.encode_r_type(0b0110011, rd, rs1, rs2, 0b101, 0b0000001)
            
            elif opcode == 'and':
                rd, rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2]), self.parse_register(parts[3])
                return self.encode_r_type(0b0110011, rd, rs1, rs2, 0b111, 0b0000000)
            
            elif opcode == 'or':
                rd, rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2]), self.parse_register(parts[3])
                return self.encode_r_type(0b0110011, rd, rs1, rs2, 0b110, 0b0000000)
            
            elif opcode == 'slt':
                rd, rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2]), self.parse_register(parts[3])
                return self.encode_r_type(0b0110011, rd, rs1, rs2, 0b010, 0b0000000)
            
            # Tipo I: ADDI, ANDI, ORI
            elif opcode == 'addi':
                rd, rs1 = self.parse_register(parts[1]), self.parse_register(parts[2])
                imm = int(parts[3], 0) if parts[3] not in self.labels else self.labels[parts[3]]
                return self.encode_i_type(0b0010011, rd, rs1, imm, 0b000)
            
            elif opcode == 'slli':
                rd, rs1 = self.parse_register(parts[1]), self.parse_register(parts[2])
                shamt = int(parts[3], 0) & 0x1F
                return self.encode_i_type(0b0010011, rd, rs1, shamt, 0b001)
            
            elif opcode == 'andi':
                rd, rs1 = self.parse_register(parts[1]), self.parse_register(parts[2])
                imm = int(parts[3], 0)
                return self.encode_i_type(0b0010011, rd, rs1, imm, 0b111)
            
            # Load/Store
            elif opcode == 'lw':
                rd = self.parse_register(parts[1])
                # Formato: lw rd, imm(rs1)
                if len(parts) == 3:
                    imm = 0
                    rs1 = self.parse_register(parts[2])
                else:
                    imm = int(parts[2], 0)
                    rs1 = self.parse_register(parts[3])
                return self.encode_i_type(0b0000011, rd, rs1, imm, 0b010)
            
            elif opcode == 'sw':
                rs2 = self.parse_register(parts[1])
                if len(parts) == 3:
                    imm = 0
                    rs1 = self.parse_register(parts[2])
                else:
                    imm = int(parts[2], 0)
                    rs1 = self.parse_register(parts[3])
                return self.encode_s_type(0b0100011, rs1, rs2, imm, 0b010)
            
            # Branch
            elif opcode == 'beq':
                rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2])
                if parts[3] in self.labels:
                    imm = self.labels[parts[3]] - address
                else:
                    imm = int(parts[3], 0)
                return self.encode_b_type(0b1100011, rs1, rs2, imm, 0b000)
            
            elif opcode == 'bne':
                rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2])
                if parts[3] in self.labels:
                    imm = self.labels[parts[3]] - address
                else:
                    imm = int(parts[3], 0)
                return self.encode_b_type(0b1100011, rs1, rs2, imm, 0b001)
            
            elif opcode == 'blt':
                rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2])
                if parts[3] in self.labels:
                    imm = self.labels[parts[3]] - address
                else:
                    imm = int(parts[3], 0)
                return self.encode_b_type(0b1100011, rs1, rs2, imm, 0b100)
            
            elif opcode == 'bge':
                rs1, rs2 = self.parse_register(parts[1]), self.parse_register(parts[2])
                if parts[3] in self.labels:
                    imm = self.labels[parts[3]] - address
                else:
                    imm = int(parts[3], 0)
                return self.encode_b_type(0b1100011, rs1, rs2, imm, 0b101)
            
            # JAL
            elif opcode == 'jal':
                rd = self.parse_register(parts[1])
                if parts[2] in self.labels:
                    imm = self.labels[parts[2]] - address
                else:
                    imm = int(parts[2], 0)
                return self.encode_j_type(0b1101111, rd, imm)
            
            else:
                print(f"Warning: Unknown instruction '{opcode}' at address {address}")
                return None
                
        except Exception as e:
            print(f"Error assembling '{line}': {e}")
            return None
    
    def first_pass(self, lines):
        """Primeira passagem: identificar labels"""
        address = 0
        for line in lines:
            line = re.sub(r'#.*', '', line).strip()
            
            # Verificar se é label
            if ':' in line:
                label = line.split(':')[0].strip()
                self.labels[label] = address
                line = line.split(':', 1)[1].strip() if ':' in line else ''
            
            # Contar se é uma instrução válida
            if line and not line.startswith('.'):
                address += 4
    
    def second_pass(self, lines):
        """Segunda passagem: montar instruções"""
        address = 0
        machine_code = []
        
        for line in lines:
            line = re.sub(r'#.*', '', line).strip()
            
            # Remover label se existir
            if ':' in line:
                line = line.split(':', 1)[1].strip()
            
            # Pular diretivas e linhas vazias
            if not line or line.startswith('.'):
                continue
            
            code = self.assemble_instruction(line, address)
            if code is not None:
                machine_code.append((address, code, line))
                address += 4
        
        return machine_code
    
    def assemble_file(self, filename):
        """Monta um arquivo assembly"""
        with open(filename, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Duas passagens
        self.first_pass(lines)
        machine_code = self.second_pass(lines)
        
        return machine_code
    
    def generate_verilog(self, machine_code, output_file=None):
        """Gera código Verilog para instruction_memory"""
        output = []
        output.append("// Código gerado automaticamente pelo assembler")
        output.append("// RISC-V Machine Code")
        output.append("")
        
        for i, (addr, code, orig) in enumerate(machine_code):
            output.append(f"    instruction[{i}] = 32'b{code:032b}; // {orig}")
        
        result = '\n'.join(output)
        
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(result)
        
        return result

def main():
    if len(sys.argv) < 2:
        print("Uso: python assembler.py <arquivo.asm> [saida.v]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    assembler = RISCVAssembler()
    
    print(f"Montando {input_file}...")
    machine_code = assembler.assemble_file(input_file)
    
    print(f"\nLabels encontradas:")
    for label, addr in assembler.labels.items():
        print(f"  {label}: {addr}")
    
    print(f"\nCódigo de máquina ({len(machine_code)} instruções):")
    for addr, code, orig in machine_code:
        print(f"  [{addr:3d}] 0x{code:08X}  {orig}")
    
    print("\n" + "="*70)
    verilog_code = assembler.generate_verilog(machine_code, output_file)
    print(verilog_code)
    print("="*70)
    
    if output_file:
        print(f"\nCódigo Verilog salvo em: {output_file}")

if __name__ == "__main__":
    main()
