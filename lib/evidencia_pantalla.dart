import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class EvidenciaPantalla extends StatefulWidget {
  const EvidenciaPantalla({super.key});

  @override
  State<EvidenciaPantalla> createState() => _EvidenciaPantallaState();
}

class _EvidenciaPantallaState extends State<EvidenciaPantalla> {
  final selector = ImagePicker();
  XFile? imagen;
  String origen = 'Imagen incluida';
  bool ocupado = false;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android) recuperarImagen();
  }

  Future<void> recuperarImagen() async {
    setState(() => ocupado = true);
    try {
      final resultado = await selector.retrieveLostData();
      if (!mounted || resultado.isEmpty) return;
      final archivos = resultado.files;
      if (archivos != null && archivos.isNotEmpty) {
        mostrarImagen(archivos.first, 'Imagen recuperada');
      } else if (resultado.exception != null) {
        avisar('No se pudo recuperar la imagen.');
      }
    } on PlatformException {
      if (mounted) avisar('No se pudo recuperar la imagen.');
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> elegirImagen(ImageSource fuente) async {
    if (ocupado) return;
    setState(() => ocupado = true);
    try {
      final archivo = await selector.pickImage(
        source: fuente,
        maxWidth: 1280,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (!mounted) return;
      if (archivo == null) {
        avisar('Operación cancelada.');
        return;
      }
      mostrarImagen(
        archivo,
        fuente == ImageSource.camera ? 'Cámara' : 'Galería',
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      final mensaje = switch (error.code) {
        'camera_access_denied' || 'photo_access_denied' =>
          'Acceso denegado. Revisa los permisos en Ajustes.',
        'camera_access_restricted' || 'photo_access_restricted' =>
          'El dispositivo restringe el acceso a este recurso.',
        'no_available_camera' => 'No hay una cámara disponible.',
        _ => 'No se pudo obtener la imagen.',
      };
      avisar(mensaje);
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  void mostrarImagen(XFile? archivo, String fuente) {
    setState(() {
      imagen = archivo;
      origen = fuente;
    });
  }

  void avisar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final archivo = imagen;
    return Scaffold(
      appBar: AppBar(title: const Text('Evidencia fotográfica')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'TalleresTEC',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ColoredBox(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: archivo == null
                          ? Image.asset(
                              'assets/portada_taller.png',
                              fit: BoxFit.contain,
                              semanticLabel: 'Portada de TalleresTEC',
                            )
                          : Image.file(
                              File(archivo.path),
                              key: ValueKey(archivo.path),
                              fit: BoxFit.contain,
                              semanticLabel: 'Foto del taller',
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Text('Imagen no disponible'),
                                  ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(liveRegion: true, child: Text('Origen: $origen')),
                if (archivo != null)
                  Text(
                    'Archivo: ${archivo.name}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (ocupado) const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: ocupado
                          ? null
                          : () => elegirImagen(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Tomar foto'),
                    ),
                    OutlinedButton.icon(
                      onPressed: ocupado
                          ? null
                          : () => elegirImagen(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Elegir imagen'),
                    ),
                    TextButton(
                      onPressed: ocupado || archivo == null
                          ? null
                          : () => mostrarImagen(null, 'Imagen incluida'),
                      child: const Text('Quitar imagen'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
