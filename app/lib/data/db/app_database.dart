import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/enums.dart';
import 'clave_cifrado.dart';
import 'tablas.dart';

part 'app_database.g.dart';

/// Base de datos local de Notium (tarea 2.2): la ÚNICA fuente de datos de la
/// UI (Single Source of Truth, sección 3.1). Cifrada con SQLCipher desde la
/// v1 — retrofitearlo después obligaría a migrar el archivo completo.
@DriftDatabase(tables: [Notas, Adjuntos, HistorialCambios, Usuarios, SyncMeta])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_abrirCifrada());

  /// Para tests: BD en memoria sin cifrado ni plugins de plataforma.
  AppDatabase.paraTests(super.ejecutor);

  @override
  int get schemaVersion => 4;

  /// Migraciones versionadas (tarea 2.2). v2 (3.2): columna `sincronizado`
  /// para distinguir CREATE de UPDATE en el push. v3 (3.3): tabla `sync_meta`
  /// para el cursor de pull. v4 (4.2): columna `sync_error` con el motivo del
  /// rechazo del servidor.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, desde, hasta) async {
          if (desde < 2) {
            await m.addColumn(notas, notas.sincronizado);
            await m.addColumn(adjuntos, adjuntos.sincronizado);
          }
          if (desde < 3) {
            await m.createTable(syncMeta);
          }
          if (desde < 4) {
            await m.addColumn(notas, notas.syncError);
            await m.addColumn(adjuntos, adjuntos.syncError);
          }
        },
        beforeOpen: (detalles) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

QueryExecutor _abrirCifrada() {
  return LazyDatabase(() async {
    final directorio = await getApplicationDocumentsDirectory();
    final archivo = File(p.join(directorio.path, 'notium.db'));
    final clave =
        await ClaveCifrado(const FlutterSecureStorage()).obtenerOCrear();

    return NativeDatabase.createInBackground(
      archivo,
      setup: (db) {
        // La clave debe aplicarse ANTES de cualquier otra operación.
        db.execute('PRAGMA key = "x\'$clave\'"');

        // Verificación defensiva: si por un error de build la librería
        // enlazada no fuese SQLCipher, la BD quedaría SIN cifrar en disco.
        // Mejor fallar ruidosamente (pubspec: hooks → sqlite3 → sqlcipher).
        final version = db.select('PRAGMA cipher_version');
        if (version.isEmpty) {
          throw StateError(
            'SQLCipher no está disponible: la base de datos NO quedaría cifrada.',
          );
        }
      },
    );
  });
}
