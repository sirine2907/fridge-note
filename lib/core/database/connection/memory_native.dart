import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// A fresh database that only lives in memory. Used by demo mode and tests.
///
/// Streams are closed right away when nobody listens any more. Drift normally
/// waits a moment (on a timer) to reuse them, which hangs Flutter widget tests.
QueryExecutor openInMemoryDatabase() {
  return DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true);
}
