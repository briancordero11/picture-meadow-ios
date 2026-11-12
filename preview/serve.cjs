#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');

let directory = path.join(__dirname, 'dist');
let port = 8787;
const args = process.argv.slice(2);
for (let index = 0; index < args.length; index++) {
  if (args[index] === '--dir' && args[index + 1]) directory = path.resolve(process.cwd(), args[++index]);
  else if (args[index] === '--port' && args[index + 1]) port = Number(args[++index]);
  else throw new Error('Usage: node preview/serve.cjs [--dir <output-directory>] [--port <number>]');
}
if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error('Port must be an integer from 0 to 65535.');
if (!fs.existsSync(path.join(directory, 'index.html'))) throw new Error('Build the preview first: node preview/build.cjs');
directory = fs.realpathSync(directory);
const contentTypes = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8', '.json': 'application/json; charset=utf-8', '.png': 'image/png',
  '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.txt': 'text/plain; charset=utf-8' };
const csp = "default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self' data:; connect-src 'none'; object-src 'none'; base-uri 'none'; form-action 'none'";
function staysWithin(filename) {
  const relative = path.relative(directory, filename);
  return !relative.startsWith('..') && !path.isAbsolute(relative);
}
const server = http.createServer((request, response) => {
  response.setHeader('Cache-Control', 'no-store');
  response.setHeader('X-Content-Type-Options', 'nosniff');
  response.setHeader('Content-Security-Policy', csp);
  if (!['GET', 'HEAD'].includes(request.method)) {
    response.writeHead(405, { Allow: 'GET, HEAD' }); response.end(); return;
  }
  let filename;
  try {
    const pathname = decodeURIComponent(new URL(request.url, 'http://127.0.0.1').pathname);
    filename = path.resolve(directory, '.' + (pathname === '/' ? '/index.html' : pathname));
    if (!staysWithin(filename)) { response.writeHead(403); response.end(); return; }
    filename = fs.realpathSync(filename);
    if (!staysWithin(filename) || !fs.statSync(filename).isFile()) { response.writeHead(404); response.end(); return; }
  } catch { response.writeHead(404); response.end(); return; }
  response.setHeader('Content-Type', contentTypes[path.extname(filename).toLowerCase()] ?? 'application/octet-stream');
  response.setHeader('Content-Length', fs.statSync(filename).size);
  response.writeHead(200);
  if (request.method === 'HEAD') { response.end(); return; }
  const stream = fs.createReadStream(filename);
  stream.on('error', () => response.destroy());
  stream.pipe(response);
});
server.listen(port, '127.0.0.1', () => {
  console.log('Preview: http://127.0.0.1:' + server.address().port + '/');
  console.log('Serving ' + directory + ' — press Ctrl+C to stop.');
});
