// gated_latch.sv
//
// "Gated latch": envuelve el and_or_latch para que se controle con una
// sola línea de datos (d) más una señal de habilitación de escritura
// (wr_en), en vez de dos entradas set/reset separadas.
//
//   set   = d AND wr_en
//   reset = (NOT d) AND wr_en
//
// Si wr_en = 0, set = reset = 0 -> el latch no cambia (mantiene su valor).
// Si wr_en = 1, el latch copia el valor de d y lo retiene aunque d o
// wr_en vuelvan a 0 después.
module gated_latch (
    input  wire d,
    input  wire wr_en,
    output wire q
);

    wire d_n;
    wire set_sig;
    wire reset_sig;

    not g_dn    (d_n, d);
    and g_set   (set_sig, d, wr_en);
    and g_reset (reset_sig, d_n, wr_en);

    and_or_latch core (
        .set   (set_sig),
        .reset (reset_sig),
        .q     (q)
    );

endmodule
