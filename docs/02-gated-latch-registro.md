# 2. Gated latch y registro

Basado en los minutos 4:48–8:11 del video.

## El problema de usar set/reset directo

Con dos entradas (`set`/`reset`) no alcanza para una memoria práctica:
el dato que se quiere guardar normalmente ya viene como un solo bit
(`0` o `1`), no como "activar la línea de poner" o "activar la línea de
borrar". El video agrega una línea de **write enable** (`WR_EN`): si
está en `0`, la entrada de datos se ignora por completo; si está en
`1`, el latch copia lo que haya en la línea de datos.

## Gated latch

```
set   = d AND wr_en
reset = (NOT d) AND wr_en
```

Con `wr_en = 0`, `set = reset = 0` → el AND-OR latch no cambia, retiene
su valor. Con `wr_en = 1`, el latch copia `d` y lo conserva aunque `d` o
`wr_en` vuelvan a `0` después. Implementado en
[`rtl/gated_latch.sv`](../rtl/gated_latch.sv), instanciando el
`and_or_latch` del documento anterior:

```systemverilog
module gated_latch (
    input  wire d,
    input  wire wr_en,
    output wire q
);
    wire d_n, set_sig, reset_sig;
    not g_dn    (d_n, d);
    and g_set   (set_sig, d, wr_en);
    and g_reset (reset_sig, d_n, wr_en);
    and_or_latch core (.set(set_sig), .reset(reset_sig), .q(q));
endmodule
```

## Registro

El video junta varios gated latches con el **mismo** `wr_en`
compartido para formar un registro de N bits ("una colección de
latches interconectados de esta manera se conoce como registro").
[`rtl/register.sv`](../rtl/register.sv) lo implementa parametrizado en
`WIDTH` con un `generate`:

```systemverilog
module register #(parameter int WIDTH = 8) (
    input  wire [WIDTH-1:0] d,
    input  wire              wr_en,
    output wire [WIDTH-1:0] q
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i++) begin : bit_lane
            gated_latch latch_i (.d(d[i]), .wr_en(wr_en), .q(q[i]));
        end
    endgenerate
endmodule
```

No se usa directamente dentro de `mem_top` (la memoria matricial lo
reemplaza para poder escalar — ver documento 4), pero se deja como
módulo propio y con su propio testbench
([`sim/testbench_register.sv`](../sim/testbench_register.sv), 5/5
checks) porque es exactamente el paso intermedio que describe el video
antes de llegar a la matriz, y la consigna pide implementar "la
estructura de memoria... según lo descrito en el video" completa, no
solo el resultado final.

El video también señala el problema que motiva el siguiente paso: un
registro de 1 GB necesitaría millones de cables de entrada/salida. Por
eso se pasa a una matriz direccionable en vez de seguir alargando el
registro.
