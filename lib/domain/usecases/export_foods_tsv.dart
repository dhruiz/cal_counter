import '../../data/datasources/local_data_source.dart';

class ExportFoodsTsv {
  final LocalDataSource dataSource;

  ExportFoodsTsv(this.dataSource);

  Future<String> call() async {
    return await dataSource.exportFoodsTsv();
  }
}
