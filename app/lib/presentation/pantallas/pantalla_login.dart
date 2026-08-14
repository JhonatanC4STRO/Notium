import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/red/auth_api.dart';
import '../providers.dart';
import 'pantalla_registro.dart';

/// Login con red (CU-02). El camino sin red no pasa por aquí: si hay sesión
/// cacheada válida/degradada, la raíz de la app va directo a las notas.
class PantallaLogin extends ConsumerStatefulWidget {
  const PantallaLogin({super.key});

  @override
  ConsumerState<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends ConsumerState<PantallaLogin> {
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _email.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final email = _email.text.trim();
    if (email.isEmpty || _contrasena.text.isEmpty) {
      _avisar('Escribe tu email y contraseña.');
      return;
    }

    setState(() => _enviando = true);
    try {
      await ref
          .read(sesionProvider.notifier)
          .login(email: email, contrasena: _contrasena.text);
      // La raíz reacciona al cambio de sesión y muestra las notas.
    } on ApiException catch (e) {
      _avisar(e.codigo == 'CREDENCIALES_INVALIDAS'
          ? 'Email o contraseña incorrectos.'
          : e.mensaje);
    } on SinConexionException {
      _avisar('Sin conexión: el primer inicio de sesión necesita red.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Notium',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contrasena,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onSubmitted: (_) => _entrar(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _enviando ? null : _entrar,
                  child: _enviando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Iniciar sesión'),
                ),
                TextButton(
                  onPressed: _enviando
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PantallaRegistro(),
                            ),
                          ),
                  child: const Text('Crear una cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
