import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:practicaprefs/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('Restablecer borra las cuatro claves y conserva una ajena', (
    tester,
  ) async {
    final anterior = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(() => SharedPreferencesAsyncPlatform.instance = anterior);
    final prefs = SharedPreferencesAsync();
    await prefs.setString('otra.configuracion', 'conservar');
    await prefs.setString(kNombre, 'Ana');
    await prefs.setBool(kOscuro, true);
    await prefs.setDouble(kTamano, 20);
    await prefs.setStringList(kFavoritos, ['Flutter', 'Flutter', 'Python']);
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PracticaPrefs());
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 20);
    expect(
      tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .where((casilla) => casilla.value == true),
      hasLength(2),
    );
    final restablecer = find.text('Restablecer');
    await tester.ensureVisible(restablecer);
    await tester.tap(restablecer);
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(find.byType(Slider)).value, 16);
    expect(await prefs.getAll(), {'otra.configuracion': 'conservar'});
  });
}
