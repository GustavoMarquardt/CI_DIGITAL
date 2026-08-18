// ============================================================================
// tcu_incline_estimator.v
// Estimador de inclinacao da pista por dinamica longitudinal.
//
// Modulo ISOLADO de proposito: a TCU consome apenas a saida `incline_est`.
// Para trocar por um sensor dedicado no futuro, basta substituir este modulo
// por um que leia o endereco de I/O do sensor e produza `incline_est`.
//
// Principio:
//   - aceleracao_real   = d(velocidade)/dt, medida numa janela de amostragem
//   - aceleracao_esperada ~ torque disponivel (proxy = MAP atenuado)
//   - inclinacao ~ (esperada - real):
//        > 0  => aclive  (acelera menos do que o torque permitiria)
//        < 0  => declive (acelera mais do que o esperado / ganha velocidade)
//
// Saida saturada em [-64, +63] (8 bits signed) para uso direto nos limiares.
// ============================================================================
module tcu_incline_estimator #(
    parameter [15:0] SAMPLE_CYCLES = 16'd256  // janela de amostragem (ciclos de clock)
)(
    input                   clk,
    input                   rst,
    input  [15:0]           vehicle_speed, // velocidade atual do veiculo
    input  [7:0]            sensor_map,    // carga ~ torque disponivel
    input  [15:0]           sensor_rpm,    // reservado p/ refinamento futuro do torque
    output reg signed [7:0] incline_est    // + aclive / - declive
);

    reg [15:0] sample_cnt;
    reg [15:0] speed_prev;

    // Temporarios de calculo (uso combinacional dentro do bloco sincrono)
    reg signed [15:0] accel_real;
    reg signed [15:0] accel_esp;
    reg signed [15:0] diff;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_cnt  <= 16'd0;
            speed_prev  <= 16'd0;
            incline_est <= 8'sd0;
        end else begin
            if (sample_cnt >= SAMPLE_CYCLES) begin
                sample_cnt <= 16'd0;

                // aceleracao real na janela (pode ser negativa)
                accel_real = $signed({1'b0, vehicle_speed}) - $signed({1'b0, speed_prev});
                // aceleracao esperada ~ torque (proxy: MAP/8)
                accel_esp  = $signed({8'b0, sensor_map}) >>> 3;
                // inclinacao ~ esperado - real
                diff       = accel_esp - accel_real;

                // saturacao em [-64, +63]
                if (diff > 16'sd63)
                    incline_est <= 8'sd63;
                else if (diff < -16'sd64)
                    incline_est <= -8'sd64;
                else
                    incline_est <= diff[7:0];

                speed_prev <= vehicle_speed;
            end else begin
                sample_cnt <= sample_cnt + 16'd1;
            end
        end
    end

endmodule
