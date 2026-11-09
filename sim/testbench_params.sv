// testbench_params.sv
//
// Prueba que mem_top sea realmente parametrizable: se instancia con
// ADDR_WIDTH=6 y DATA_WIDTH=16 (matriz 8x8 = 64 palabras de 16 bits,
// en vez de la matriz 4x4 de 8 bits por defecto) sin tocar ningun
// modulo. Verifica direcciones en distintas zonas de la matriz
// (esquina inicial, esquina final, e intermedia) para confirmar que
// la decodificacion de fila/columna escala correctamente.
`timescale 1ns/1ps

module testbench_params;

    localparam int ADDR_WIDTH = 6;
    localparam int DATA_WIDTH = 16;

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

    // Misma disciplina de temporización que testbench.sv: la dirección
    // se fija y se deja asentar con wr_en/rd_en en 0 antes de activar
    // el control, para no exponer al decodificador/latch a un glitch
    // transitorio durante el cambio de dirección.
    task write_word(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] val);
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

    initial begin
        drive_data = 1'b0;
        data_drive = '0;
        wr_en       = 1'b0;
        rd_en       = 1'b0;
        addr        = '0;
        #5;

        write_word(6'd0,  16'hBEEF);
        write_word(6'd1,  16'hCAFE);
        write_word(6'd36, 16'h1234); // zona intermedia de la matriz 8x8
        write_word(6'd63, 16'hFFFF); // ultima direccion

        check_read(6'd0,  16'hBEEF, "addr0_matriz_8x8");
        check_read(6'd1,  16'hCAFE, "addr1_matriz_8x8");
        check_read(6'd36, 16'h1234, "addr36_matriz_8x8");
        check_read(6'd63, 16'hFFFF, "addr63_matriz_8x8");

        // confirmar que las escrituras posteriores no corrompieron addr0
        check_read(6'd0,  16'hBEEF, "addr0_no_corrompido_matriz_8x8");

        $display("------------------------------------------------");
        if (errors == 0)
            $display("TESTBENCH_PARAMS: PASS (%0d/%0d checks)", checks, checks);
        else
            $display("TESTBENCH_PARAMS: FAIL (%0d errores de %0d checks)", errors, checks);
        $finish;
    end

endmodule
