# 3. Decodificador de direcciones

Basado en los minutos 8:20–9:58 del video.

El video propone organizar los latches en una **matriz** (ejemplo
concreto: 4x4 = 16 latches) en vez de un arreglo lineal, para no
necesitar un cable de datos por cada bit. Cada celda de la matriz se
identifica con una dirección: un decodificador de filas y uno de
columnas, cada uno activa exactamente una línea según el valor binario
de entrada ("inputting 00 activa la salida 0, inputting 01 activa la
salida 1, y así sucesivamente"). El video asume el decodificador como
un bloque ya conocido (lo construyó en un video anterior) y lo usa como
caja negra.

[`rtl/decoder.sv`](../rtl/decoder.sv) implementa un decodificador
N-a-2^N "one-hot" parametrizado en `N`:

```systemverilog
module decoder #(parameter int N = 2) (
    input  wire [N-1:0]      in,
    output wire [(2**N)-1:0] out
);
```

Para cada salida `out[i]`, se compara cada bit de `in` contra el bit
correspondiente del literal `i` (comparación directa si ese bit del
literal es 1, comparación negada —con una compuerta `not`— si es 0), y
se activa solo cuando **todos** los bits coinciden. Esa comparación
bit a bit con inversores es, en esencia, el árbol de compuertas AND/NOT
de un decodificador clásico; el operador de reducción `&match` sobre
esas comparaciones es equivalente a una única compuerta AND de N
entradas.

Verificado de forma aislada antes de integrarlo a la matriz (ver
[06-verificacion.md](06-verificacion.md)): para `N=2`, con las cuatro
combinaciones de entrada (`00`, `01`, `10`, `11`) se confirmó que
activa exactamente una salida por cada una (`0001`, `0010`, `0100`,
`1000`), sin solapamientos.

En `mem_matrix.sv` (documento 4) se instancian **dos** decodificadores
independientes: uno para la dirección de fila y otro para la de
columna, igual que en el video.
