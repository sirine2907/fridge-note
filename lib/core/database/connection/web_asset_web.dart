import 'package:web/web.dart' as web;

/// Resolves [name] against the `<base href>` of index.html (/fridge-note/ on
/// GitHub Pages). A plain relative Uri would resolve against the current page,
/// so a deep link like /fridge-note/invite/CODE looked for
/// /fridge-note/invite/sqlite3.wasm and the demo failed to start.
Uri webAsset(String name) => Uri.parse(web.document.baseURI).resolve(name);
