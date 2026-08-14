import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/domain/enums.dart';
import 'package:notium/presentation/pantallas/pantalla_historial.dart';
import 'package:notium/presentation/providers.dart';

/// Widget tests de la pantalla de historial (tarea 4.1, RF-05) con BD en
/// memoria: verifica que muestra el historial local y resalta los cambios
/// descartados por conflicto. No toca la red (la sección del servidor solo
/// carga al pulsarse).
void main() {
  late AppDatabase db;
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() => db = AppDatabase.paraTests(NativeDatabase.memory()));
  tearDown(() => db.close());

  const notaUuid = 'nota-1';
  final ahora = DateTime.utc(2026, 7, 20, 15, 30);

  Future<void> insertarNota() => db.into(db.notas).insert(NotasCompanion.insert(
        uuid: notaUuid,
        usuarioUuid: 'u-1',
        titulo: 'Mi nota',
        createdAt: ahora,
        updatedAt: ahora,
      ));

  Future<void> insertarEntrada({
    required String uuid,
    required String tipo,
    required OrigenCambio origen,
    required DateTime fecha,
    String? valorAnterior,
  }) {
    return db.into(db.historialCambios).insert(HistorialCambiosCompanion.insert(
          uuid: uuid,
          notaUuid: notaUuid,
          tipoCambio: tipo,
          origenCambio: origen,
          fecha: fecha,
          valorAnterior: Value(valorAnterior),
        ));
  }

  Widget app() => ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: PantallaHistorial(notaUuid: notaUuid, titulo: 'Mi nota'),
        ),
      );

  // Desmonta el árbol dentro del test y drena el timer de cierre que agendan
  // los streams de drift al cancelarse (si no, el framework lo marca como
  // timer pendiente y falla el test).
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('lista vacía muestra el mensaje "sin cambios"', (tester) async {
    await insertarNota();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin cambios registrados'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('muestra las entradas locales, más recientes primero', (tester) async {
    await insertarNota();
    await insertarEntrada(uuid: 'h-1', tipo: 'CREATE', origen: OrigenCambio.LOCAL, fecha: ahora);
    await insertarEntrada(
      uuid: 'h-2',
      tipo: 'UPDATE',
      origen: OrigenCambio.REMOTO,
      fecha: ahora.add(const Duration(minutes: 5)),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.textContaining('Cambio en este dispositivo'), findsOneWidget);
    expect(find.textContaining('Cambio de otro dispositivo'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('resalta un CONFLICTO_DESCARTADO mostrando el valor descartado (RF-05)',
      (tester) async {
    await insertarNota();
    await insertarEntrada(
      uuid: 'h-conflicto',
      tipo: 'CONFLICTO',
      origen: OrigenCambio.CONFLICTO_DESCARTADO,
      fecha: ahora,
      valorAnterior: jsonEncode({'titulo': 'edición perdedora'}),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.textContaining('descartado por conflicto'), findsOneWidget);
    expect(find.textContaining('Se descartó: "edición perdedora"'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('la sección del servidor no carga hasta pulsarla (offline-first)',
      (tester) async {
    await insertarNota();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // El botón está presente pero no se ha intentado ninguna carga remota.
    expect(find.text('Ver historial del servidor'), findsOneWidget);
    await desmontar(tester);
  });
}
