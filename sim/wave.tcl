# wave.tcl
#
# Agrega al visor de formas de onda de Vivado (xsim GUI) las senales
# clave para demostrar en vivo el funcionamiento de mem_top: la
# interfaz externa (direccion, controles, bus de datos) y, por dentro
# del plano de bit 0, la decodificacion de fila/columna y una celda
# puntual seleccionada (fila 0, columna 0). Pensado para correr dentro
# de la GUI de xsim (Tools > Run Tcl Script, o "source sim/wave.tcl"
# en la consola Tcl).
#
# Nota: los nombres entre llaves usan la sintaxis de identificador
# escapado de Verilog (\nombre seguido de un espacio) porque los
# scopes de un generate indexado (ej. bit_plane[0], row_g[0].col_g[0])
# se representan asi en la jerarquia de xsim -- no son un error de
# tipeo, hay que mantener el espacio despues de cada nombre escapado.

add_wave /testbench/addr
add_wave /testbench/wr_en
add_wave /testbench/rd_en
add_wave /testbench/data

add_wave {/testbench/dut/\bit_plane[0].plane /row_addr}
add_wave {/testbench/dut/\bit_plane[0].plane /col_addr}
add_wave {/testbench/dut/\bit_plane[0].plane /row_sel}
add_wave {/testbench/dut/\bit_plane[0].plane /col_sel}

add_wave {/testbench/dut/\bit_plane[0].plane /\row_g[0].col_g[0].cell_sel}
add_wave {/testbench/dut/\bit_plane[0].plane /\row_g[0].col_g[0].cell_wr}
add_wave {/testbench/dut/\bit_plane[0].plane /\row_g[0].col_g[0].cell_rd}

run all
