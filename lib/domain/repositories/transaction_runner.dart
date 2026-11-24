/// Ejecuta varias operaciones de repositorio como una sola transacción: o se
/// aplican todas o ninguna. Lo usan los casos de uso que escriben en varias
/// tablas (alta en tienda, carrito, importación...).
abstract class TransactionRunner {
  Future<T> call<T>(Future<T> Function() action);
}
