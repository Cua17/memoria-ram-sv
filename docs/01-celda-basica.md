# 1. Celda básica: el AND-OR latch

Basado en los minutos 1:02–4:09 del video (*How Transistors Remember
Data*, Core Dumped).

## De la realimentación a la memoria

El video arranca con la idea central: para "recordar" algo, un circuito
necesita que su propia salida se realimente a su entrada. Dos ejemplos
mínimos:

- Una compuerta **OR** con su salida realimentada a una de sus
  entradas: una vez que se pone `1`, se queda en `1` para siempre (solo
  puede "recordar" un uno).
- Una compuerta **AND** con su salida realimentada: una vez que se pone
  `0`, se queda en `0` para siempre (solo puede "recordar" un cero).

Ninguna por separado sirve como memoria real porque cada una solo puede
retener un valor. El video las combina.

## La combinación: AND-OR latch

```
or_out = set OR q
q      = or_out AND (NOT reset)
```

- `set = 1` fuerza `q -> 1`. Como `q` se realimenta al OR, `set` puede
  volver a `0` sin que `q` cambie.
- `reset = 1` (a través del inversor) fuerza `q -> 0`, y por el mismo
  motivo puede volver a `0` sin que `q` cambie.
- `set` y `reset` activados al mismo tiempo no tienen un resultado con
  sentido (el propio video lo advierte explícitamente) — no se usan así
  en ningún otro módulo de este proyecto.

Implementado en [`rtl/and_or_latch.sv`](../rtl/and_or_latch.sv) con
compuertas primitivas de Verilog (`and`, `or`, `not`) en vez de un
`always` con reloj, **a propósito**: la retención del bit no depende de
ningún flanco de reloj, depende *solo* de la realimentación estructural
de compuertas, igual que lo explica el video desde los transistores.

```systemverilog
module and_or_latch (
    input  wire set,
    input  wire reset,
    output wire q
);
    wire or_out, reset_n;
    not g_inv_reset (reset_n, reset);
    or  g_or        (or_out, set, q);
    and g_and        (q, or_out, reset_n);
endmodule
```

Verificado en [`sim/testbench_register.sv`](../sim/testbench_register.sv)
de forma indirecta (es la base del `register`) y de forma aislada en el
proceso de depuración documentado en
[06-verificacion.md](06-verificacion.md).
