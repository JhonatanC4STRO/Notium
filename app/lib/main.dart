import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'data/sync/sync_background.dart';
import 'presentation/app.dart';
import 'presentation/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Motor de tareas en segundo plano (tarea 3.4): registra el callback del
  // isolate de workmanager. Las tareas concretas se registran al iniciar sesión.
  await inicializarWorkmanager();

  // Almacén de copias de adjuntos y archivo de la BD, dentro del sandbox de
  // la app (el archivo se usa para medir el uso de disco, RNF-05).
  final documentos = await getApplicationDocumentsDirectory();
  final adjuntos = Directory(p.join(documentos.path, 'adjuntos'));
  final archivoDb = File(p.join(documentos.path, 'notium.db'));

  // ProviderScope habilita Riverpod en todo el árbol (ADR-01): la UI solo
  // consume la BD local a través de providers (Single Source of Truth, 3.1).
  runApp(
    ProviderScope(
      overrides: [
        directorioAdjuntosProvider.overrideWithValue(adjuntos),
        archivoBaseDatosProvider.overrideWithValue(archivoDb),
      ],
      child: const NotiumApp(),
    ),
  );
}
