import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/styles.dart';
import '../../data/backup/foods_tsv_codec.dart';
import '../../data/backup/full_backup.dart';
import '../../data/backup/legacy_db.dart';
import '../../data/backup/repertoire_codec.dart';
import '../../domain/entities/repertoire.dart';
import '../../domain/services/dates.dart';
import '../providers/data_provider.dart';
import '../widgets/file_transfer.dart';
import '../widgets/food_widgets.dart';

/// Ajustes → Datos: compartir repertorios, hoja de cálculo, respaldo
/// completo, formatos antiguos y catálogos incluidos.
class DataView extends ConsumerStatefulWidget {
  const DataView({super.key});

  @override
  ConsumerState<DataView> createState() => _DataViewState();
}

class _DataViewState extends ConsumerState<DataView> {
  bool _busy = false;
  bool _conRecetas = true;

  void _msg(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppStyles.semaphRed : null,
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _msg('$e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Exportar ------------------------------------------------------------------

  Future<void> _exportRepertoire() => _run(() async {
    final rep = await ref.read(exportRepertoireProvider)(
      incluirRecetas: _conRecetas,
    );
    final path = await FileTransfer.saveText(
      nombre: 'repertorio_${dateKey(DateTime.now())}.json',
      texto: RepertoireCodec.encode(rep),
      titulo: 'Exportar repertorio',
    );
    if (path != null) {
      _msg(
        'Repertorio exportado (${rep.alimentos.length} alimentos'
        '${rep.recetas.isEmpty ? '' : ', ${rep.recetas.length} recetas'}).',
      );
    }
  });

  Future<void> _exportTsv() => _run(() async {
    final rep = await ref.read(exportRepertoireProvider)();
    final path = await FileTransfer.saveText(
      nombre: 'alimentos_${dateKey(DateTime.now())}.tsv',
      texto: FoodsTsvCodec.encode(rep),
      titulo: 'Exportar alimentos (TSV)',
    );
    if (path != null) _msg('${rep.alimentos.length} alimentos exportados.');
  });

  Future<void> _exportBackup() => _run(() async {
    final json = await ref.read(fullBackupProvider).export();
    final path = await FileTransfer.saveText(
      nombre: 'cal_counter_respaldo_${dateKey(DateTime.now())}.json',
      texto: json,
      titulo: 'Guardar respaldo completo',
    );
    if (path != null) _msg('Respaldo guardado.');
  });

  // Importar ------------------------------------------------------------------

  /// Importa cualquier archivo: detecta repertorio, respaldo, TSV o .db.
  Future<void> _import() => _run(() async {
    final file = await FileTransfer.pick();
    if (file == null || !mounted) return;
    if (file.esSqlite) {
      final path = await file.aArchivoTemporal();
      final data = LegacyData.read(path);
      await _importRepertoire(data.toRepertoire(), 'Base de datos antigua');
      return;
    }
    final texto = file.texto.trimLeft();
    if (texto.startsWith('{')) {
      if (texto.contains('"${FullBackupService.formato}"')) {
        await _restore(texto);
      } else {
        await _importRepertoire(RepertoireCodec.decode(texto), 'Repertorio');
      }
      return;
    }
    await _importRepertoire(FoodsTsvCodec.decode(texto), 'Alimentos (TSV)');
  });

  Future<void> _importRepertoire(Repertoire rep, String titulo) async {
    if (rep.vacio) {
      _msg('El archivo no contiene alimentos ni recetas.', error: true);
      return;
    }
    final import = ref.read(importRepertoireProvider);
    final preview = await import(rep, dryRun: true);
    if (!mounted) return;
    final politica = await ImportPreviewDialog.show(context, titulo, preview);
    if (politica == null) return;
    final res = await import(rep, politica: politica);
    _msg('Importado: ${res.resumen}');
  }

  Future<void> _restore(String json) async {
    final counts = FullBackupService.inspect(json);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: Text(
          'Se REEMPLAZARÁ todo lo que hay ahora (alimentos, recetas, '
          'compras, listas, comidas y ajustes) por el respaldo:\n\n'
          '${counts['alimentos']} alimentos · ${counts['recetas']} recetas · '
          '${counts['compras']} compras · ${counts['listas_compra']} listas · '
          '${counts['comidas']} comidas.\n\n'
          'Antes se guarda automáticamente una copia del estado actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final service = ref.read(fullBackupProvider);
    final copia = await saveAutomaticBackup(service);
    await service.restore(json);
    await markOnboardingDone();
    _msg(
      copia == null
          ? 'Respaldo restaurado.'
          : 'Respaldo restaurado. Copia del estado anterior: $copia',
    );
  }

  Future<void> _seed() => _run(() async {
    final rep = await ref.read(seedCatalogProvider.future);
    await _importRepertoire(rep, 'Catálogo base');
  });

  Future<void> _produce() => _run(() async {
    final rep = await ref.read(produceCatalogProvider.future);
    await _importRepertoire(rep, 'Frutas y verduras');
  });

  Future<void> _migrateLegacy(String path) => _run(() async {
    final data = LegacyData.read(path);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Datos de la versión anterior'),
        content: Text(
          'Se encontraron ${data.alimentos.length} alimentos, '
          '${data.productos.length} productos, ${data.recetas.length} recetas '
          'y ${data.listas.length} listas. Se pasarán al formato nuevo; el '
          'archivo antiguo no se modifica.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final report = await ref.read(migrateLegacyProvider)(data);
    await markLegacyMigrated();
    ref.invalidate(legacyDatabaseProvider);
    _msg('Importado: ${report.resumen}');
  });

  @override
  Widget build(BuildContext context) {
    final legacy = ref.watch(legacyDatabaseProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos y respaldos'),
        backgroundColor: AppStyles.primary,
        foregroundColor: Colors.white,
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (_busy) const LinearProgressIndicator(),
            if (legacy != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: InfoBanner(
                  color: AppStyles.semaphBlue,
                  icon: Icons.history,
                  text: 'Hay datos de la versión anterior de la app.',
                  action: TextButton(
                    onPressed: () => _migrateLegacy(legacy),
                    child: const Text('Importar'),
                  ),
                ),
              ),
            const _Section('Compartir'),
            SwitchListTile(
              secondary: const Icon(Icons.menu_book_outlined),
              title: const Text('Incluir recetas'),
              subtitle: const Text(
                'Los precios, comidas y ajustes nunca se comparten.',
              ),
              value: _conRecetas,
              onChanged: (v) => setState(() => _conRecetas = v),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Exportar repertorio'),
              subtitle: const Text(
                'Archivo .json para pasar tus alimentos a otra persona',
              ),
              onTap: _exportRepertoire,
            ),
            ListTile(
              leading: const Icon(Icons.file_open_outlined),
              title: const Text('Importar'),
              subtitle: const Text(
                'Repertorio (.json), respaldo, alimentos (.tsv) o base de '
                'datos antigua (.db). Se fusiona sin duplicar.',
              ),
              onTap: _import,
            ),
            const _Section('Hoja de cálculo'),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Exportar alimentos (TSV)'),
              subtitle: const Text('Para abrir en Excel u hojas de cálculo'),
              onTap: _exportTsv,
            ),
            const _Section('Respaldo completo'),
            ListTile(
              leading: const Icon(Icons.save_outlined),
              title: const Text('Crear respaldo'),
              subtitle: const Text(
                'Todo: alimentos, recetas, compras, listas, comidas y ajustes',
              ),
              onTap: _exportBackup,
            ),
            const ListTile(
              leading: Icon(Icons.restore),
              title: Text('Restaurar un respaldo'),
              subtitle: Text('Usa «Importar» y elige el archivo de respaldo.'),
            ),
            const _Section('Catálogos incluidos'),
            ListTile(
              leading: const Icon(Icons.eco_outlined),
              title: const Text('Añadir el catálogo base'),
              subtitle: const Text(
                '678 alimentos genéricos con su tabla nutricional',
              ),
              onTap: _seed,
            ),
            ListTile(
              leading: const Icon(Icons.local_florist_outlined),
              title: const Text('Añadir frutas y verduras'),
              subtitle: const Text(
                '229 frutas, verduras y hortalizas (tablas CIQUAL y USDA)',
              ),
              onTap: _produce,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(color: AppStyles.primary),
    ),
  );
}

/// Vista previa de una importación: qué se añade, qué se completa y qué
/// tiene valores distintos (con la política a aplicar). Devuelve la
/// política elegida o null si se cancela.
class ImportPreviewDialog extends StatefulWidget {
  final String titulo;
  final ImportReport preview;

  const ImportPreviewDialog({
    super.key,
    required this.titulo,
    required this.preview,
  });

  static Future<ConflictPolicy?> show(
    BuildContext context,
    String titulo,
    ImportReport preview,
  ) => showDialog<ConflictPolicy>(
    context: context,
    builder: (_) => ImportPreviewDialog(titulo: titulo, preview: preview),
  );

  @override
  State<ImportPreviewDialog> createState() => _ImportPreviewDialogState();
}

class _ImportPreviewDialogState extends State<ImportPreviewDialog> {
  ConflictPolicy _politica = ConflictPolicy.conservarMios;

  @override
  Widget build(BuildContext context) {
    final r = widget.preview;
    Widget row(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
    final nada = r.nuevos + r.completados + r.conflictos + r.recetasNuevas == 0;
    return AlertDialog(
      title: Text('Importar: ${widget.titulo}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(Icons.add_circle_outline, '${r.nuevos} alimentos nuevos'),
            row(
              Icons.auto_fix_high,
              '${r.completados} se completan con datos que faltaban',
            ),
            row(Icons.check, '${r.sinCambios} ya estaban igual'),
            if (r.recetasNuevas + r.recetasOmitidas > 0)
              row(
                Icons.menu_book_outlined,
                '${r.recetasNuevas} recetas nuevas'
                '${r.recetasOmitidas > 0 ? ' (${r.recetasOmitidas} ya existían)' : ''}',
              ),
            if (r.codigosEnConflicto > 0)
              row(
                Icons.qr_code,
                '${r.codigosEnConflicto} códigos ya son de otro alimento '
                '(se ignoran)',
              ),
            if (r.conflictos > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${r.conflictos} alimentos tienen valores distintos: '
                '${r.nombresEnConflicto.take(5).join(', ')}'
                '${r.nombresEnConflicto.length > 5 ? '...' : ''}',
              ),
              RadioGroup<ConflictPolicy>(
                groupValue: _politica,
                onChanged: (v) => setState(() => _politica = v ?? _politica),
                child: Column(
                  children: [
                    for (final p in ConflictPolicy.values)
                      RadioListTile<ConflictPolicy>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: p,
                        title: Text(p.etiqueta),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: nada ? null : () => Navigator.pop(context, _politica),
          child: const Text('Importar'),
        ),
      ],
    );
  }
}
