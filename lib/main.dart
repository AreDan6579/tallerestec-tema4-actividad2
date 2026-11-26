import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalogo.dart';
import 'evidencia_pantalla.dart';
import 'notas_pantalla.dart';
import 'taller.dart';

void main() => runApp(const PracticaPrefs());

const kNombre = 'practicaprefs.nombre';
const kOscuro = 'practicaprefs.oscuro';
const kTamano = 'practicaprefs.tamano';
const kFavoritos = 'practicaprefs.favoritos';
final talleres = talleresIniciales.map((taller) => taller.nombre).toList();

class PracticaPrefs extends StatefulWidget {
  const PracticaPrefs({super.key});

  @override
  State<PracticaPrefs> createState() => _PracticaPrefsState();
}

class _PracticaPrefsState extends State<PracticaPrefs> {
  final prefs = SharedPreferencesAsync();
  final nombre = TextEditingController();
  Set<String> favoritos = {};
  bool oscuro = false;
  bool ocupado = false;
  double tamano = 16;
  String estado = '';

  @override
  void initState() {
    super.initState();
    recuperar();
  }

  @override
  void dispose() {
    nombre.dispose();
    super.dispose();
  }

  Future<void> operar(Future<void> Function() tarea, String mensaje) async {
    if (ocupado) return;
    setState(() {
      ocupado = true;
      estado = '';
    });
    try {
      await tarea();
      if (mounted) setState(() => estado = mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => estado = 'No se completó la operación. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> recuperar() => operar(() async {
    final guardado = await prefs.getString(kNombre) ?? '';
    final tema = await prefs.getBool(kOscuro) ?? false;
    final medida = await prefs.getDouble(kTamano) ?? 16.0;
    final lista = await prefs.getStringList(kFavoritos) ?? const <String>[];
    if (!mounted) return;
    setState(() {
      nombre.text = guardado;
      oscuro = tema;
      tamano = medida.isFinite ? medida.clamp(14.0, 24.0) : 16;
      favoritos = lista.toSet();
      favoritos.retainAll(talleres);
    });
  }, 'Preferencias recuperadas.');

  Future<void> guardar() async {
    final texto = nombre.text.trim();
    if (texto.isEmpty) {
      setState(() => estado = 'Escribe un nombre.');
      return;
    }
    final tema = oscuro;
    final medida = tamano;
    final lista = favoritos.toList();
    await operar(() async {
      await prefs.setString(kNombre, texto);
      await prefs.setBool(kOscuro, tema);
      await prefs.setDouble(kTamano, medida);
      await prefs.setStringList(kFavoritos, lista);
      if (!mounted) return;
      nombre.text = texto;
    }, 'Preferencias guardadas.');
  }

  Future<void> restablecer() => operar(() async {
    await prefs.clear(allowList: {kNombre, kOscuro, kTamano, kFavoritos});
    if (!mounted) return;
    setState(() {
      nombre.clear();
      oscuro = false;
      tamano = 16;
      favoritos.clear();
    });
  }, 'Preferencias restablecidas.');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF6950A5)),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF6950A5),
        brightness: Brightness.dark,
      ),
      themeMode: oscuro ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Preferencias de TalleresTEC'),
          actions: [
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Catálogo de talleres',
                  icon: const Icon(Icons.school_outlined),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: (_) => const CatalogoPantalla()),
                  ),
                ),
              ),
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Evidencia fotográfica',
                  icon: const Icon(Icons.photo_camera_outlined),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EvidenciaPantalla(),
                    ),
                  ),
                ),
              ),
            if (!kIsWeb)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Nota del taller',
                  icon: const Icon(Icons.notes),
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(builder: (_) => const NotasPantalla()),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextField(
                    controller: nombre,
                    enabled: !ocupado,
                    decoration: const InputDecoration(
                      labelText: 'Nombre visible',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Tema oscuro'),
                    value: oscuro,
                    onChanged: ocupado
                        ? null
                        : (valor) => setState(() => oscuro = valor),
                  ),
                  const SizedBox(height: 12),
                  Text('Tamaño de texto: ${tamano.toStringAsFixed(0)}'),
                  Slider(
                    min: 14,
                    max: 24,
                    divisions: 10,
                    value: tamano,
                    label: tamano.toStringAsFixed(0),
                    onChanged: ocupado
                        ? null
                        : (valor) => setState(() => tamano = valor),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Vista previa de TalleresTEC',
                        style: TextStyle(fontSize: tamano),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Talleres favoritos',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (final taller in talleres)
                    CheckboxListTile(
                      dense: true,
                      title: Text(taller),
                      value: favoritos.contains(taller),
                      onChanged: ocupado
                          ? null
                          : (marcado) => setState(() {
                              if (marcado == true) {
                                favoritos.add(taller);
                              } else {
                                favoritos.remove(taller);
                              }
                            }),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: ocupado ? null : guardar,
                        child: const Text('Guardar'),
                      ),
                      OutlinedButton(
                        onPressed: ocupado ? null : recuperar,
                        child: const Text('Recuperar'),
                      ),
                      TextButton(
                        onPressed: ocupado ? null : restablecer,
                        child: const Text('Restablecer'),
                      ),
                    ],
                  ),
                  if (ocupado) const LinearProgressIndicator(),
                  if (estado.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Semantics(liveRegion: true, child: Text(estado)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
