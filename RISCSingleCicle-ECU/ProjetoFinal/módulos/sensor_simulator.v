module sensor_simulator (
    input clk, rst,
    input [2:0] test_scenario, // Seleciona cenário de teste
    
    output reg [15:0] sensor_rpm,
    output reg [7:0] sensor_tps,
    output reg [7:0] sensor_temp_motor,
    output reg [7:0] sensor_temp_ar,
    output reg [7:0] sensor_map,
    output reg sensor_tdc
);

// Parâmetros dos cenários de teste
parameter IDLE = 3'd0;           // Motor em marcha lenta
parameter COLD_START = 3'd1;     // Arranque a frio
parameter ACCELERATION = 3'd2;   // Aceleração gradual
parameter CRUISE = 3'd3;         // Regime de cruzeiro
parameter OVERREV = 3'd4;        // Proteção de RPM alto
parameter OVERHEAT = 3'd5;       // Proteção de superaquecimento

reg [31:0] cycle_counter;
reg [15:0] tdc_counter;
reg [15:0] tdc_period;

// Geração do sinal TDC baseado no RPM
// TDC deve pulsar a cada rotação completa
// Para 6000 RPM = 100 rotações/segundo = período de 10ms
// Com clock de 10ns (100MHz), 10ms = 1.000.000 ciclos
always @(*) begin
    if (sensor_rpm > 0)
        tdc_period = 6000000 / sensor_rpm; // Período em ciclos de clock
    else
        tdc_period = 16'hFFFF;
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        tdc_counter <= 0;
        sensor_tdc <= 0;
    end
    else begin
        if (tdc_counter >= tdc_period) begin
            tdc_counter <= 0;
            sensor_tdc <= 1;
        end
        else begin
            tdc_counter <= tdc_counter + 1;
            sensor_tdc <= 0;
        end
    end
end

// Contador de ciclos para simulação dinâmica
always @(posedge clk or posedge rst) begin
    if (rst)
        cycle_counter <= 0;
    else
        cycle_counter <= cycle_counter + 1;
end

// Geração dos valores dos sensores baseado no cenário
always @(posedge clk or posedge rst) begin
    if (rst) begin
        sensor_rpm <= 16'd0;
        sensor_tps <= 8'd0;
        sensor_temp_motor <= 8'd20;
        sensor_temp_ar <= 8'd20;
        sensor_map <= 8'd30;
    end
    else begin
        case (test_scenario)
            IDLE: begin
                // Marcha lenta estável
                sensor_rpm <= 16'd800;
                sensor_tps <= 8'd0;
                sensor_temp_motor <= 8'd90;
                sensor_temp_ar <= 8'd25;
                sensor_map <= 8'd30;
            end
            
            COLD_START: begin
                // Arranque a frio - temperatura sobe gradualmente
                if (cycle_counter < 100)
                    sensor_rpm <= 16'd0;
                else if (cycle_counter < 200)
                    sensor_rpm <= 16'd300;
                else
                    sensor_rpm <= 16'd800;
                
                sensor_tps <= 8'd5;
                
                // Temperatura sobe de 20°C para 60°C
                if (cycle_counter < 500)
                    sensor_temp_motor <= 8'd20 + (cycle_counter / 10);
                else
                    sensor_temp_motor <= 8'd60;
                
                sensor_temp_ar <= 8'd20;
                sensor_map <= 8'd35;
            end
            
            ACCELERATION: begin
                // Aceleração gradual de 1000 a 6000 RPM
                if (cycle_counter < 1000) begin
                    sensor_rpm <= 16'd1000 + (cycle_counter * 5);
                    sensor_tps <= 8'd0 + (cycle_counter / 10);
                end
                else begin
                    sensor_rpm <= 16'd6000;
                    sensor_tps <= 8'd100;
                end
                
                sensor_temp_motor <= 8'd85;
                sensor_temp_ar <= 8'd30;
                sensor_map <= 8'd50 + (sensor_tps / 2);
            end
            
            CRUISE: begin
                // Cruzeiro estável
                sensor_rpm <= 16'd3000;
                sensor_tps <= 8'd40;
                sensor_temp_motor <= 8'd90;
                sensor_temp_ar <= 8'd25;
                sensor_map <= 8'd50;
            end
            
            OVERREV: begin
                // Teste de limitador de RPM (manter >6500: testbench amostra após milhares de ciclos)
                if (cycle_counter < 200)
                    sensor_rpm <= 16'd5000;
                else if (cycle_counter < 400)
                    sensor_rpm <= 16'd6500; // Acima do limite
                else
                    sensor_rpm <= 16'd7000; // Mantém condição de over-rev até trocar de cenário
                
                sensor_tps <= 8'd100;
                sensor_temp_motor <= 8'd95;
                sensor_temp_ar <= 8'd30;
                sensor_map <= 8'd90;
            end
            
            OVERHEAT: begin
                // Teste de proteção de temperatura
                sensor_rpm <= 16'd4000;
                sensor_tps <= 8'd60;
                
                // Temperatura sobe progressivamente
                if (cycle_counter < 100)
                    sensor_temp_motor <= 8'd80;
                else if (cycle_counter < 200)
                    sensor_temp_motor <= 8'd100;
                else if (cycle_counter < 300)
                    sensor_temp_motor <= 8'd115;
                else if (cycle_counter < 400)
                    sensor_temp_motor <= 8'd125; // Acima do limite crítico
                else
                    sensor_temp_motor <= 8'd130; // Muito crítico
                
                sensor_temp_ar <= 8'd35;
                sensor_map <= 8'd70;
            end
            
            default: begin
                // Idle como padrão
                sensor_rpm <= 16'd800;
                sensor_tps <= 8'd0;
                sensor_temp_motor <= 8'd90;
                sensor_temp_ar <= 8'd25;
                sensor_map <= 8'd30;
            end
        endcase
    end
end

endmodule
