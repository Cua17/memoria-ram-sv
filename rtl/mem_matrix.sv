// mem_matrix.sv
//
// Matriz de ROWS x COLS mem_cell para UN bit de la palabra de memoria.
// Un decodificador de filas y uno de columnas activan exactamente un
// par (fila, columna) por dirección -- la intersección es la única
// celda cuyo wr_sel/rd_sel se activa. Todas las celdas comparten la
// misma línea `data` (bus de 1 bit): solo la celda direccionada maneja
// el bus al leer, y solo ella captura el bus al escribir; el resto se
// queda en alta impedancia o simplemente ignora el valor porque su
// wr_sel es 0. Esto reproduce tal cual la "matriz 4x4" del video.
module mem_matrix #(
    parameter int ROW_BITS = 2,
    parameter int COL_BITS = 2
) (
    input  wire [ROW_BITS-1:0] row_addr,
    input  wire [COL_BITS-1:0] col_addr,
    input  wire                wr_en,
    input  wire                rd_en,
    inout  wire                data
);

    localparam int ROWS = 2 ** ROW_BITS;
    localparam int COLS = 2 ** COL_BITS;

    wire [ROWS-1:0] row_sel;
    wire [COLS-1:0] col_sel;

    decoder #(.N(ROW_BITS)) row_dec (.in(row_addr), .out(row_sel));
    decoder #(.N(COL_BITS)) col_dec (.in(col_addr), .out(col_sel));

    genvar r, c;
    generate
        for (r = 0; r < ROWS; r++) begin : row_g
            for (c = 0; c < COLS; c++) begin : col_g
                wire cell_sel;
                wire cell_wr;
                wire cell_rd;

                and g_sel (cell_sel, row_sel[r], col_sel[c]);
                and g_wr  (cell_wr, cell_sel, wr_en);
                and g_rd  (cell_rd, cell_sel, rd_en);

                mem_cell cell_inst (
                    .data   (data),
                    .wr_sel (cell_wr),
                    .rd_sel (cell_rd)
                );
            end
        end
    endgenerate

endmodule
