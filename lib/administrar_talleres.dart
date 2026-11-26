import 'package:flutter/material.dart';

import 'taller.dart';
import 'taller_db.dart';

class AdministrarTalleres extends StatefulWidget {
  const AdministrarTalleres({super.key, required this.db});
  final TallerDb db;

  @override
  State<AdministrarTalleres> createState() => _AdministrarTalleresState();
}

class _AdministrarTalleresState extends State<AdministrarTalleres> {
  final busqueda = TextEditingController();
  String filtro = '';
  late Future<List<Taller>> consulta = widget.db.listar();
  bool ocupado = false;

  @override
  void dispose() {
    busqueda.dispose();
    super.dispose();
  }

  void consultar(String texto) {
    setState(() {
      filtro = texto;
      consulta = widget.db.listar(texto);
    });
  }

  Future<void> editar([Taller? taller]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioTaller(db: widget.db, taller: taller),
      ),
    );
    if (!mounted) return;
    consultar(filtro);
  }

  Future<void> borrar(Taller taller) async {
    setState(() => ocupado = true);
    try {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (dialogo) => AlertDialog(
          title: const Text('Eliminar taller'),
          content: Text('¿Eliminar ${taller.nombre}?'),
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
      if (!mounted || confirmado != true) return;
      await widget.db.eliminar(taller.id!);
      if (!mounted) return;
      consultar(filtro);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el taller.')),
        );
      }
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar talleres')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ocupado ? null : () => editar(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo taller'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: busqueda,
              decoration: const InputDecoration(labelText: 'Buscar por nombre'),
              onSubmitted: consultar,
            ),
          ),
          Wrap(
            children: [
              FilledButton(
                onPressed: () => consultar(busqueda.text),
                child: const Text('Buscar'),
              ),
              TextButton(
                onPressed: () {
                  busqueda.clear();
                  consultar('');
                },
                child: const Text('Mostrar todos'),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<Taller>>(
              future: consulta,
              builder: (context, estado) {
                if (estado.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (estado.hasError) {
                  return Center(
                    child: TextButton(
                      onPressed: () => consultar(filtro),
                      child: const Text('No se pudo cargar. Reintentar'),
                    ),
                  );
                }
                final talleres = estado.data!;
                if (talleres.isEmpty) {
                  return Center(
                    child: Text(
                      filtro.trim().isEmpty
                          ? 'El catálogo está vacío.'
                          : 'No hay coincidencias.',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: talleres.length,
                  itemBuilder: (context, i) {
                    final taller = talleres[i];
                    return Card(
                      child: ListTile(
                        title: Text(taller.nombre),
                        subtitle: Text(
                          'ID ${taller.id} · Cupo ${taller.cupo} · ${taller.lugar}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              onPressed: ocupado ? null : () => editar(taller),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              onPressed: ocupado ? null : () => borrar(taller),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FormularioTaller extends StatefulWidget {
  const FormularioTaller({super.key, required this.db, this.taller});
  final TallerDb db;
  final Taller? taller;

  @override
  State<FormularioTaller> createState() => _FormularioTallerState();
}

class _FormularioTallerState extends State<FormularioTaller> {
  final formulario = GlobalKey<FormState>();
  bool guardando = false;
  late final campos = <String, TextEditingController>{
    'Nombre': TextEditingController(text: widget.taller?.nombre),
    'Descripción': TextEditingController(text: widget.taller?.descripcion),
    'Horario': TextEditingController(text: widget.taller?.horario),
    'Lugar': TextEditingController(text: widget.taller?.lugar),
    'Costo en MXN': TextEditingController(
      text: widget.taller?.costo.toString() ?? '0',
    ),
    'Cupo': TextEditingController(text: widget.taller?.cupo.toString()),
    'Horas': TextEditingController(text: widget.taller?.horas.toString()),
    'Requisito 1': TextEditingController(text: widget.taller?.requisitos[0]),
    'Requisito 2': TextEditingController(text: widget.taller?.requisitos[1]),
  };

  @override
  void dispose() {
    for (final campo in campos.values) {
      campo.dispose();
    }
    super.dispose();
  }

  String valor(String campo) => campos[campo]!.text.trim();

  TextInputType teclado(String campo) {
    if (campo == 'Cupo' || campo == 'Horas') return TextInputType.number;
    if (campo == 'Costo en MXN') {
      return const TextInputType.numberWithOptions(decimal: true);
    }
    return TextInputType.text;
  }

  String? validar(String campo) {
    final texto = valor(campo);
    if (texto.isEmpty) return 'Completa este campo.';
    if (campo == 'Cupo' || campo == 'Horas') {
      if ((int.tryParse(texto) ?? 0) <= 0) return 'Escribe un entero positivo.';
    }
    if (campo == 'Costo en MXN') {
      final costo = double.tryParse(texto.replaceAll(',', '.'));
      if (costo == null || !costo.isFinite || costo < 0) {
        return 'Escribe un costo válido, mayor o igual a cero.';
      }
    }
    return null;
  }

  Future<void> guardar() async {
    if (guardando || !formulario.currentState!.validate()) return;
    setState(() => guardando = true);
    try {
      await widget.db.guardar(
        Taller(
          valor('Nombre'),
          valor('Descripción'),
          valor('Horario'),
          valor('Lugar'),
          double.parse(valor('Costo en MXN').replaceAll(',', '.')),
          widget.taller?.imagen ?? '',
          int.parse(valor('Cupo')),
          int.parse(valor('Horas')),
          [valor('Requisito 1'), valor('Requisito 2')],
          id: widget.taller?.id,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.taller == null
              ? 'Nuevo taller'
              : 'Editar taller #${widget.taller!.id}',
        ),
      ),
      body: Form(
        key: formulario,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final campo in campos.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: campo.value,
                  enabled: !guardando,
                  decoration: InputDecoration(labelText: campo.key),
                  keyboardType: teclado(campo.key),
                  validator: (_) => validar(campo.key),
                ),
              ),
            FilledButton(
              onPressed: guardando ? null : guardar,
              child: Text(widget.taller == null ? 'Guardar' : 'Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}
