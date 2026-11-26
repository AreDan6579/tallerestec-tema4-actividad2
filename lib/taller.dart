class Taller {
  final int? id;
  final String nombre;
  final String descripcion;
  final String horario;
  final String lugar;
  final double costo;
  final String imagen;
  final int cupo;
  final int horas;
  final List<String> requisitos;

  const Taller(
    this.nombre,
    this.descripcion,
    this.horario,
    this.lugar,
    this.costo,
    this.imagen,
    this.cupo,
    this.horas,
    this.requisitos, {
    this.id,
  });
  Map<String, Object> aMapa() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'horario': horario,
    'lugar': lugar,
    'costo': costo,
    'imagen': imagen,
    'cupo': cupo,
    'horas': horas,
    'requisito1': requisitos[0],
    'requisito2': requisitos[1],
  };

  factory Taller.deMapa(Map<String, Object?> mapa) => Taller(
    mapa['nombre'] as String,
    mapa['descripcion'] as String,
    mapa['horario'] as String,
    mapa['lugar'] as String,
    (mapa['costo'] as num).toDouble(),
    mapa['imagen'] as String,
    mapa['cupo'] as int,
    mapa['horas'] as int,
    [mapa['requisito1'] as String, mapa['requisito2'] as String],
    id: mapa['id'] as int,
  );
}

const talleresIniciales = <Taller>[
  Taller(
    'Flutter',
    'Crea interfaces y navega entre pantallas con Flutter y Dart.',
    'Viernes 14:00 a 18:00',
    'Macrocentro',
    200,
    'taller/flutter.jpg',
    12,
    4,
    [
      'Traer una computadora con Flutter y Dart instalados.',
      'Tener conocimientos básicos de variables y funciones en Dart.',
    ],
  ),
  Taller(
    'Desarrollo de Videojuegos',
    'Construye un videojuego básico en Godot.',
    'Sábado 09:00 a 12:00',
    'Laboratorio 3',
    180,
    'taller/videojuegos.jpg',
    10,
    3,
    [
      'Traer una computadora con Godot 4 instalado.',
      'Conocer variables, condicionales y funciones de programación.',
    ],
  ),
  Taller(
    'Hackeo Ético',
    'Aprende seguridad informática en un entorno autorizado.',
    'Sábado 12:00 a 15:00',
    'Laboratorio 1',
    150,
    'taller/hackeo_etico.jpg',
    15,
    3,
    [
      'Traer una computadora con VirtualBox instalado.',
      'Realizar las prácticas solo en el laboratorio autorizado del taller.',
    ],
  ),
  Taller(
    'Python',
    'Practica los fundamentos de programación con Python.',
    'Jueves 16:00 a 18:00',
    'Laboratorio 2',
    0,
    'taller/python.jpg',
    18,
    2,
    [
      'Tener Python 3 instalado.',
      'Traer un editor de código y conocer variables y condicionales.',
    ],
  ),
  Taller(
    'Música',
    'Aprende ritmo, lectura musical básica y acordes iniciales.',
    'Miércoles 15:00 a 17:00',
    'Aula de Música',
    120,
    '',
    20,
    2,
    [
      'Traer un cuaderno y lápiz para los ejercicios.',
      'Llevar un instrumento si se cuenta con uno; no es obligatorio.',
    ],
  ),
];
