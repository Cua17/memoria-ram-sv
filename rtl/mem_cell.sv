// mem_cell.sv
//
// Celda de memoria direccionable de 1 bit. Usa una sola línea (data,
// inout) tanto para escribir como para leer, exactamente como describe
// el video: cuando rd_sel está activo, la línea se comporta como
// salida (maneja el bus con el valor almacenado); cuando rd_sel está
// inactivo, la línea se comporta como entrada (el valor del bus pasa
// al gated_latch, que solo lo captura si wr_sel está activo).
// wr_sel y rd_sel ya vienen filtrados por la dirección (ver
// mem_matrix.sv), así que esta celda solo reacciona cuando su
// dirección fue seleccionada.
module mem_cell (
    inout  wire data,
    input  wire wr_sel,
    input  wire rd_sel
);

    wire q;

    gated_latch core (
        .d     (data),
        .wr_en (wr_sel),
        .q     (q)
    );

    assign data = rd_sel ? q : 1'bz;

endmodule
