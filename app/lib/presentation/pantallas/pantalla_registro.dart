import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/red/auth_api.dart';
import '../providers.dart';

/// Registro de cuenta (CU-01). Requiere red: no existe registro offline.
class PantallaRegistro extends ConsumerStatefulWidget {
  const PantallaRegistro({super.key});

  @override
  ConsumerState<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends ConsumerState<PantallaRegistro> {
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final nombre = _nombre.text.trim();
    final email = _email.text.trim();
    if (nombre.isEmpty || email.isEmpty) {
      _avisar('El nombre y el email son obligatorios.');
      return;
    }
    if (_contrasena.text.length < 8) {
      _avisar('La contraseña debe tener al menos 8 caracteres.');
      return;
    }

    setState(() => _enviando = true);
    try {
      await ref.read(sesionProvider.notifier).registrar(
            nombre: nombre,
            email: email,
            contrasena: _contrasena.text,
          );
      // Sesión iniciada: la raíz muestra las notas; se saca esta pantalla
      // de la pila para no volver al formulario con "atrás".
      if (mounted) Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on ApiException catch (e) {
      _avisar(e.codigo == 'EMAIL_DUPLICADO'
          ? 'Ese email ya está registrado.'
          : e.mensaje);
    } on SinConexionException {
      _avisar('Sin conexión: crear la cuenta necesita red.');
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
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _contrasena,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña (mínimo 8 caracteres)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  onSubmitted: (_) => _registrar(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _enviando ? null : _registrar,
                  child: _enviando
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Registrarme'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
