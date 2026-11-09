# 5. mem_top: de bits a bytes, y la abstracción de RAM

Basado en los minutos 14:12–16:34 del video.

## De 1 bit a una palabra completa

El video generaliza la matriz de 1 bit a bytes completos: "to store
bytes instead of bits we can use eight matrices... all these matrices
will share the same address input... the read enable and write enable
inputs should also be shared... each matrix will have its own data
line." Es exactamente la estructura de
[`rtl/mem_top.sv`](../rtl/mem_top.sv): `DATA_WIDTH` instancias de
`mem_matrix` (una por cada bit de la palabra), todas compartiendo
dirección, `wr_en` y `rd_en`, cada una con su propio bit de la línea de
datos.

```systemverilog
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
    // ... genera DATA_WIDTH instancias de mem_matrix, una por bit ...
endmodule
```

La dirección se parte en dos mitades (fila/columna), igual que en el
video.

## Por qué los valores por defecto son `ADDR_WIDTH=4`, `DATA_WIDTH=8`

Con `ADDR_WIDTH=4` la matriz queda en `ROW_BITS=2`, `COL_BITS=2`, es
decir **4x4 = 16 palabras direccionables** — el mismo ejemplo numérico
que usa el video en esta sección ("we'll organize them into a 4x4
matrix, totaling 16 latches"). `DATA_WIDTH=8` es un byte, la unidad
mínima que el video usa para el ejemplo de lectura/escritura. Es
decir: la instancia por defecto de `mem_top` **es** literalmente el
ejemplo del video, no una analogía.

## Parametrización real (no solo "queda un parámetro sin usar")

`mem_top` se puede instanciar con cualquier `ADDR_WIDTH` par y
`DATA_WIDTH` arbitrario sin tocar ningún módulo — la matriz, los
decodificadores y la cantidad de planos de bits se generan solos. Esto
se demuestra (no se afirma sin probar) en
[`sim/testbench_params.sv`](../sim/testbench_params.sv): la misma
arquitectura, instanciada con `ADDR_WIDTH=6, DATA_WIDTH=16` (matriz
8x8 = 64 palabras de 16 bits), pasa sus 5 verificaciones igual que la
instancia por defecto. Ver [06-verificacion.md](06-verificacion.md)
para el detalle.

## La abstracción final: RAM como lista de bytes

El cierre conceptual del video es importante y se refleja en cómo se
pensó la interfaz de `mem_top`: quien usa la memoria no necesita saber
que por dentro hay una matriz con decodificadores — ve una dirección,
un bit de escritura, un bit de lectura y un bus de datos, como una
simple lista de palabras indexada por dirección ("this is called
Random Access Memory, since we can point to any random byte in the
list by providing its address"). El video también explica por qué el
ancho del bus de direcciones determina la capacidad (`2^n` palabras
direccionables con `n` bits de dirección) — con `ADDR_WIDTH=4` son
`2^4 = 16` palabras, consistente con la matriz 4x4 de arriba.

El video cierra mencionando que esto es **SRAM** (rápida, pero cada
celda necesita varios transistores) y que existe una alternativa más
barata y lenta (**DRAM**, un transistor + un capacitor), que queda
fuera del alcance de esta entrega porque el video explícitamente la
deja para un video aparte.
