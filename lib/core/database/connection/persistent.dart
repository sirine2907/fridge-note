import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'web_asset.dart';

/// The real on-device database, one file per signed-in user.
QueryExecutor openPersistentDatabase(String userId) {
  final safeName = userId.replaceAll(RegExp('[^a-zA-Z0-9]'), '');
  return driftDatabase(
    name: 'fridge_note_$safeName',
    web: DriftWebOptions(
      sqlite3Wasm: webAsset('sqlite3.wasm'),
      driftWorker: webAsset('drift_worker.js'),
    ),
  );
}
