module io_controller (
    input clk, rst,
    input [31:0] address,
    input [31:0] write_data,
    input write_enable,
    output reg [31:0] read_data,
    
    // Sensores (entradas simuladas)
    input [15:0] sensor_rpm,
    input [7:0] sensor_tps,
    input [7:0] sensor_temp_motor,
    input [7:0] sensor_temp_ar,
    input [7:0] sensor_map,
    input sensor_tdc,
    
    // Atuadores (saídas)
    output reg [7:0] ignition_advance,
    output reg [15:0] injection_time,
    output reg ignition_trigger,
    output reg [7:0] safety_flags
);

// Mapeamento de endereços:
// Leitura (Sensores):
// 0x1000: RPM (16 bits)
// 0x1004: TPS - Throttle Position Sensor (8 bits)
// 0x1008: Temperatura do Motor (8 bits)
// 0x100C: Temperatura do Ar (8 bits)
// 0x1010: MAP - Manifold Absolute Pressure (8 bits)
// 0x1014: TDC Sensor (1 bit)
//
// Escrita (Atuadores):
// 0x2000: Avanço de Ignição (8 bits)
// 0x2004: Tempo de Injeção (16 bits)
// 0x2008: Trigger de Ignição (1 bit)
// 0x2010: Safety Flags (8 bits, read/write)

// Inicialização dos atuadores
initial begin
    ignition_advance = 8'd15;  // 15 graus padrão
    injection_time = 16'd1000; // 1000 us padrão
    ignition_trigger = 1'b0;
    safety_flags = 8'b0;
end

// Lógica de leitura (assíncrona)
always @(*) begin
    case (address)
        32'h00001000: read_data = {16'b0, sensor_rpm};
        32'h00001004: read_data = {24'b0, sensor_tps};
        32'h00001008: read_data = {24'b0, sensor_temp_motor};
        32'h0000100C: read_data = {24'b0, sensor_temp_ar};
        32'h00001010: read_data = {24'b0, sensor_map};
        32'h00001014: read_data = {31'b0, sensor_tdc};
        32'h00002010: read_data = {24'b0, safety_flags};
        default: read_data = 32'h0;
    endcase
end

// Escrita síncrona; reset limpa atuadores a cada cenário do testbench
always @(posedge clk or posedge rst) begin
    if (rst) begin
        ignition_advance <= 8'd15;
        injection_time <= 16'd1000;
        ignition_trigger <= 1'b0;
        safety_flags <= 8'b0;
    end else if (write_enable) begin
        if (address >= 32'h00002000 && address <= 32'h00002010) begin
            case (address)
                32'h00002000: ignition_advance <= write_data[7:0];
                32'h00002004: injection_time <= write_data[15:0];
                32'h00002008: ignition_trigger <= write_data[0];
                32'h00002010: safety_flags <= write_data[7:0];
                default: ;
            endcase
        end
    end
end

endmodule
