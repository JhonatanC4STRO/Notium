import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notium/data/auth/almacen_seguro.dart';
import 'package:notium/data/auth/almacen_sesion.dart';
import 'package:notium/data/db/app_database.dart';
import 'package:notium/domain/sesion.dart';
import 'package:notium/presentation/app.dart';
import 'package:notium/presentation/pantallas/pantalla_login.dart';
import 'package:notium/presentation/providers.dart';

/// Widget tests de la UI (tareas 2.4 y 3.1) con BD en memoria, directorio
/// temporal y almacén de sesión en memoria: sin emulador ni red.
void main() {
  late AppDatabase db;
  late Directory temporal;
  late AlmacenSeguroEnMemoria almacenSeguro;

  // Cada test crea su propia BD en memoria; el warning de instancias
  // múltiples de drift no aplica (nunca comparten executor).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUp(() async {
    db = AppDatabase.paraTests(NativeDatabase.memory());
    temporal = await Directory.systemTemp.createTemp('notium_ui_');
    almacenSeguro = AlmacenSeguroEnMemoria();
  });

  tearDown(() async {
    await db.close();
    await temporal.delete(recursive: true);
  });

  /// Deja una sesión válida cacheada (como tras un login exitoso): la raíz
  /// va directo a las notas — el mismo camino del login offline de CU-02.
  Future<void> sembrarSesion() {
    return AlmacenSesion(almacenSeguro).guardarSesion(Sesion(
      usuario: const UsuarioSesion(
        uuid: 'b1a2c3d4-0000-4000-8000-000000000001',
        nombre: 'Usuario Test',
        email: 'test@notium.co',
      ),
      accessToken: 'access-falso',
      refreshToken: 'refresh-falso',
      expiraEn: DateTime.now().toUtc().add(const Duration(hours: 1)),
    ));
  }

  Widget appDePrueba() => ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          directorioAdjuntosProvider.overrideWithValue(temporal),
          archivoBaseDatosProvider
              .overrideWithValue(File('${temporal.path}/notium.db')),
          almacenSeguroProvider.overrideWithValue(almacenSeguro),
          // Sin orquestación en segundo plano: no hay plugins de plataforma.
          syncEnSegundoPlanoProvider.overrideWithValue(false),
        ],
        child: const NotiumApp(),
      );

  /// Desmonta el árbol DENTRO del cuerpo del test y drena el timer de cierre
  /// que agendan los streams de drift al cancelarse; sin esto, el framework
  /// encuentra un timer pendiente al verificar invariantes y falla el test.
  Future<void> desmontar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    // pump SIN duración no avanza el reloj fake y el timer nunca dispararía.
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('la lista vacía invita a crear la primera nota', (tester) async {
    await sembrarSesion();
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    expect(find.textContaining('Sin notas todavía'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('crear una nota desde el editor la muestra en la lista con su indicador PENDING (RF-04)',
      (tester) async {
    await sembrarSesion();
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Acta de reunión');
    await tester.enterText(find.widgetWithText(TextField, 'Contenido'), 'Puntos tratados...');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // De vuelta en la lista: la nota está y su estado es visible (RF-04).
    expect(find.text('Acta de reunión'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget); // PENDING
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: find.byIcon(Icons.schedule), matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, 'Pendiente de sincronizar');
    await desmontar(tester);
  });

  testWidgets('el título es obligatorio para guardar', (tester) async {
    await sembrarSesion();
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('El título es obligatorio.'), findsOneWidget); // SnackBar
    expect(find.text('Nueva nota'), findsOneWidget); // seguimos en el editor
    await desmontar(tester);
  });

  testWidgets('editar desde la lista actualiza el título', (tester) async {
    await sembrarSesion();
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    // Crea una nota primero.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'v1');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // La abre y la edita.
    await tester.tap(find.text('v1'));
    await tester.pumpAndSettle();
    expect(find.text('Editar nota'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'v2');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('v2'), findsOneWidget);
    expect(find.text('v1'), findsNothing);
    await desmontar(tester);
  });

  testWidgets('eliminar pide confirmación y respeta Cancelar', (tester) async {
    await sembrarSesion();
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Persistente');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Cancelar no elimina.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar nota?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Persistente'), findsOneWidget);

    // Confirmar sí elimina (soft delete: desaparece de la vista).
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Persistente'), findsNothing);
    expect(find.textContaining('Sin notas todavía'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('RNF-03: el cambio es visible en el siguiente frame tras guardar', (tester) async {
    await sembrarSesion();
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título'), 'Instantánea');

    final cronometro = Stopwatch()..start();
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    cronometro.stop();

    expect(find.text('Instantánea'), findsOneWidget);
    // En el reloj real del test host; en dispositivo se verifica manualmente.
    expect(cronometro.elapsedMilliseconds, lessThan(1000));
    await desmontar(tester);
  });

  testWidgets('sin sesión cacheada, la app arranca en el login (3.1)', (tester) async {
    // Almacén vacío: primer arranque o sesión expirada más allá de la ventana.
    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    expect(find.byType(PantallaLogin), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    await desmontar(tester);
  });

  testWidgets('con sesión degradada, entra offline y muestra el aviso (CU-02 sin red)',
      (tester) async {
    // Access token expirado hace 2 días: dentro de la ventana extendida.
    await AlmacenSesion(almacenSeguro).guardarSesion(Sesion(
      usuario: const UsuarioSesion(
        uuid: 'b1a2c3d4-0000-4000-8000-000000000001',
        nombre: 'Usuario Test',
        email: 'test@notium.co',
      ),
      accessToken: 'access-expirado',
      refreshToken: 'refresh-falso',
      expiraEn: DateTime.now().toUtc().subtract(const Duration(days: 2)),
    ));

    await tester.pumpWidget(appDePrueba());
    await tester.pumpAndSettle();

    // Nada de login: uso offline permitido con aviso de renovación.
    expect(find.byType(PantallaLogin), findsNothing);
    expect(find.textContaining('Sesión por renovar'), findsOneWidget);
    expect(find.textContaining('Sin notas todavía'), findsOneWidget);
    await desmontar(tester);
  });
}
