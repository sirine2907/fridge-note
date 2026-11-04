// Picks the right in-memory database for the platform.
export 'memory_native.dart' if (dart.library.js_interop) 'memory_web.dart';
