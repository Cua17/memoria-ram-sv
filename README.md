# Memoria RAM parametrizada en SystemVerilog (puntos extra)

Trabajo de puntos extra del curso (Arquitectura de Computadoras, curso
"Manejo de Base de Datos" pivoteado a mitad de semestre — ver también
[examen-final-alu-plus](https://github.com/Cua17/examen-final-alu-plus)
para la parte práctica principal del curso).

Consigna: implementar la estructura de memoria descrita en el video
[*How Transistors Remember Data*](https://www.youtube.com/watch?v=rM9BjciBLmg)
(canal Core Dumped) en SystemVerilog parametrizado, como un módulo
top. Entregable: este repositorio + un video explicando el
funcionamiento interno del esquema de memoria.

José Daniel Cuá Fagiani — Carné 21200

## Resultado principal (verificado)

| Testbench | Qué cubre | Resultado |
|---|---|---|
| `sim/testbench.sv` | `mem_top` por defecto — matriz 4x4, 16 bytes (xvlog/xelab/xsim) | **22/22 PASS** |
| `sim/testbench_register.sv` | `register` de 8 bits (módulo intermedio del video) | **5/5 PASS** |
| `sim/testbench_params.sv` | `mem_top` con `ADDR_WIDTH=6`, `DATA_WIDTH=16` — matriz 8x8, 64 palabras de 16 bits | **5/5 PASS** |

Ver [`docs/06-verificacion.md`](docs/06-verificacion.md) para el detalle
completo, incluyendo un bug de temporización real que se encontró y
corrigió durante la verificación (no solo "corrió a la primera").

## Cómo el código sigue al video, paso a paso

El video construye la memoria en capas; este repositorio tiene un
módulo por capa, cada uno documentado y verificado por separado:

1. [Celda básica — AND-OR latch](docs/01-celda-basica.md) →
   [`rtl/and_or_latch.sv`](rtl/and_or_latch.sv)
2. [Gated latch y registro](docs/02-gated-latch-registro.md) →
   [`rtl/gated_latch.sv`](rtl/gated_latch.sv),
   [`rtl/register.sv`](rtl/register.sv)
3. [Decodificador de direcciones](docs/03-decodificador.md) →
   [`rtl/decoder.sv`](rtl/decoder.sv)
4. [Celda direccionable + bus triestado + matriz](docs/04-matriz-y-bus-triestado.md) →
   [`rtl/mem_cell.sv`](rtl/mem_cell.sv), [`rtl/mem_matrix.sv`](rtl/mem_matrix.sv)
5. [mem_top: palabra completa + abstracción de RAM](docs/05-mem-top.md) →
   [`rtl/mem_top.sv`](rtl/mem_top.sv)
6. [Verificación](docs/06-verificacion.md)

## Estructura del repositorio

```
rtl/    and_or_latch.sv, gated_latch.sv, register.sv, decoder.sv,
        mem_cell.sv, mem_matrix.sv, mem_top.sv
sim/    testbench.sv, testbench_register.sv, testbench_params.sv
docs/   un documento por capa de la arquitectura + verificación
guion/  guion para el video explicando el funcionamiento interno
```

## mem_top — interfaz

```systemverilog
module mem_top #(
    parameter int ADDR_WIDTH = 4,   // por defecto: 16 palabras (matriz 4x4, igual que el video)
    parameter int DATA_WIDTH = 8    // por defecto: 1 byte por palabra
) (
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire                  wr_en,
    input  wire                  rd_en,
    inout  wire [DATA_WIDTH-1:0] data
);
```

- `wr_en=1` escribe el valor manejado en `data` en la palabra `addr`.
- `rd_en=1` hace que `data` sea manejado por la memoria con el valor
  almacenado en `addr` (alta impedancia en cualquier otro caso).
- `wr_en` y `rd_en` no deben activarse juntos.
- La dirección debe estar estable (igual que cualquier memoria
  asíncrona real) antes de activar `wr_en`/`rd_en` — ver
  [docs/06-verificacion.md](docs/06-verificacion.md).

## Cómo reproducir la simulación

Vivado Simulator 2026.1 por línea de comandos (sin GUI):

```bash
cd MemoriaRAM
xvlog --sv rtl/and_or_latch.sv rtl/gated_latch.sv rtl/register.sv rtl/decoder.sv rtl/mem_cell.sv rtl/mem_matrix.sv rtl/mem_top.sv sim/testbench.sv sim/testbench_register.sv sim/testbench_params.sv
xelab testbench -s testbench_sim && xsim testbench_sim -runall
xelab testbench_register -s testbench_register_sim && xsim testbench_register_sim -runall
xelab testbench_params -s testbench_params_sim && xsim testbench_params_sim -runall
```

Cada corrida debe terminar en `TESTBENCH...: PASS (N/N checks)`.

## Cómo demostrarlo en vivo (formas de onda en Vivado)

Para el video conviene mostrar las señales en el visor de formas de
onda de Vivado (xsim GUI), no solo el texto de PASS/FAIL. Para eso
hace falta elaborar con información de depuración completa:

```bash
cd MemoriaRAM
xvlog --sv rtl/and_or_latch.sv rtl/gated_latch.sv rtl/register.sv rtl/decoder.sv rtl/mem_cell.sv rtl/mem_matrix.sv rtl/mem_top.sv sim/testbench.sv
xelab testbench -s testbench_sim -debug all
xsim testbench_sim -gui
```

Con la GUI abierta, en la consola Tcl (parte inferior) escribir:

```tcl
source sim/wave.tcl
```

Esto agrega automáticamente las señales clave (dirección, `wr_en`,
`rd_en`, bus de datos, y por dentro del plano de bit 0: direcciones de
fila/columna, salidas del decodificador, y las señales de selección de
una celda puntual) y corre toda la simulación — ya queda todo dibujado
para señalar en cámara: la dirección cambiando, la escritura, la
lectura, y el bus en alta impedancia cuando está ocioso. El contenido
exacto de `sim/wave.tcl` (y por qué los nombres de las señales internas
llevan esa sintaxis con barra invertida) está comentado en el propio
archivo.

## Video

Guion en [`guion/guion_video_memoria.md`](guion/guion_video_memoria.md).
