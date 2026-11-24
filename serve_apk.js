const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const APK_PATH = 'c:/Personal Application/Vega.apk';

const server = http.createServer((req, res) => {
  if (req.url === '/Vega.apk') {
    if (fs.existsSync(APK_PATH)) {
      const stat = fs.statSync(APK_PATH);
      res.writeHead(200, {
        'Content-Type': 'application/vnd.android.package-archive',
        'Content-Length': stat.size,
        'Content-Disposition': 'attachment; filename="Vega.apk"'
      });
      fs.createReadStream(APK_PATH).pipe(res);
      console.log(`[${new Date().toLocaleTimeString()}] Phone downloaded Vega.apk (${stat.size} bytes)`);
    } else {
      res.writeHead(404);
      res.end('APK not found. Run .\\build_apk.ps1 first.');
    }
  } else {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(`<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Download Vega APK</title>
  <style>
    body {
      background: #0B0C0E;
      color: #FFFFFF;
      font-family: -apple-system, sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
      text-align: center;
    }
    .card {
      background: #161618;
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 24px;
      padding: 32px 24px;
      max-width: 360px;
      width: 100%;
      box-shadow: 0 20px 50px rgba(0,0,0,0.8);
    }
    .badge {
      display: inline-block;
      background: #8B4DF5;
      color: #FFF;
      font-size: 11px;
      font-weight: 800;
      padding: 4px 12px;
      border-radius: 20px;
      margin-bottom: 16px;
      letter-spacing: 0.5px;
    }
    h1 { margin: 0 0 8px 0; font-size: 24px; font-weight: 800; }
    p { color: #8E8E93; font-size: 14px; margin: 0 0 24px 0; line-height: 1.5; }
    .btn {
      display: block;
      background: #F6C84C;
      color: #000;
      text-decoration: none;
      padding: 16px 24px;
      border-radius: 16px;
      font-weight: 800;
      font-size: 16px;
      box-shadow: 0 8px 20px rgba(246, 200, 76, 0.3);
    }
    .note {
      font-size: 12px;
      color: #636366;
      margin-top: 16px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">MEET PANDYA • DHAN 1109849315</div>
    <h1>Vega APK</h1>
    <p>Personal F&O Trading Ledger with live Supabase cloud sync & Dhan fee calculators.</p>
    <a href="/Vega.apk" class="btn">⬇️ Download Vega.apk</a>
    <div class="note">Once downloaded, tap the notification to install. If Android prompts "Install unknown apps", tap <b>Settings</b> ➔ <b>Allow from this source</b>.</div>
  </div>
</body>
</html>`);
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Vega APK Download Server running at http://192.168.1.5:${PORT}/`);
});
