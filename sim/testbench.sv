// testbench.sv
//
// Verificacion funcional de mem_top con los parametros por defecto
// (ADDR_WIDTH=4, DATA_WIDTH=8 -> matriz 4x4, el mismo ejemplo numerico
// que usa el video). Cubre: bus en alta impedancia cuando esta ocioso,
// escritura/lectura simple, que escribir una direccion no corrompa
// otra, sobreescritura, y un barrido completo de las 16 direcciones.
`timescale 1ns/1ps

module testbench;

    localparam int ADDR_WIDTH = 4;
    localparam int DATA_WIDTH = 8;

    logic [ADDR_WIDTH-1:0] addr;
    logic                  wr_en;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] data_drive;
    logic                  drive_data;
    wire  [DATA_WIDTH-1:0] data;

    assign data = drive_data ? data_drive : {DATA_WIDTH{1'bz}};

    integer errors = 0;
    integer checks = 0;

    mem_top #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH)
    ) dut (
        .addr  (addr),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .data  (data)
    );

    // IMPORTANTE: la dirección se fija y se deja asentar con wr_en/rd_en
    // en 0 ANTES de activar el control. El and_or_latch es asíncrono
    // (sin reloj): si la dirección y wr_en cambiaran en el mismo
    // instante, un glitch transitorio del decodificador durante el
    // cambio de dirección podría quedar "grabado" en la celda
    // equivocada. Esta disciplina de temporización (dirección estable
    // antes de activar el control) es la misma que exige cualquier
    // memoria asíncrona real.
    task write_byte(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] val);
        begin
            wr_en = 1'b0;
            rd_en = 1'b0;
            addr  = a;
            #2;
            data_drive = val;
            drive_data = 1'b1;
            wr_en      = 1'b1;
            #10;
            wr_en      = 1'b0;
            drive_data = 1'b0;
            #5;
        end
    endtask

    task check_read(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] expected, input string name);
        begin
            wr_en      = 1'b0;
            rd_en      = 1'b0;
            drive_data = 1'b0;
            addr       = a;
            #2;
            rd_en      = 1'b1;
            #10;
            checks = checks + 1;
            if (data !== expected) begin
                errors = errors + 1;
                $display("FAIL [%s] addr=%0d esperado=%0h leido=%0h", name, a, expected, data);
            end else begin
                $display("PASS [%s] addr=%0d valor=%0h", name, a, data);
            end
            rd_en = 1'b0;
            #5;
        end
    endtask

    task check_highz(input string name);
        begin
            wr_en      = 1'b0;
            rd_en      = 1'b0;
            drive_data = 1'b0;
            addr       = '0;
            #10;
            checks = checks + 1;
            if (data !== {DATA_WIDTH{1'bz}}) begin
                errors = errors + 1;
                $display("FAIL [%s] se esperaba alta impedancia, bus=%b", name, data);
            end else begin
                $display("PASS [%s] bus en alta impedancia como se esperaba", name);
            end
        end
    endtask

    initial begin
        drive_data = 1'b0;
        data_drive = '0;
        wr_en      = 1'b0;
        rd_en      = 1'b0;
        addr       = '0;
        #5;

        // 1) bus ocioso en alta impedancia antes de cualquier operacion
        check_highz("bus_ocioso_inicial");

        // 2) escritura y lectura simple en direccion 0
        write_byte(4'd0, 8'hA5);
        check_read(4'd0, 8'hA5, "addr0_tras_escribir");

        // 3) escritura en otra direccion de la misma matriz 4x4
        //    (addr5 = fila1,col1; distinta fila y columna de addr0)
        write_byte(4'd5, 8'h3C);
        check_read(4'd5, 8'h3C, "addr5_tras_escribir");

        // 4) addr0 no debe haberse corrompido por escribir addr5
        check_read(4'd0, 8'hA5, "addr0_no_corrompido");

        // 5) sobreescritura de un valor ya guardado
        write_byte(4'd0, 8'h5A);
        check_read(4'd0, 8'h5A, "addr0_sobreescrito");

        // 6) recorrer las 16 direcciones con patrones distintos
        for (int i = 0; i < 16; i++) begin
            logic [DATA_WIDTH-1:0] pattern;
            pattern = (i * 7 + 1) & 8'hFF;
            write_byte(i[3:0], pattern);
        end
        for (int i = 0; i < 16; i++) begin
            logic [DATA_WIDTH-1:0] pattern;
            pattern = (i * 7 + 1) & 8'hFF;
            check_read(i[3:0], pattern, $sformatf("barrido_addr%0d", i));
        end

        // 7) bus vuelve a alta impedancia cuando ni se lee ni se escribe
        check_highz("bus_ocioso_final");

        $display("------------------------------------------------");
        if (errors == 0)
            $display("TESTBENCH: PASS (%0d/%0d checks)", checks, checks);
        else
            $display("TESTBENCH: FAIL (%0d errores de %0d checks)", errors, checks);
        $finish;
    end

endmodule
