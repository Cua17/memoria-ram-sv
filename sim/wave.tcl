# wave.tcl
#
# Agrega al visor de formas de onda de Vivado (xsim GUI) las senales
# clave para demostrar en vivo el funcionamiento de mem_top: la
# interfaz externa (direccion, controles, bus de datos) y, por dentro
# del plano de bit 0, la decodificacion de fila/columna. A proposito
# se dejan solo 8 senales (nada de senales de una celda puntual) para
# que entren todas en pantalla sin tener que hacer scroll -- son las
# mismas que explica sim/../guion/guion_video_memoria.md, paso 6.
# Pensado para correr dentro de la GUI de xsim (Tools > Run Tcl
# Script, o "source sim/wave.tcl" en la consola Tcl).
#
# Nota: los nombres entre llaves usan la sintaxis de identificador
# escapado de Verilog (\nombre seguido de un espacio) porque el scope
# de un generate indexado (bit_plane[0]) se representa asi en la
# jerarquia de xsim -- no es un error de tipeo, hay que mantener el
# espacio despues del nombre escapado.

add_wave /testbench/addr
add_wave /testbench/wr_en
add_wave /testbench/rd_en
add_wave /testbench/data

add_wave {/testbench/dut/\bit_plane[0].plane /row_addr}
add_wave {/testbench/dut/\bit_plane[0].plane /col_addr}
add_wave {/testbench/dut/\bit_plane[0].plane /row_sel}
add_wave {/testbench/dut/\bit_plane[0].plane /col_sel}

run all
