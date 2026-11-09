// and_or_latch.sv
//
// Celda básica de 1 bit (SR latch construido con puertas AND/OR/NOT),
// tal como se describe en el video. No es un flip-flop ni usa always:
// es la realimentación estructural de compuertas lógicas la que retiene
// el valor, igual que se explica desde los transistores.
//
//   or_out = set OR q
//   q      = or_out AND (NOT reset)
//
// set  = 1 fuerza q -> 1 (y se mantiene aunque set vuelva a 0).
// reset = 1 fuerza q -> 0 (y se mantiene aunque reset vuelva a 0).
// set y reset nunca deben activarse juntos (igual que indica el video).
module and_or_latch (
    input  wire set,
    input  wire reset,
    output wire q
);

    wire or_out;
    wire reset_n;

    not g_inv_reset (reset_n, reset);
    or  g_or        (or_out, set, q);
    and g_and        (q, or_out, reset_n);

endmodule
