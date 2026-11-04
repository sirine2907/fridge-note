import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

/// A fresh database that only lives in memory. Used by demo mode.
///
/// sqlite3.wasm sits in the web/ folder, next to index.html.
QueryExecutor openInMemoryDatabase() {
  return DatabaseConnection.delayed(Future(() async {
    final sqlite3 = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
    sqlite3.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
    return DatabaseConnection(WasmDatabase.inMemory(sqlite3));
  }));
}
