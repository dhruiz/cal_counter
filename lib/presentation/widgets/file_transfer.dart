import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils.dart';

/// Archivo elegido por el usuario.
class PickedData {
  final String nombre;
  final Uint8List bytes;

  const PickedData(this.nombre, this.bytes);

  String get texto => utf8.decode(bytes, allowMalformed: true);

  String get extension => p.extension(nombre).toLowerCase().replaceAll('.', '');

  /// Cabecera de un archivo SQLite ("SQLite format 3").
  bool get esSqlite =>
      bytes.length > 16 &&
      utf8.decode(bytes.sublist(0, 15), allowMalformed: true) ==
          'SQLite format 3';

  /// Copia a un archivo temporal (para abrir un .db en solo lectura).
  Future<String> aArchivoTemporal() async {
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(dir.path, 'importar_${DateTime.now().millisecondsSinceEpoch}.db'),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

/// Guardar y abrir archivos con el selector del sistema (SAF en Android:
/// sin permisos de almacenamiento).
class FileTransfer {
  FileTransfer._();

  /// Guarda [texto] (UTF-8). Devuelve una ruta legible, o null si se cancela.
  ///
  /// Desde file_picker 12 `saveFile` devuelve un [Uri] y escribe los bytes él
  /// mismo (SAF en Android); el tipo MIME sale de la extensión de [nombre].
  static Future<String?> saveText({
    required String nombre,
    required String texto,
    String titulo = 'Guardar archivo',
  }) async {
    final saved = await FilePicker.saveFile(
      dialogTitle: titulo,
      fileName: nombre,
      bytes: Uint8List.fromList(utf8.encode(texto)),
    );
    return saved == null ? null : AppUtils.formatRutaGuardada(saved);
  }

  /// Abre un archivo cualquiera (el tipo se detecta por su contenido).
  ///
  /// `FileType.any`: algunos gestores no reconocen .json/.tsv/.db como tipos
  /// personalizados; el contenido se valida al leerlo.
  static Future<PickedData?> pick() async {
    final f = await FilePicker.pickFile(type: FileType.any);
    if (f == null) return null; // Cancelado
    return PickedData(f.name, await f.readAsBytes());
  }
}
