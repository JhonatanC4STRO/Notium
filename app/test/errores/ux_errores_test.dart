import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/almacenamiento/espacio_service.dart';
import 'package:notium/data/auth/almacen_seguro.dart';
import 'package:notium/data/auth/almacen_sesion.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/data/repositorios/nota_repository.dart';
import 'package:notium/domain/enums.dart';
import 'package:notium/domain/sesion.dart';
import 'package:notium/presentation/app.dart';
import 'package:notium/presentation/providers.dart';

/// Widget tests de la UX de errores y del aviso de almacenamiento
/// (tarea 4.2; RF-04, RNF-05, sección 5.2).
void main() {
  late AppDatabase db;
  late Directory temporal;
  late AlmacenSeguroEnMemoria almacenSeguro;

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() async {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    temporal = await Directory.systemTemp.createTemp('notium_err_');
    almacenSeguro = AlmacenSeguroEnMemoria();
    await AlmacenSesion(almacenSeguro).guardarSesion(Sesion(
      usuario: const UsuarioSesion(uuid: 'u-1', nombre: 'Test', email: 't@t.co'),
      accessToken: 'a',
      refreshToken: 'r',
      expiraEn: DateTime.now().toUtc().add(const Duration(hours: 1)),
    ));
  });

  tearDown(() async {
    await db.close();
    await temporal.delete(recursive: true);
  });

  /// El uso de disco se inyecta como estado: medirlo de verdad es E/S
  /// asíncrona que no resuelve dentro del reloj falso de un widget test. La
  /// medición real está cubierta en `espacio_service_test.dart`.
  Widget appDePrueba({UsoAlmacenamiento? uso}) => ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          directorioAdjuntosProvider.overrideWithValue(temporal),
          archivoBaseDatosProvider
              .overrideWithValue(File('${temporal.path}/notium.db')),
          almacenSeguroProvider.overrideWithValue(almacenSeguro),
          usuarioActualUuidProvider.overrideWithValue('u-1'),
          syncEnSegundoPlanoProvider.overrideWithValue(false),
          usoAlmacenamientoProvider.overrideWith(
            (ref) async =>
                uso ??
                const UsoAlmacenamiento(
                  bytes: 1024,
                  limiteBytes: EspacioService.limitePorDefecto,
                ),
          ),
        ],
        child: const NotiumApp(),
      );

  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// Deja una nota rechazada por el servidor, como tras un push con ERROR.
  Future<String> notaEnError(String motivo) async {
    final nota = await NotaRepository(db).crear(usuarioUuid: 'u-1', titulo: 'Rechazada');
    await (db.update(db.notas)..where((n) => n.uuid.equals(nota.uuid))).write(
      NotasCompanion(
        syncStatus: const Value(SyncStatus.ERROR),
        syncError: Value(motivo),
      ),
    );
    return nota.uuid;
  }

  testWidgets('la lista muestra el motivo del rechazo y cómo corregirlo (RF-04)',
      (tester) async {
    await notaEnError('El título es obligatorio.');

    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsWidgets); // indicador ERROR
    expect(find.textContaining('El título es obligatorio.'), findsOneWidget);
    expect(find.textContaining('Toca para corregir'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('el editor explica el rechazo y corregir devuelve la nota a PENDING',
      (tester) async {
    final uuid = await notaEnError('Contenido inválido.');

    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    // Abrir la nota en error.
    await tester.tap(find.text('Rechazada'));
    await tester.pumpAndSettle();

    expect(find.text('El servidor rechazó este cambio'), findsOneWidget);
    expect(find.text('Contenido inválido.'), findsOneWidget);

    // Corregir y guardar: sección 5.2 → ERROR vuelve a PENDING y se limpia
    // el motivo, de modo que la SyncTask la reintente.
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Corregida');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final nota =
        await (db.select(db.notas)..where((n) => n.uuid.equals(uuid))).getSingle();
    expect(nota.titulo, 'Corregida');
    expect(nota.syncStatus, SyncStatus.PENDING);
    expect(nota.syncError, isNull);
    await desmontar(tester);
  });

  testWidgets('sin presión de espacio no se muestra el aviso (RNF-05)', (tester) async {
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    expect(find.textContaining('Almacenamiento casi lleno'), findsNothing);
    await desmontar(tester);
  });

  testWidgets('cerca del límite aparece el aviso de almacenamiento (RNF-05)',
      (tester) async {
    // 480 MB de 500 MB: por encima del umbral de aviso (90%).
    await tester.pumpWidget(appDePrueba(
      uso: const UsoAlmacenamiento(
        bytes: 480 * 1024 * 1024,
        limiteBytes: EspacioService.limitePorDefecto,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Almacenamiento casi lleno'), findsOneWidget);
    await desmontar(tester);
  });
}
