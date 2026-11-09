// decoder.sv
//
// Decodificador N-a-2^N, "one-hot": dado un valor binario de N bits,
// activa exactamente una de las 2^N salidas (la que coincide con ese
// valor). El video asume este bloque como ya conocido de un video
// anterior y lo usa dos veces en la matriz (uno para filas, otro para
// columnas). out[i] se obtiene como el AND de cada bit de entrada
// comparado contra el bit correspondiente del literal i (NOT cuando
// ese bit del literal es 0), que es la reducción lógica de un
// decodificador construido con compuertas AND/NOT.
module decoder #(
    parameter int N = 2
) (
    input  wire [N-1:0]      in,
    output wire [(2**N)-1:0] out
);

    genvar i, j;
    generate
        for (i = 0; i < (2**N); i++) begin : out_lane
            wire [N-1:0] match;
            for (j = 0; j < N; j++) begin : bit_match
                if (((i >> j) & 1) == 1) begin : bit_is_one
                    assign match[j] = in[j];
                end else begin : bit_is_zero
                    wire nbit;
                    not g_n (nbit, in[j]);
                    assign match[j] = nbit;
                end
            end
            assign out[i] = &match;
        end
    endgenerate

endmodule
