import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'taller.dart';

class TallerDb {
  TallerDb({this.archivo});

  final String? archivo;

  Future<Database> abrir() async {
    return openDatabase(
      archivo ?? path.join(await getDatabasesPath(), 'talleres_tec.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE talleres (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL CHECK(length(trim(nombre)) > 0),
  descripcion TEXT NOT NULL,
  horario TEXT NOT NULL,
  lugar TEXT NOT NULL,
  costo REAL NOT NULL CHECK(costo >= 0),
  imagen TEXT NOT NULL,
  cupo INTEGER NOT NULL CHECK(cupo > 0),
  horas INTEGER NOT NULL CHECK(horas > 0),
  requisito1 TEXT NOT NULL,
  requisito2 TEXT NOT NULL
)
''');
        for (final taller in talleresIniciales) {
          await db.insert('talleres', taller.aMapa());
        }
      },
    );
  }

  Future<List<Taller>> listar([String texto = '']) async {
    final db = await abrir();
    final buscar = texto.trim();
    final filas = await db.query(
      'talleres',
      where: buscar.isEmpty ? null : 'nombre LIKE ?',
      whereArgs: buscar.isEmpty ? null : ['%$buscar%'],
      orderBy: 'id',
    );
    return filas.map(Taller.deMapa).toList();
  }

  Future<int> guardar(Taller taller) async {
    final db = await abrir();
    final id = taller.id;
    if (id == null) return db.insert('talleres', taller.aMapa());
    final filas = await db.update(
      'talleres',
      taller.aMapa(),
      where: 'id = ?',
      whereArgs: [id],
    );
    if (filas != 1) throw StateError('El taller ya no existe.');
    return id;
  }

  Future<void> eliminar(int id) async {
    final db = await abrir();
    await db.delete('talleres', where: 'id = ?', whereArgs: [id]);
  }
}
