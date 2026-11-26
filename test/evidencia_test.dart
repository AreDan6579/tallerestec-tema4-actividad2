import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:practicaprefs/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class SelectorDePrueba extends ImagePickerPlatform {
  ImageSource? fuente;
  XFile? archivo;
  PlatformException? error;
  LostDataResponse pendiente = LostDataResponse.empty();

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    fuente = source;
    final fallo = error;
    if (fallo != null) throw fallo;
    return archivo;
  }

  @override
  Future<LostDataResponse> getLostData() async => pendiente;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fuenteRoboto = Platform.environment['CAMARA_FUENTE'];
  final carpetaCapturas = Platform.environment['CAMARA_CAPTURAS'];

  if (fuenteRoboto != null) {
    setUpAll(() async {
      final roboto = File(fuenteRoboto);
      final iconos = File('${roboto.parent.path}/MaterialIcons-Regular.otf');
      for (final (familia, archivo) in [
        ('Roboto', roboto),
        ('MaterialIcons', iconos),
      ]) {
        final fuente = ByteData.sublistView(archivo.readAsBytesSync());
        await (FontLoader(familia)..addFont(Future.value(fuente))).load();
      }
    });
  }

  testWidgets('Portada, selección, cancelación, permisos y quitar imagen', (
    tester,
  ) async {
    final anterior = ImagePickerPlatform.instance;
    final preferencias = SharedPreferencesAsyncPlatform.instance;
    final selector = SelectorDePrueba();
    ImagePickerPlatform.instance = selector;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() {
      ImagePickerPlatform.instance = anterior;
      SharedPreferencesAsyncPlatform.instance = preferencias;
    });

    const pantalla = Size(414, 650);
    final capturaKey = GlobalKey();
    await tester.binding.setSurfaceSize(pantalla);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pulsar(Finder boton) async {
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }

    Future<void> captura(String nombre) async {
      if (carpetaCapturas == null) return;
      final contexto = capturaKey.currentContext!;
      for (final imagen in tester.widgetList<Image>(find.byType(Image))) {
        await tester.runAsync(() => precacheImage(imagen.image, contexto));
      }
      await tester.pumpAndSettle();
      final pantalla = contexto.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final imagen = await pantalla.toImage(pixelRatio: 2);
        try {
          final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
          await File('$carpetaCapturas/$nombre.png')
              .writeAsBytes(datos!.buffer.asUint8List());
        } finally {
          imagen.dispose();
        }
      });
    }

    await tester.pumpWidget(
      RepaintBoundary(key: capturaKey, child: const PracticaPrefs()),
    );
    await tester.pumpAndSettle();

    final abrir = find.byTooltip('Evidencia fotográfica');
    await pulsar(abrir);
    expect(find.text('Origen: Imagen incluida'), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
    await captura('01_imagen_incluida');

    await tester.runAsync(() async {
      final contexto = capturaKey.currentContext!;
      await precacheImage(FileImage(File('test/fotos/taza.png')), contexto);
      await precacheImage(FileImage(File('test/fotos/monedas.png')), contexto);
    });

    selector.archivo = XFile('test/fotos/taza.png');
    await pulsar(find.text('Tomar foto'));
    expect(selector.fuente, ImageSource.camera);
    expect(find.text('Origen: Cámara'), findsOneWidget);
    expect(find.text('Archivo: taza.png'), findsOneWidget);
    expect(
      (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
      'test/fotos/taza.png',
    );
    await captura('02_camara');

    selector.archivo = XFile('test/fotos/monedas.png');
    await pulsar(find.text('Elegir imagen'));
    expect(selector.fuente, ImageSource.gallery);
    expect(find.text('Origen: Galería'), findsOneWidget);
    expect(find.text('Archivo: monedas.png'), findsOneWidget);
    expect(
      (tester.widget<Image>(find.byType(Image)).image as FileImage).file.path,
      'test/fotos/monedas.png',
    );
    await captura('03_galeria');

    selector.archivo = null;
    await pulsar(find.text('Elegir imagen'));
    expect(find.text('Operación cancelada.'), findsOneWidget);
    expect(find.text('Origen: Galería'), findsOneWidget);
    expect(find.text('Archivo: monedas.png'), findsOneWidget);

    selector.error = PlatformException(code: 'camera_access_denied');
    await pulsar(find.text('Tomar foto'));
    expect(
      find.text('Acceso denegado. Revisa los permisos en Ajustes.'),
      findsOneWidget,
    );
    expect(find.text('Archivo: monedas.png'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await pulsar(find.text('Quitar imagen'));
    expect(find.text('Origen: Imagen incluida'), findsOneWidget);
    expect(find.text('Archivo: monedas.png'), findsNothing);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<AssetImage>());
    expect(File('test/fotos/monedas.png').existsSync(), isTrue);

    await pulsar(find.byType(BackButton));
    expect(find.text('Preferencias de TalleresTEC'), findsOneWidget);

    selector.pendiente = LostDataResponse(
      files: [XFile('test/fotos/taza.png')],
    );
    await pulsar(abrir);
    expect(find.text('Origen: Imagen recuperada'), findsOneWidget);
    expect(find.text('Archivo: taza.png'), findsOneWidget);
  }, variant: const TargetPlatformVariant({TargetPlatform.android}));
}
