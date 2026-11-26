import 'package:flutter/material.dart';

import 'notas_archivo.dart';

class NotasPantalla extends StatefulWidget {
  const NotasPantalla({super.key, this.archivo = const NotasArchivo()});
  final NotasArchivo archivo;

  @override
  State<NotasPantalla> createState() => _NotasPantallaState();
}

class _NotasPantallaState extends State<NotasPantalla> {
  final nota = TextEditingController();
  final linea = TextEditingController();
  bool ocupado = false;
  String estado = '';

  @override
  void initState() {
    super.initState();
    recuperar();
  }

  @override
  void dispose() {
    nota.dispose();
    linea.dispose();
    super.dispose();
  }

  Future<void> operar(Future<String> Function() tarea) async {
    if (ocupado) return;
    setState(() {
      ocupado = true;
      estado = '';
    });
    try {
      final mensaje = await tarea();
      if (mounted) setState(() => estado = mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => estado = 'No se pudo acceder a la nota. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> recuperar() => operar(() async {
    final contenido = await widget.archivo.leer();
    if (mounted) nota.text = contenido ?? '';
    return contenido == null ? 'Sin nota guardada.' : 'Nota recuperada.';
  });

  Future<void> guardar() async {
    final texto = nota.text;
    if (texto.trim().isEmpty) {
      setState(() => estado = 'Escribe una nota.');
      return;
    }
    await operar(() async {
      await widget.archivo.guardar(texto);
      return 'Nota guardada.';
    });
  }

  Future<void> agregar() async {
    final texto = linea.text.trim();
    if (texto.isEmpty) {
      setState(() => estado = 'Escribe una línea para agregar.');
      return;
    }
    await operar(() async {
      final contenido = await widget.archivo.agregarLinea(texto);
      if (mounted) {
        nota.text = contenido;
        linea.clear();
      }
      return 'Línea agregada.';
    });
  }

  Future<void> confirmarEliminacion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Quieres eliminar el archivo nota.txt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogo, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true) return;
    await operar(() async {
      final eliminado = await widget.archivo.eliminar();
      if (mounted) {
        nota.clear();
        linea.clear();
      }
      return eliminado ? 'Nota eliminada.' : 'Sin nota guardada.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nota del taller')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextField(
                  controller: nota,
                  enabled: !ocupado,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Nota',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
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
                      onPressed: ocupado ? null : confirmarEliminacion,
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: linea,
                  enabled: !ocupado,
                  decoration: const InputDecoration(
                    labelText: 'Línea nueva',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: ocupado ? null : agregar,
                    child: const Text('Agregar línea'),
                  ),
                ),
                const SizedBox(height: 16),
                if (ocupado) const LinearProgressIndicator(),
                Semantics(liveRegion: true, child: Text(estado)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
