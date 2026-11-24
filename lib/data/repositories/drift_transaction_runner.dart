import '../../domain/repositories/transaction_runner.dart';
import '../db/app_database.dart';

/// Transacciones de Drift: las llamadas a repositorios dentro de [action]
/// (en la misma zona) participan automáticamente.
class DriftTransactionRunner implements TransactionRunner {
  final AppDatabase db;

  DriftTransactionRunner(this.db);

  @override
  Future<T> call<T>(Future<T> Function() action) => db.transaction(action);
}
