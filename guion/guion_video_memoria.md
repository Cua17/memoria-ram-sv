# Guion — Memoria RAM parametrizada (puntos extra)

José Daniel Cuá Fagiani — Carné 21200. Duración estimada: 8-10 minutos.
Mostrar cámara mientras se habla. Tener abiertas de antemano: el
repositorio en GitHub, el landing page, y el editor con los archivos
de `rtl/`.

## 0. Apertura (30 seg)

**Mostrar:** el landing del repositorio.

**Decir:**
"Hola profe, esto es el trabajo de puntos extra, aparte del examen
final. La consigna era implementar en SystemVerilog, parametrizado,
la estructura de memoria que explica este video de YouTube —
*How Transistors Remember Data*, del canal Core Dumped — y entregarlo
como un repositorio más un video explicando cómo funciona por dentro.
Todo lo que voy a mostrar corrió de verdad en simulación, no son
capturas de otro lado."

## 1. La idea central: realimentación = memoria (1 min)

**Mostrar:** `docs/01-celda-basica.md` y `rtl/and_or_latch.sv`.

**Decir:**
"El video arranca de una idea simple: para que un circuito 'recuerde'
algo, su salida tiene que realimentarse a su propia entrada. Una
compuerta OR con su salida realimentada solo puede recordar un uno; una
AND con su salida realimentada solo puede recordar un cero. El video
las combina en lo que llama un AND-OR latch: la salida `q` es
`(set OR q) AND (NOT reset)`. Si pongo `set` en uno, `q` se queda en
uno aunque `set` vuelva a cero; si pongo `reset` en uno, pasa lo
mismo pero para el cero. Esto está implementado acá con compuertas
primitivas de Verilog — `and`, `or`, `not` — a propósito, sin ningún
reloj: el bit se retiene solo por la realimentación estructural, igual
que en el video."

## 2. Gated latch y registro (1.5 min)

**Mostrar:** `rtl/gated_latch.sv` y `rtl/register.sv`.

**Decir:**
"El problema de usar set/reset directo es que un dato normalmente es
un solo bit, no dos líneas separadas de 'poner' y 'borrar'. Por eso se
agrega una línea de write enable: `set = d AND wr_en`, `reset =
(NOT d) AND wr_en`. Si `wr_en` está en cero, el latch ignora
completamente el dato y mantiene su valor; si está en uno, copia el
dato y lo retiene después. Juntando varios de estos gated latches con
el mismo write enable compartido se forma un registro — acá está
`register.sv`, parametrizado en el ancho, con un `generate` que
instancia tantos gated latches como bits se pidan. Este módulo lo dejé
aparte, con su propio testbench, porque es exactamente el paso
intermedio que describe el video antes de llegar a la matriz."

## 3. El problema de escalar y el decodificador (1.5 min)

**Mostrar:** `docs/03-decodificador.md` y `rtl/decoder.sv`.

**Decir:**
"El video señala el problema de seguir alargando el registro: una
memoria de un gigabyte necesitaría millones de cables. La solución es
organizar los latches en una matriz y direccionar cada uno con un
decodificador de filas y uno de columnas. Un decodificador recibe N
bits y activa exactamente una de sus 2 a la N salidas — acá en
`decoder.sv`, parametrizado en N, comparando cada bit de la entrada
contra el literal de cada salida. Lo probé aislado antes de integrarlo:
para N igual a 2, las cuatro combinaciones de entrada activan
exactamente una salida cada una, sin solapamientos."

## 4. Celda direccionable, bus triestado y matriz (2 min)

**Mostrar:** `rtl/mem_cell.sv` y `rtl/mem_matrix.sv`.

**Decir:**
"Para no necesitar un cable de entrada y otro de salida por cada
celda, el video agrega un read enable y usa la misma línea para los
dos sentidos. Acá en `mem_cell.sv` esa línea es un puerto `inout`: el
dato entra directo al gated latch, que lo ignora si no se está
escribiendo esa celda; y hay un `assign data = rd_sel ? q : 1'bz` que
solo maneja el bus cuando a esta celda específica le toca ser leída —
el mismo mecanismo de bus triestado que ya usé en la ALU del examen
final. En `mem_matrix.sv` se juntan el decodificador de filas, el de
columnas, y por cada celda un AND que combina la selección de fila,
de columna, y el write o read enable globales — así que solo la celda
en la intersección exacta de la dirección recibe la señal de
escritura o lectura."

## 5. mem_top: de bits a bytes, y un bug real que encontré (2 min)

**Mostrar:** `rtl/mem_top.sv` y `docs/06-verificacion.md`.

**Decir:**
"Para guardar una palabra completa en vez de un solo bit, el video
repite la matriz una vez por cada bit de la palabra, todas compartiendo
la misma dirección y el mismo control. Eso es `mem_top`: parametrizado
en `ADDR_WIDTH` y `DATA_WIDTH`, por defecto justo el ejemplo del
video, una matriz 4 por 4 de bytes.

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

## 6. Resultados de simulación (1 min)

**Mostrar:** terminal con la corrida real de `xvlog`/`xelab`/`xsim`.

**Decir:**
"Con esa corrección, las tres verificaciones pasan limpio: 22 de 22
checks para la memoria 4 por 4 de bytes, 5 de 5 para el registro
independiente, y 5 de 5 para la misma arquitectura instanciada con
otros parámetros — una matriz de 8 por 8 con palabras de 16 bits, sin
tocar ningún módulo, solo cambiando los parámetros. Esto demuestra que
sí quedó parametrizado de verdad, no con un solo tamaño fijo."

## 7. Cierre (30 seg)

**Decir:**
"Eso es toda la estructura: celda básica, gated latch, registro,
decodificador, celda direccionable con bus triestado, matriz, y el
módulo top que junta todo como una memoria de acceso aleatorio. Todo
el código, la documentación capa por capa y las simulaciones están en
el repositorio. Gracias."
