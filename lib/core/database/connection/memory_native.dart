import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// A fresh database that only lives in memory. Used by demo mode.
QueryExecutor openInMemoryDatabase() => NativeDatabase.memory();
