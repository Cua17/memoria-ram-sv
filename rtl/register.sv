// register.sv
//
// Registro de WIDTH bits: WIDTH gated_latch con el mismo wr_en
// compartido, tal como lo describe el video ("una colección de latches
// interconectados de esta manera se conoce como registro"). No se usa
// directamente dentro de mem_top (la memoria matricial lo reemplaza
// para escalar), pero se deja como módulo independiente y verificado
// porque es el paso intermedio explícito que pide la guía del video.
module register #(
    parameter int WIDTH = 8
) (
    input  wire [WIDTH-1:0] d,
    input  wire              wr_en,
    output wire [WIDTH-1:0] q
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin : bit_lane
            gated_latch latch_i (
                .d     (d[i]),
                .wr_en (wr_en),
                .q     (q[i])
            );
        end
    endgenerate

endmodule
