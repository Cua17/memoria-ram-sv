# 6. Verificación

Herramienta: **Vivado Simulator 2026.1** (`xvlog`/`xelab`/`xsim`, línea
de comandos, sin GUI), igual que en la Parte 1 del examen final.

## Resultados finales

| Testbench | Qué cubre | Resultado |
|---|---|---|
| [`sim/testbench.sv`](../sim/testbench.sv) | `mem_top` por defecto (`ADDR_WIDTH=4`, `DATA_WIDTH=8` → matriz 4x4, 16 bytes) | **22/22 PASS** |
| [`sim/testbench_register.sv`](../sim/testbench_register.sv) | `register` de 8 bits (módulo intermedio del video) | **5/5 PASS** |
| [`sim/testbench_params.sv`](../sim/testbench_params.sv) | `mem_top` con `ADDR_WIDTH=6`, `DATA_WIDTH=16` (matriz 8x8, 64 palabras de 16 bits) — demuestra parametrización real | **5/5 PASS** |

Reproducir (desde la carpeta `MemoriaRAM/`):

```bash
xvlog --sv rtl/and_or_latch.sv rtl/gated_latch.sv rtl/register.sv rtl/decoder.sv rtl/mem_cell.sv rtl/mem_matrix.sv rtl/mem_top.sv sim/testbench.sv sim/testbench_register.sv sim/testbench_params.sv
xelab testbench -s testbench_sim && xsim testbench_sim -runall
xelab testbench_register -s testbench_register_sim && xsim testbench_register_sim -runall
xelab testbench_params -s testbench_params_sim && xsim testbench_params_sim -runall
```

Cada corrida debe terminar en `TESTBENCH...: PASS (N/N checks)`.

## `testbench.sv` — qué verifica cada chequeo

1. **Bus ocioso en alta impedancia** antes de cualquier operación (ni
   lectura ni escritura activas).
2. Escritura y lectura simple en una dirección.
3. Escritura en una **segunda** dirección de distinta fila *y* columna
   dentro de la misma matriz 4x4.
4. Que la primera dirección **no se haya corrompido** al escribir la
   segunda (prueba directa de que la matriz aísla correctamente cada
   celda).
5. Sobreescritura de un valor ya guardado.
6. Barrido completo de las 16 direcciones con 16 patrones distintos,
   escritas todas y luego leídas todas — ejercita cada celda de la
   matriz 4x4 al menos una vez.
7. Bus vuelve a alta impedancia al terminar.

## Un bug real encontrado durante la verificación (y cómo se encontró)

La primera versión de los testbenches cambiaba la dirección y
activaba `wr_en`/`rd_en` **en el mismo instante de simulación**. El
resultado: escribir una dirección corrompía otra dirección ya
guardada — por ejemplo, escribir `0x3C` en la dirección 5 hacía que la
dirección 0 (que debía seguir en `0xA5`) **también** terminara en
`0x3C`.

Proceso de depuración (ningún resultado se "arregló a ojo" sin
entender la causa):

1. Se armó un testbench aislado solo para `decoder.sv` (las 4
   combinaciones de entrada para `N=2`) — resultado correcto y
   exclusivo (`00→0001`, `01→0010`, `10→0100`, `11→1000`). El
   decodificador no era el problema.
2. Se armó un testbench con **dos** `mem_cell` manuales, controlando
   `wr_sel`/`rd_sel` directamente (sin decodificador) — aislamiento
   correcto. El `gated_latch`/`and_or_latch` tampoco era el problema.
3. Se armó un testbench para `mem_matrix` sola (2x2) — ahí **sí**
   apareció la corrupción cruzada entre celdas.
4. Se agregó una sonda sobre las señales internas `cell_wr` de cada
   celda durante la escritura — y resultó que, leídas en el instante
   en que el testbench ya había esperado, `cell_wr` era correcto y
   exclusivo en cada caso. Es decir: el problema no era un valor final
   incorrecto, sino un **glitch transitorio** durante la transición de
   dirección — el `and_or_latch`, al ser asíncrono (sin reloj),
   reacciona a cualquier pulso transitorio de sus entradas, incluso
   uno que dure apenas un ciclo delta de simulación.

**Causa raíz:** la dirección y el control (`wr_en`) cambiaban a la vez;
durante la transición del decodificador, una celda distinta a la
direccionada podía ver un pulso momentáneo de selección antes de que
el decodificador se asentara, y ese pulso quedaba "grabado" porque el
latch no tiene reloj que lo proteja.

**Corrección:** en los tres testbenches, cada tarea de escritura/lectura
ahora fija la dirección primero con `wr_en=rd_en=0`, espera a que se
asiente, y *después* activa el control — la misma disciplina de
temporización que exige cualquier memoria asíncrona real (dirección
estable antes de activar el control de lectura/escritura). Con ese
cambio, los 32 checks de los tres testbenches pasan limpio.

Esto también es, en sí mismo, parte de lo que vale la pena explicar en
el video de la entrega: el video de YouTube describe la arquitectura
lógica, pero no advierte sobre esta restricción de temporización — se
descubrió al simularlo de verdad.
