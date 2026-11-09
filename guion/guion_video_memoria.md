# Guion — Memoria RAM parametrizada (puntos extra)

José Daniel Cuá Fagiani — Carné 21200. Duración estimada: ~10-10.5
minutos. Mostrar cámara mientras se habla. Tener abiertas de
antemano, ANTES de empezar a grabar:

- El repositorio en GitHub y el landing page.
- El editor (VS Code) con los archivos de `rtl/` y `docs/` en pestañas.
- La ventana de Vivado Simulator **ya corrida**, con las ondas de
  `sim/wave.tcl` cargadas y el zoom ajustado a toda la simulación
  (botón "Zoom Fit") — no hace falta correr ningún comando durante la
  grabación, solo dejarla abierta así y mostrarla cuando toque.

Cada paso de acá abajo dice **qué pestaña/archivo abrir** y **qué
decir mientras esa pestaña está en pantalla**, en orden. Cuando
termines el texto de una pestaña, recién ahí cambiás a la siguiente.

## 0. Apertura (30 seg)

**Abrir:** el landing del repositorio.

**Decir:**
"Hola profe, esto es el trabajo de puntos extra, aparte del examen
final. La consigna era implementar en SystemVerilog, parametrizado,
la estructura de memoria que explica este video de YouTube —
*How Transistors Remember Data*, del canal Core Dumped — y entregarlo
como un repositorio más un video explicando cómo funciona por dentro.
Todo lo que voy a mostrar corrió de verdad en simulación, no son
capturas de otro lado."

## 1. La idea central: realimentación = memoria (1 min)

**Abrir:** `docs/01-celda-basica.md`.

**Decir:**
"El video arranca de una idea simple: para que un circuito 'recuerde'
algo, su salida tiene que realimentarse a su propia entrada. Una
compuerta OR con su salida realimentada solo puede recordar un uno;
una AND con su salida realimentada solo puede recordar un cero. El
video las combina en lo que llama un AND-OR latch: si pongo `set` en
uno, `q` pasa a uno y se queda ahí aunque `set` vuelva a cero después;
y si pongo `reset` en uno, pasa lo mismo pero para el cero."

**Abrir:** `rtl/and_or_latch.sv`.

**Decir:**
"Esto está implementado acá con compuertas primitivas de Verilog —
`and`, `or`, `not` — a propósito, sin ningún reloj: el bit se retiene
solo por la realimentación estructural, igual que en el video."

## 2. Gated latch y registro (1.5 min)

**Abrir:** `rtl/gated_latch.sv`.

**Decir:**
"El problema de usar set/reset directo es que un dato normalmente es
un solo bit, no dos líneas separadas de 'poner' y 'borrar'. Por eso se
agrega una línea de write enable: si `wr_en` está en cero, el latch
ignora completamente el dato que le llegue y mantiene lo que ya tenía
guardado; si `wr_en` está en uno, copia el valor que le estoy pasando
y lo retiene después, aunque el dato o el `wr_en` vuelvan a cero."

**Abrir:** `rtl/register.sv`.

**Decir:**
"Juntando varios de estos gated latches con el mismo write enable
compartido se forma un registro — acá está `register.sv`,
parametrizado en el ancho, con un `generate` que instancia tantos
gated latches como bits se pidan. Este módulo lo dejé aparte, con su
propio testbench, porque es exactamente el paso intermedio que
describe el video antes de llegar a la matriz."

## 3. El problema de escalar y el decodificador (1.5 min)

**Abrir:** `docs/03-decodificador.md`.

**Decir:**
"El video señala el problema de seguir alargando el registro: una
memoria de un gigabyte necesitaría millones de cables. La solución es
organizar los latches en una matriz y direccionar cada uno con un
decodificador de filas y uno de columnas."

**Abrir:** `rtl/decoder.sv`.

**Decir:**
"Un decodificador recibe N bits y activa exactamente una de sus 2 a
la N salidas — acá en `decoder.sv`, parametrizado en N, comparando
cada bit de la entrada contra el literal de cada salida. Lo probé
aislado antes de integrarlo: para N igual a 2, las cuatro
combinaciones de entrada activan exactamente una salida cada una, sin
solapamientos."

## 4. Celda direccionable, bus triestado y matriz (2 min)

**Abrir:** `rtl/mem_cell.sv`.

**Decir:**
"Para no necesitar un cable de entrada y otro de salida por cada
celda, el video agrega un read enable y usa la misma línea para los
dos sentidos. Acá en `mem_cell.sv` esa línea es un puerto `inout`: el
dato entra directo al gated latch, que lo ignora si no se está
escribiendo esa celda; y hay una línea que hace que esta celda
específica maneje el bus solo cuando le toca ser leída — en cualquier
otro momento se queda en alta impedancia, para no estorbar a las demás
celdas que comparten la misma línea. Es el mismo mecanismo de bus
triestado que ya usé en la ALU del examen final."

**Abrir:** `rtl/mem_matrix.sv`.

**Decir:**
"Acá se juntan el decodificador de filas, el de columnas, y por cada
celda un AND que combina la selección de fila, de columna, y el write
o read enable globales — así que solo la celda en la intersección
exacta de la dirección recibe la señal de escritura o lectura."

## 5. mem_top: de bits a bytes, y un bug real que encontré (2 min)

**Abrir:** `rtl/mem_top.sv`.

**Decir:**
"Para guardar una palabra completa en vez de un solo bit, el video
repite la matriz una vez por cada bit de la palabra, todas compartiendo
la misma dirección y el mismo control. Eso es `mem_top`: parametrizado
en `ADDR_WIDTH` y `DATA_WIDTH`, por defecto justo el ejemplo del
video, una matriz 4 por 4 de bytes."

**Abrir:** `docs/06-verificacion.md`.

**Decir:**
"Algo que vale la pena contar: al simular esto encontré un bug real.
Escribir en una dirección corrompía otra dirección que ya tenía un
valor guardado. Lo investigué por capas: probé el decodificador solo
—bien—, probé dos celdas de memoria manuales sin decodificador
—bien—, probé la matriz completa —ahí apareció el problema—, y puse
una sonda sobre la señal interna de escritura de cada celda. La señal
en sí era correcta; el problema era que yo cambiaba la dirección y
activaba el write enable en el mismo instante, y como este latch no
tiene reloj que lo proteja, un glitch transitorio del decodificador
durante el cambio de dirección se podía quedar grabado en la celda
equivocada. La corrección fue cambiar la disciplina de temporización
en el testbench: fijar la dirección primero, dejarla asentar, y
después activar el control — igual que exige cualquier memoria
asíncrona real."

## 6. Leer la forma de onda y los resultados (1.5-2 min)

**Abrir:** la ventana de Vivado Simulator (ya abierta de antemano, ver
nota del inicio), con la vista ajustada a toda la simulación.

**Decir:**
"Esto ya lo tengo corrido de antes: es la misma simulación de
`mem_top`, pero en el visor de formas de onda en vez de solo texto,
para que se vea de verdad cómo funciona y no solo que lo cuente. Acá
abajo, en la consola, dice `TESTBENCH: PASS, 22 de 22 checks` — esa es
la prueba de que la memoria funciona exactamente como debería en los
22 casos que verifiqué: escrituras, lecturas, que una dirección no se
corrompa al escribir otra, y el barrido completo de las 16 direcciones.

"Arriba tengo las señales. `addr` es la dirección que se está usando
en cada momento. `wr_en` se pone en uno cada vez que estoy escribiendo,
y `rd_en` cuando estoy leyendo. `data` es el bus de datos: cuando ni
escribo ni leo, se queda en `Z` — alta impedancia, nadie lo maneja — y
cuando sí, toma el valor que se está escribiendo o el que se está
leyendo. Y estas de más abajo son la dirección partida en fila y
columna, que es lo que usa la matriz por dentro para decodificar.

"Miren este primer tramo: dirección 0, se escribe, después se lee, y
el valor que sale es el mismo que entró. Después dirección 5, mismo
patrón. Y después viene un barrido completo: se escriben las 16
direcciones una por una, y después se vuelven a leer todas, para
comprobar que cada una guardó su propio valor sin pisar a las demás —
justo lo que antes expliqué que fallaba por el bug de temporización, y
acá se ve que ya quedó resuelto.

"Y las tres verificaciones en total — esta de la memoria 4 por 4, la
del registro independiente, y la de la misma arquitectura con otros
parámetros, una matriz de 8 por 8 con palabras de 16 bits — pasan
limpio sin tocar ningún módulo, solo cambiando los parámetros. Eso
demuestra que sí quedó parametrizado de verdad, no con un solo tamaño
fijo."

## 7. Cierre (30 seg)

**Decir:**
"Eso es toda la estructura: celda básica, gated latch, registro,
decodificador, celda direccionable con bus triestado, matriz, y el
módulo top que junta todo como una memoria de acceso aleatorio. Todo
el código, la documentación capa por capa y las simulaciones están en
el repositorio. Gracias."
