import 'package:cal_counter/data/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// Base de datos en memoria para tests (mismo esquema que en el móvil).
AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}
