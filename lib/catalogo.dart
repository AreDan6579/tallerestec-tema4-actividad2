import 'package:flutter/material.dart';

import 'administrar_talleres.dart';
import 'taller.dart';
import 'taller_db.dart';

class CatalogoPantalla extends StatefulWidget {
  const CatalogoPantalla({super.key});

  @override
  State<CatalogoPantalla> createState() => _CatalogoPantallaState();
}

class _CatalogoPantallaState extends State<CatalogoPantalla> {
  final controlador = PageController(viewportFraction: 0.88, keepPage: false);
  int actual = 0;
  final db = TallerDb();
  late Future<List<Taller>> consulta = db.listar();

  Future<void> administrar() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AdministrarTalleres(db: db)),
    );
    if (!mounted) return;
    setState(() {
      actual = 0;
      consulta = db.listar();
    });
  }

  @override
  void dispose() {
    controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TalleresTEC'),
        actions: [
          IconButton(
            onPressed: administrar,
            tooltip: 'Administrar talleres',
            icon: const Icon(Icons.edit_note),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(title: Text('TalleresTEC')),
              ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('Catálogo de talleres'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<List<Taller>>(
        future: consulta,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (estado.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => consulta = db.listar()),
                child: const Text('No se pudo cargar. Reintentar'),
              ),
            );
          }
          final talleres = estado.data!;
          if (talleres.isEmpty) {
            return Center(
              child: TextButton(
                onPressed: administrar,
                child: const Text(
                  'El catálogo está vacío. Administrar talleres',
                ),
              ),
            );
          }
          return catalogo(talleres);
        },
      ),
    );
  }

  Widget catalogo(List<Taller> talleres) {
    actual = actual.clamp(0, talleres.length - 1);
    final taller = talleres[actual];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFFCF6FF),
              child: Text(
                taller.nombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,

            child: PageView.builder(
              controller: controlador,
              itemCount: talleres.length,
              onPageChanged: (index) {
                setState(() => actual = index);
              },
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: FotoTaller(taller: talleres[index]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${actual + 1} de ${talleres.length} · Desliza para cambiar',
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: DatosTaller(taller: taller),
          ),
          Center(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => DetallePantalla(taller: taller),
                  ),
                );
              },
              icon: const Icon(Icons.stars),
              label: const Text('Ver más'),
            ),
          ),
        ],
      ),
    );
  }
}

class FotoTaller extends StatelessWidget {
  final Taller taller;

  const FotoTaller({super.key, required this.taller});

  @override
  Widget build(BuildContext context) {
    if (taller.imagen.isEmpty) {
      return Container(
        color: const Color(0xFFFCF6FF),
        alignment: Alignment.center,
        child: const Icon(
          Icons.music_note,
          size: 100,
          color: Color(0xFF6950A5),
        ),
      );
    }

    return Image.asset(
      taller.imagen,
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }
}

class DatosTaller extends StatelessWidget {
  final Taller taller;
  final bool completo;

  const DatosTaller({super.key, required this.taller, this.completo = false});

  Widget dato(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icono, color: const Color(0xFF6950A5)),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final precio = taller.costo == 0
        ? 'Gratuito'
        : '\$${taller.costo.toStringAsFixed(2)} MXN';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF6FF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          dato(Icons.calendar_today_outlined, taller.horario),
          dato(Icons.location_on_outlined, 'Ubicación: ${taller.lugar}'),
          dato(Icons.attach_money, 'Costo de admisión: $precio'),
          if (completo) ...[
            dato(
              Icons.view_list_outlined,
              'Cupo total: ${taller.cupo} lugares',
            ),
            dato(Icons.schedule, 'Horas totales: ${taller.horas}'),
          ],
        ],
      ),
    );
  }
}

class DetallePantalla extends StatelessWidget {
  final Taller taller;

  const DetallePantalla({super.key, required this.taller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(taller.nombre)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              taller.nombre,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 220, child: FotoTaller(taller: taller)),
            const SizedBox(height: 16),
            Text(taller.descripcion),
            const SizedBox(height: 16),
            DatosTaller(taller: taller, completo: true),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final bool? resultado = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute<bool>(
                    builder: (context) => ConfirmacionPantalla(taller: taller),
                  ),
                );

                if (!context.mounted) return;

                if (resultado == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Interés confirmado en ${taller.nombre}.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.stars),
              label: const Text('Confirmar interés'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => RequisitosPantalla(taller: taller),
                  ),
                );
              },
              child: const Text('Requisitos del taller'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Disponibilidad'),
                    content: Text('Cupo total: ${taller.cupo} lugares.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Consultar disponibilidad'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop<void>(context),
              child: const Text('Volver al catálogo'),
            ),
          ],
        ),
      ),
    );
  }
}

class RequisitosPantalla extends StatelessWidget {
  final Taller taller;

  const RequisitosPantalla({super.key, required this.taller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requisitos del taller')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              taller.nombre,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Text('1.'),
              title: Text(taller.requisitos[0]),
            ),
            ListTile(
              leading: const Text('2.'),
              title: Text(taller.requisitos[1]),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop<void>(context),
              child: const Text('Volver al detalle'),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmacionPantalla extends StatelessWidget {
  final Taller taller;

  const ConfirmacionPantalla({super.key, required this.taller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar interés')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              taller.nombre,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(height: 220, child: FotoTaller(taller: taller)),
            const SizedBox(height: 16),
            DatosTaller(taller: taller),
            const SizedBox(height: 20),
            const Text(
              '¿Confirmas tu interés?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.pop<bool>(context, true),
                  icon: const Icon(Icons.stars),
                  label: const Text('Sí'),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop<bool>(context, false),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
