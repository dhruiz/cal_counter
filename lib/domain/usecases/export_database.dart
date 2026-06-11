import '../../data/datasources/local_data_source.dart';

class ExportDatabase {
  final LocalDataSource dataSource;

  ExportDatabase(this.dataSource);

  Future<void> call(String destinationPath) async {
    await dataSource.exportDatabase(destinationPath);
  }
}
