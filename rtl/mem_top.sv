// mem_top.sv
//
// Módulo top de la memoria RAM parametrizada. Es la abstracción final
// que describe el video: desde afuera se ve como una "lista de bytes"
// direccionable (Random Access Memory) -- adentro sigue siendo la
// matriz de latches con decodificadores de fila/columna, repetida una
// vez por cada bit de la palabra (DATA_WIDTH planos de bits, todos
// compartiendo la misma dirección y las mismas señales de control).
//
// ADDR_WIDTH bits de dirección -> 2^ADDR_WIDTH palabras direccionables.
// DATA_WIDTH bits de ancho de palabra (por defecto 8 = un byte).
//
// La dirección se parte en dos mitades (fila/columna) igual que en el
// video; con los valores por defecto (ADDR_WIDTH=4) queda una matriz
// de 4x4 = 16 palabras, el mismo ejemplo numérico que usa el video.
//
// wr_en=1 escribe el valor de `data` en la palabra apuntada por addr.
// rd_en=1 hace que `data` sea manejado por la memoria con el valor
// almacenado en esa palabra (alta impedancia en cualquier otro caso).
// wr_en y rd_en no deben activarse juntos.
module mem_top #(
    parameter int ADDR_WIDTH = 4,
    parameter int DATA_WIDTH = 8
) (
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire                  wr_en,
    input  wire                  rd_en,
    inout  wire [DATA_WIDTH-1:0] data
);

    localparam int ROW_BITS = ADDR_WIDTH / 2;
    localparam int COL_BITS = ADDR_WIDTH - ROW_BITS;

    wire [ROW_BITS-1:0] row_addr;
    wire [COL_BITS-1:0] col_addr;

    assign row_addr = addr[ADDR_WIDTH-1:COL_BITS];
    assign col_addr = addr[COL_BITS-1:0];

    genvar b;
    generate
        for (b = 0; b < DATA_WIDTH; b++) begin : bit_plane
            mem_matrix #(
                .ROW_BITS (ROW_BITS),
                .COL_BITS (COL_BITS)
            ) plane (
                .row_addr (row_addr),
                .col_addr (col_addr),
                .wr_en    (wr_en),
                .rd_en    (rd_en),
                .data     (data[b])
            );
        end
    endgenerate

endmodule
