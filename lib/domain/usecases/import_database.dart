import '../../data/datasources/local_data_source.dart';

class ImportDatabase {
  final LocalDataSource dataSource;

  ImportDatabase(this.dataSource);

  Future<int> call(String sourcePath) async {
    return await dataSource.importDatabase(sourcePath);
  }
}
