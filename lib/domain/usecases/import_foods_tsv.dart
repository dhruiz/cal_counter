import '../../data/datasources/local_data_source.dart';

class ImportFoodsTsv {
  final LocalDataSource dataSource;

  ImportFoodsTsv(this.dataSource);

  Future<int> call(String tsvContent) async {
    return await dataSource.importFoodsTsvFromString(tsvContent);
  }
}
