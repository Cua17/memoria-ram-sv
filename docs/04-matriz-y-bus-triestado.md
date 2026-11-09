# 4. Celda direccionable, bus triestado y matriz

Basado en los minutos 10:01–14:10 del video (la parte que el propio
presentador llama "esto es una sobre-simplificación" por lo intrincada
que se pone, justo antes de abstraerla).

## Una sola línea para leer y escribir

El video agrega a cada latch un **read enable** para poder usar una
sola línea de datos tanto para escribir como para leer, en vez de 32
cables (16 de entrada + 16 de salida) para una matriz de 16 celdas:

> "activating the read enable signal configures the data line as an
> output... when read enable is off, the transistor prevents the
> signal from reaching the output, allowing the data line to serve as
> an input."

[`rtl/mem_cell.sv`](../rtl/mem_cell.sv) implementa esto literalmente
con un puerto `inout` y una señal triestado, el mismo mecanismo de bus
triestado que ya se usó en la Parte 1 del examen final para las
operaciones AND/OR de la ALU+:

```systemverilog
module mem_cell (
    inout  wire data,
    input  wire wr_sel,
    input  wire rd_sel
);
    wire q;
    gated_latch core (.d(data), .wr_en(wr_sel), .q(q));
    assign data = rd_sel ? q : 1'bz;
endmodule
```

- `data` conectado directamente a la entrada `d` del `gated_latch`: si
  `wr_sel = 0` el latch simplemente la ignora, así que no hay conflicto
  aunque la línea esté siendo usada para leer en ese momento.
- `assign data = rd_sel ? q : 1'bz`: solo cuando esta celda específica
  está siendo leída, maneja el bus con su valor almacenado; en
  cualquier otro momento queda en alta impedancia para no interferir
  con otras celdas que comparten la misma línea.

`wr_sel` y `rd_sel` no son controles globales: ya vienen filtrados por
dirección (ver más abajo), así que una celda solo reacciona cuando su
dirección fue seleccionada.

## La matriz: decodificar + filtrar con AND

[`rtl/mem_matrix.sv`](../rtl/mem_matrix.sv) arma una matriz de
`ROWS x COLS` celdas de 1 bit. Row/col decoder (documento 3) producen
`row_sel`/`col_sel` one-hot; para cada celda `(r, c)`:

```systemverilog
and g_sel (cell_sel, row_sel[r], col_sel[c]);
and g_wr  (cell_wr,  cell_sel,   wr_en);
and g_rd  (cell_rd,  cell_sel,   rd_en);
```

Solo la celda en la intersección de la fila y columna activas recibe
`cell_wr`/`cell_rd` en 1; el resto se queda en 0 sin importar qué pase
en la línea `data` compartida. Esto reproduce exactamente lo que
describe el video: "the sole AND gate producing an output of one... is
where the active outputs of the decoders intersect" y "since none of
the other latches have their write enable activated, this value
remains disregarded."

## Un detalle de temporización que el video no menciona (y que sí importa)

El AND-OR latch es **asíncrono**: no tiene reloj, reacciona a cualquier
cambio de sus entradas en el instante en que ocurre. Eso significa que
la dirección (`row_addr`/`col_addr`) tiene que estar **estable antes**
de activar `wr_en`/`rd_en`, igual que en cualquier memoria asíncrona
real (SRAM asíncrona clásica): si la dirección cambiara en el mismo
instante que el control, un glitch transitorio del decodificador
durante la transición podría "quedar grabado" en la celda equivocada.
Los testbenches de este proyecto respetan esa disciplina a propósito
(dirección y datos estables, *luego* se activa el control) — el
proceso de depuración que encontró este problema está documentado en
[06-verificacion.md](06-verificacion.md), porque es justamente el tipo
de detalle que separa "la idea en el video" de "un circuito real que
funciona".
