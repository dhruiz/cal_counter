import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  /// Guarda [texto] (UTF-8). Devuelve la ruta, o null si se cancela.
  static Future<String?> saveText({
    required String nombre,
    required String texto,
    required String extension,
    String titulo = 'Guardar archivo',
  }) async {
    final saved = await FilePicker.saveFile(
      dialogTitle: titulo,
      fileName: nombre,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: Uint8List.fromList(utf8.encode(texto)),
    );
    return (saved == null || saved.isEmpty) ? null : saved;
  }

  /// Abre un archivo cualquiera (el tipo se detecta por su contenido).
  static Future<PickedData?> pick() async {
    final res = await FilePicker.pickFiles(type: FileType.any, withData: true);
    if (res == null || res.files.isEmpty) return null;
    final f = res.files.single;
    final bytes = f.bytes;
    if (bytes == null) return null;
    return PickedData(f.name, bytes);
  }
}
