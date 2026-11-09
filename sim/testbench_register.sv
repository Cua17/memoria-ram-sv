// testbench_register.sv
//
// Verificacion del modulo intermedio register.sv (8 gated_latch con
// wr_en compartido), de forma independiente de la matriz de memoria.
// Confirma el comportamiento que describe el video: con wr_en=0 el
// registro ignora por completo la entrada d y retiene su valor
// anterior; con wr_en=1 copia d y lo conserva aunque d o wr_en bajen
// despues.
`timescale 1ns/1ps

module testbench_register;

    localparam int WIDTH = 8;

    logic [WIDTH-1:0] d;
    logic              wr_en;
    wire  [WIDTH-1:0] q;

    integer errors = 0;
    integer checks = 0;

    register #(.WIDTH(WIDTH)) dut (
        .d     (d),
        .wr_en (wr_en),
        .q     (q)
    );

    task check(input [WIDTH-1:0] expected, input string name);
        begin
            checks = checks + 1;
            if (q !== expected) begin
                errors = errors + 1;
                $display("FAIL [%s] esperado=%0h leido=%0h", name, expected, q);
            end else begin
                $display("PASS [%s] q=%0h", name, q);
            end
        end
    endtask

    initial begin
        d     = '0;
        wr_en = 1'b0;
        #5;

        // valor inicial conocido (forzado con wr_en, no se asume el
        // estado de arranque de la realimentacion)
        d = 8'h00; wr_en = 1'b1; #10; wr_en = 1'b0; #5;
        check(8'h00, "valor_inicial_forzado");

        // con wr_en=0, cambiar d no debe afectar a q
        d = 8'hFF;
        #10;
        check(8'h00, "ignora_dato_sin_wr_en");

        // ahora si se activa wr_en, debe capturar el nuevo valor
        wr_en = 1'b1; #10; wr_en = 1'b0; #5;
        check(8'hFF, "captura_con_wr_en");

        // vuelve a ignorar cambios en d con wr_en=0
        d = 8'h3C;
        #10;
        check(8'hFF, "retiene_tras_bajar_wr_en");

        // nueva escritura legitima
        wr_en = 1'b1; #10; wr_en = 1'b0; #5;
        check(8'h3C, "nueva_escritura");

        $display("------------------------------------------------");
        if (errors == 0)
            $display("TESTBENCH_REGISTER: PASS (%0d/%0d checks)", checks, checks);
        else
            $display("TESTBENCH_REGISTER: FAIL (%0d errores de %0d checks)", errors, checks);
        $finish;
    end

endmodule
