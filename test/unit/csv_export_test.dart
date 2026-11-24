import 'dart:io';

import 'package:cal_counter/data/datasources/local_data_source.dart';
import 'package:cal_counter/data/repositories/meal_repository_impl.dart';
import 'package:cal_counter/domain/entities/meal_item.dart';
// file_picker.dart reexporta FilePickerPlatform (file_picker 12+): es el
// punto de inyección para tests, ya que FilePicker es final/static.
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeFilePicker extends FilePickerPlatform
    with MockPlatformInterfaceMixin {
  _FakeFilePicker({required this.saveDir});

  final String saveDir;
  String? lastFileName;
  Uint8List? lastBytes;

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    lastFileName = fileName;
    lastBytes = bytes;
    final file = File(join(saveDir, fileName));
    await file.writeAsBytes(bytes);
    return file.absolute.uri;
  }
}

void main() {
  late LocalDataSourceImpl dataSource;
  late MealRepositoryImpl mealRepo;
  late _FakeFilePicker fakePicker;
  final testDir = join('.', 'test_tmp_csv_export');

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    Directory(testDir).createSync(recursive: true);
    dataSource = LocalDataSourceImpl();
    mealRepo = MealRepositoryImpl(dataSource);
    fakePicker = _FakeFilePicker(saveDir: testDir);
    FilePickerPlatform.instance = fakePicker;
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return testDir;
        });
  });

  tearDown(() async {
    await dataSource.close();
    await databaseFactory.deleteDatabase(join(testDir, 'db_ctrl_calorias.db'));
    final dir = Directory(testDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('CSV Export Format Verification', () async {
    await dataSource.initDb();

    // 1. Create Data
    final date = DateTime(2023, 12, 1);
    final mealId = await dataSource.createMeal('Comida_Test', date);

    final item = MealItem(
      id: 0,
      mealId: mealId,
      alimento: 'Test Food',
      cantidad: 100,
      grasas: 5,
      carbohidratos: 10,
      proteinas: 15,
      kcal: 150,
    );
    await dataSource.addItemToMeal(item);

    // 2. Export
    final path = await mealRepo.exportMealsByDateCSV(date);

    // 3. Verify File Content
    final file = File(path);
    final content = await file.readAsString();

    // Real delimiter is TAB (see ListToCsvConverter(fieldDelimiter: '\t')).
    expect(
      content,
      contains(
        'nombre_comida\tcantidad\talimento\tgrasas\tcarbos\tproteinas\tkcal',
      ),
    );
    expect(content, contains('Comida_Test'));
    expect(content, contains('Test Food'));
    expect(content, contains('150.0'));
  });
}
