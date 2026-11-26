import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practicaprefs/notas_archivo.dart';
import 'package:practicaprefs/notas_pantalla.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fuente = Platform.environment['PREFS_EVIDENCE_FONT'];
  if (fuente != null) {
    setUpAll(() async {
      final loader = FontLoader('Roboto');
      loader.addFont(
        Future.value(ByteData.sublistView(File(fuente).readAsBytesSync())),
      );
      await loader.load();
    });
  }
  testWidgets('Casos de la etapa 7, tres líneas y confirmación', (
    tester,
  ) async {
    final carpeta = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('talleres_nota_'),
    ))!;
    addTearDown(() => carpeta.delete(recursive: true));
    final archivo = NotasArchivo(directorio: carpeta);
    await tester.binding.setSurfaceSize(const Size(460, 570));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> ver(String mensaje) async {
      final objetivo = find.text(mensaje);
      for (int i = 0; i < 100 && objetivo.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump(const Duration(milliseconds: 25));
      }
      expect(objetivo, findsOneWidget);
      await tester.pumpAndSettle();
    }

    Future<void> abrir(String estado) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(home: NotasPantalla(archivo: archivo)),
      );
      await ver(estado);
    }

    Finder campo(int indice) => find.byType(TextField).at(indice);
    String nota() => tester.widget<TextField>(campo(0)).controller!.text;
    Future<void> captura(String nombre) async {
      if (fuente != null) {
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('evidencias/$nombre.png'),
        );
      }
    }

    Future<void> tocar(String nombre) async {
      await tester.tap(find.text(nombre).last);
      await tester.pump();
    }

    await abrir('Sin nota guardada.');
    expect(nota(), isEmpty);
    await tester.enterText(campo(0), '   ');
    await tocar('Guardar');
    await ver('Escribe una nota.');
    expect(await tester.runAsync(archivo.leer), isNull);

    await tester.enterText(campo(0), 'Llevar la laptop.');
    await tocar('Guardar');
    await ver('Nota guardada.');
    await captura('01_guardado');
    await tester.enterText(campo(0), 'Cambio sin guardar.');
    await tocar('Recuperar');
    await ver('Nota recuperada.');
    expect(nota(), 'Llevar la laptop.');

    await tester.enterText(campo(0), 'Llevar el cargador.');
    await tocar('Guardar');
    await ver('Nota guardada.');
    await abrir('Nota recuperada.');
    expect(nota(), 'Llevar el cargador.');
    await captura('02_reapertura');

    await tocar('Eliminar');
    await tester.pumpAndSettle();
    await tocar('Cancelar');
    await tester.pumpAndSettle();
    expect(await tester.runAsync(archivo.leer), 'Llevar el cargador.');
    await tocar('Eliminar');
    await tester.pumpAndSettle();
    await captura('04_confirmacion');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      ),
    );
    await ver('Nota eliminada.');
    expect(nota(), isEmpty);
    await captura('03_eliminada');
    expect(await tester.runAsync(archivo.leer), isNull);
    await abrir('Sin nota guardada.');

    await tester.enterText(campo(0), 'Llevar la laptop.');
    await tocar('Guardar');
    await ver('Nota guardada.');
    for (final nueva in ['Llevar el cargador.', 'Llevar la libreta.']) {
      await tester.enterText(campo(1), nueva);
      await tocar('Agregar línea');
      await ver('Línea agregada.');
      expect(nota(), endsWith(nueva));
    }
    await tocar('Recuperar');
    await ver('Nota recuperada.');
    expect(nota().split('\n'), [
      'Llevar la laptop.',
      'Llevar el cargador.',
      'Llevar la libreta.',
    ]);
    await captura('05_tres_lineas');
  });
}
