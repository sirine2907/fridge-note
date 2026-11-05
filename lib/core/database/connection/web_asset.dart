// Where the files in the web/ folder (sqlite3.wasm, drift_worker.js) live.
export 'web_asset_native.dart' if (dart.library.js_interop) 'web_asset_web.dart';
