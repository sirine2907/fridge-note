// Serves build/web at http://localhost:<port>/fridge-note/ like GitHub Pages
// does, including the 404.html trick: unknown paths get index.html.
// Used by record_demo.cjs. Run alone with: node tool/web_server.cjs
const http = require('http');
const fs = require('fs');
const path = require('path');

const types = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.mjs': 'text/javascript',
  '.json': 'application/json',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.ico': 'image/x-icon',
  '.otf': 'font/otf',
  '.ttf': 'font/ttf',
  '.svg': 'image/svg+xml',
};

function serve(root, port) {
  const server = http.createServer((req, res) => {
    const url = new URL(req.url, 'http://localhost');
    if (!url.pathname.startsWith('/fridge-note/')) {
      res.writeHead(302, { Location: '/fridge-note/' });
      return res.end();
    }
    let file = path.join(root, decodeURIComponent(url.pathname.slice('/fridge-note/'.length)));
    if (!file.startsWith(root) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
      file = path.join(root, 'index.html');
    }
    res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
    fs.createReadStream(file).pipe(res);
  });
  return new Promise((resolve) => server.listen(port, () => resolve(server)));
}

module.exports = { serve };

if (require.main === module) {
  const root = path.resolve(process.argv[2] || 'build/web');
  serve(root, 8099).then(() => console.log('http://localhost:8099/fridge-note/'));
}
