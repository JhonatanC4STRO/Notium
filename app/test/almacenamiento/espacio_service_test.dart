import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/almacenamiento/espacio_service.dart';

/// Tests de EspacioService (tarea 4.2, RNF-05) con archivos temporales.
void main() {
  late Directory temporal;
  late File archivoDb;
  late Directory adjuntos;

  setUp(() async {
    temporal = await Directory.systemTemp.createTemp('notium_espacio_');
    archivoDb = File('${temporal.path}/notium.db');
    adjuntos = Directory('${temporal.path}/adjuntos');
  });

  tearDown(() => temporal.delete(recursive: true));

  EspacioService servicio({int limite = EspacioService.limitePorDefecto}) =>
      EspacioService(
        archivoBaseDatos: archivoDb,
        directorioAdjuntos: adjuntos,
        limiteBytes: limite,
      );

  test('sin BD ni adjuntos, el uso es cero', () async {
    final uso = await servicio().medir();
    expect(uso.bytes, 0);
    expect(uso.cercaDelLimite, false);
  });

  test('suma el tamaño de la BD y el de los adjuntos', () async {
    archivoDb.writeAsBytesSync(List.filled(1000, 0));
    await adjuntos.create(recursive: true);
    File('${adjuntos.path}/a.bin').writeAsBytesSync(List.filled(500, 0));
    File('${adjuntos.path}/b.bin').writeAsBytesSync(List.filled(250, 0));

    final uso = await servicio().medir();

    expect(uso.bytes, 1750);
  });

  test('avisa solo al superar el 90% del límite (RNF-05)', () async {
    await adjuntos.create(recursive: true);

    // 80% del límite: todavía no avisa.
    File('${adjuntos.path}/a.bin').writeAsBytesSync(List.filled(800, 0));
    expect((await servicio(limite: 1000).medir()).cercaDelLimite, false);

    // 95%: avisa.
    File('${adjuntos.path}/b.bin').writeAsBytesSync(List.filled(150, 0));
    final uso = await servicio(limite: 1000).medir();
    expect(uso.cercaDelLimite, true);
    expect(uso.fraccion, greaterThan(0.9));
  });

  test('formatea el uso de forma legible', () async {
    archivoDb.writeAsBytesSync(List.filled(2 * 1024 * 1024, 0));
    final uso = await servicio().medir();
    expect(uso.legible, '2.0 MB');
    expect(uso.limiteLegible, '500.0 MB');
  });
}
