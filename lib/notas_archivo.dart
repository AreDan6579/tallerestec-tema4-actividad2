import 'dart:io';

import 'package:path_provider/path_provider.dart';

class NotasArchivo {
  const NotasArchivo({this.directorio});
  final Directory? directorio;

  Future<File> _obtenerArchivo() async {
    final base = directorio ?? await getApplicationDocumentsDirectory();
    final separador = Platform.pathSeparator;
    return File('${base.path}${separador}TalleresTEC${separador}nota.txt');
  }

  Future<String?> leer() async {
    final archivo = await _obtenerArchivo();
    return await archivo.exists() ? archivo.readAsString() : null;
  }

  Future<void> guardar(String texto) async {
    final archivo = await _obtenerArchivo();
    await archivo.parent.create(recursive: true);
    await archivo.writeAsString(texto, flush: true);
  }

  Future<String> agregarLinea(String linea) async {
    if (linea.trim().isEmpty || linea.contains('\n') || linea.contains('\r')) {
      throw ArgumentError('Se requiere una sola línea.');
    }
    final archivo = await _obtenerArchivo();
    await archivo.parent.create(recursive: true);
    final anterior = await archivo.exists() ? await archivo.readAsString() : '';
    final separador = anterior.isEmpty || anterior.endsWith('\n') ? '' : '\n';
    await archivo.writeAsString(
      '$separador$linea',
      mode: FileMode.append,
      flush: true,
    );
    return '$anterior$separador$linea';
  }

  Future<bool> eliminar() async {
    final archivo = await _obtenerArchivo();
    if (!await archivo.exists()) return false;
    await archivo.delete();
    return true;
  }
}
