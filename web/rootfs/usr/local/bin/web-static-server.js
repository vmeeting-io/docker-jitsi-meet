#!/usr/bin/env node
'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const { MIME, createResolver } = require('/web/jitsi-meet/ssi.js');

const PORT = Number(process.env.WEB_STATIC_PORT || 8080);
const ROOT = process.env.WEB_ROOT || '/web/jitsi-meet';
const CONFIG_DIR = process.env.WEB_CONFIG_DIR || '/config';

const { resolvePath, processSsi, needsSsi } = createResolver(ROOT, CONFIG_DIR);

function sendFile(res, filePath, statusCode, ssiVars) {
    fs.readFile(filePath, (err, data) => {
        if (err) {
            if (err.code === 'ENOENT') {
                sendNotFound(res, ssiVars);
                return;
            }
            res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end('Internal Server Error');
            return;
        }

        const ext = path.extname(filePath).toLowerCase();
        let body = data;
        if (needsSsi(filePath)) {
            body = Buffer.from(processSsi(data.toString('utf8'), ssiVars || {}, 0), 'utf8');
        }

        res.writeHead(statusCode || 200, {
            'Content-Type': MIME[ext] || 'application/octet-stream',
            'Access-Control-Allow-Origin': '*',
        });
        res.end(body);
    });
}

function sendNotFound(res, ssiVars) {
    const notFound = path.join(ROOT, 'static', '404.html');
    fs.access(notFound, fs.constants.R_OK, (err) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
            res.end('Not Found');
            return;
        }
        sendFile(res, notFound, 404, ssiVars);
    });
}

const server = http.createServer((req, res) => {
    if (req.method !== 'GET' && req.method !== 'HEAD') {
        res.writeHead(405, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Method Not Allowed');
        return;
    }

    const parsed = url.parse(req.url);
    const pathname = parsed.pathname || '/';

    if (pathname.includes('..') || pathname.match(/\.env/)) {
        res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Forbidden');
        return;
    }

    const filePath = resolvePath(pathname);
    if (!filePath) {
        res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Forbidden');
        return;
    }

    const ssiVars = {
        subdomain: req.headers['x-subdomain'] || '',
    };

    if (req.method === 'HEAD') {
        fs.access(filePath, fs.constants.R_OK, (err) => {
            if (err) {
                sendNotFound(res, ssiVars);
                return;
            }
            const ext = path.extname(filePath).toLowerCase();
            res.writeHead(200, {
                'Content-Type': MIME[ext] || 'application/octet-stream',
                'Access-Control-Allow-Origin': '*',
            });
            res.end();
        });
        return;
    }

    sendFile(res, filePath, 200, ssiVars);
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`web static server listening on ${PORT}, root=${ROOT}, config=${CONFIG_DIR}`);
});
