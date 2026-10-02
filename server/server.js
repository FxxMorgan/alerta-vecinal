const http = require('http');
const os = require('os');
const { WebSocketServer, WebSocket } = require('ws');

const PORT = process.env.PORT || 7866;

// State management
let activeAlert = null;
let alertHistory = [];
const connectedClients = new Map(); // ws -> { id, name, ip, connectedAt, platform }

// Get local network IPv4 address
function getLocalIp() {
  const interfaces = os.networkInterfaces();
  for (const ifaceName of Object.keys(interfaces)) {
    for (const iface of interfaces[ifaceName] || []) {
      if (iface.family === 'IPv4' && !iface.internal && iface.address.startsWith('192.168.')) {
        return iface.address;
      }
    }
  }
  for (const ifaceName of Object.keys(interfaces)) {
    for (const iface of interfaces[ifaceName] || []) {
      if (iface.family === 'IPv4' && !iface.internal && !iface.address.startsWith('10.66.')) {
        return iface.address;
      }
    }
  }
  return '192.168.18.100';
}

const localIp = getLocalIp();

// Broadcast helper
function broadcast(data, excludeWs = null) {
  const payload = typeof data === 'string' ? data : JSON.stringify(data);
  for (const [clientWs] of connectedClients.entries()) {
    if (clientWs !== excludeWs && clientWs.readyState === WebSocket.OPEN) {
      try {
        clientWs.send(payload);
      } catch (err) {
        console.error('Error enviando a cliente:', err.message);
      }
    }
  }
}

function broadcastStatus() {
  const clientList = Array.from(connectedClients.values()).map(c => ({
    name: c.name,
    ip: c.ip,
    platform: c.platform,
    connectedAt: c.connectedAt
  }));

  broadcast({
    type: 'STATUS_UPDATE',
    activeAlert,
    connectedCount: connectedClients.size,
    clients: clientList,
    serverTime: new Date().toISOString()
  });
}

function triggerEmergencyAlert(sender, notes = '') {
  const alertId = 'alert_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5);
  const now = new Date().toISOString();

  activeAlert = {
    id: alertId,
    sender: sender || 'Vecino Anónimo',
    notes: notes || '¡Alerta de emergencia activada!',
    timestamp: now,
    active: true
  };

  alertHistory.unshift({ ...activeAlert });
  if (alertHistory.length > 50) alertHistory.pop();

  console.log(`\n🚨 [ALERTA DISPARADA] Por: ${activeAlert.sender} a las ${now}`);

  // Broadcast emergency to all connected devices immediately
  broadcast({
    type: 'EMERGENCY_ALERT',
    alert: activeAlert
  });

  return activeAlert;
}

function cancelEmergencyAlert(cancelledBy = 'Administración') {
  if (!activeAlert) return null;

  const previousAlert = { ...activeAlert };
  const now = new Date().toISOString();

  console.log(`\n✅ [ALERTA CANCELADA] Por: ${cancelledBy} a las ${now}`);

  activeAlert = null;

  broadcast({
    type: 'ALERT_CANCELLED',
    previousAlertId: previousAlert.id,
    cancelledBy,
    timestamp: now
  });

  return previousAlert;
}

// HTTP Server for Dashboard & REST API
const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // API Endpoints
  if (req.url === '/api/status' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      activeAlert,
      connectedCount: connectedClients.size,
      localIp,
      port: PORT,
      clients: Array.from(connectedClients.values())
    }));
    return;
  }

  if (req.url === '/api/alert' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const data = body ? JSON.parse(body) : {};
        const alert = triggerEmergencyAlert(data.sender || 'Petición Web / API', data.notes);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, alert }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  if (req.url === '/api/cancel' && req.method === 'POST') {
    let body = '';
    req.on('data', chunk => body += chunk);
    req.on('end', () => {
      try {
        const data = body ? JSON.parse(body) : {};
        cancelEmergencyAlert(data.sender || 'Petición Web / API');
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ success: true, message: 'Alerta cancelada' }));
      } catch (e) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: e.message }));
      }
    });
    return;
  }

  // Web Dashboard (Light Mode First, Swiss Clean Design)
  if (req.url === '/' || req.url === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(`<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Centro de Alerta Vecinal - Servidor Local</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", sans-serif;
      background-color: #F8FAFC;
      color: #0F172A;
      line-height: 1.5;
      padding: 24px 16px;
    }
    .container {
      max-width: 860px;
      margin: 0 auto;
    }
    header {
      background: #FFFFFF;
      border: 1px solid #E2E8F0;
      border-radius: 12px;
      padding: 20px 24px;
      margin-bottom: 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      box-shadow: 0 1px 3px rgba(0,0,0,0.03);
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 12px;
      border-radius: 9999px;
      font-size: 13px;
      font-weight: 600;
    }
    .badge-ok { background: #E8F5E9; color: #2E7D32; border: 1px solid #C8E6C9; }
    .badge-alert { background: #FFEBEE; color: #C62828; border: 1px solid #FFCDD2; animation: pulse 1.5s infinite; }
    @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.6; } }

    .card {
      background: #FFFFFF;
      border: 1px solid #E2E8F0;
      border-radius: 12px;
      padding: 24px;
      margin-bottom: 20px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.03);
    }
    .card-title {
      font-size: 16px;
      font-weight: 700;
      color: #334155;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      margin-bottom: 16px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .alert-banner {
      display: none;
      background: #FEF2F2;
      border: 2px solid #DC2626;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 24px;
      color: #991B1B;
    }
    .alert-banner.active { display: block; }
    .alert-banner h2 { font-size: 20px; font-weight: 800; margin-bottom: 6px; }

    .btn {
      cursor: pointer;
      font-weight: 600;
      padding: 12px 24px;
      border-radius: 8px;
      border: none;
      font-size: 15px;
      transition: all 0.15s ease;
      display: inline-flex;
      align-items: center;
      gap: 8px;
    }
    .btn-danger {
      background-color: #DC2626;
      color: #FFFFFF;
      box-shadow: 0 4px 12px rgba(220, 38, 38, 0.25);
    }
    .btn-danger:hover { background-color: #B91C1C; }
    .btn-outline {
      background: #FFFFFF;
      border: 1px solid #CBD5E1;
      color: #334155;
    }
    .btn-outline:hover { background: #F1F5F9; }
    .btn-success {
      background-color: #68A678;
      color: #FFFFFF;
    }
    .btn-success:hover { background-color: #558B63; }

    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    @media(max-width: 600px) { .grid { grid-template-columns: 1fr; } }

    .stat-box {
      background: #F8FAFC;
      border: 1px solid #E2E8F0;
      border-radius: 8px;
      padding: 16px;
    }
    .stat-label { font-size: 13px; color: #64748B; font-weight: 500; }
    .stat-value { font-size: 24px; font-weight: 700; color: #0F172A; margin-top: 4px; }

    table { width: 100%; border-collapse: collapse; margin-top: 12px; }
    th, td { text-align: left; padding: 10px 12px; border-bottom: 1px solid #F1F5F9; font-size: 14px; }
    th { color: #64748B; font-weight: 600; background: #F8FAFC; }

    .ip-tag {
      background: #EEF2F6;
      padding: 3px 8px;
      border-radius: 4px;
      font-family: monospace;
      font-size: 13px;
      color: #1E293B;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div>
        <h1 style="font-size: 20px; font-weight: 700;">🚨 Centro de Alerta Vecinal</h1>
        <p style="color: #64748B; font-size: 13px; margin-top: 2px;">Servidor Central de Emergencias en Red Local</p>
      </div>
      <div id="statusBadge" class="badge badge-ok">
        <span style="font-size: 10px;">●</span> Normal
      </div>
    </header>

    <div id="alertBanner" class="alert-banner">
      <h2>🚨 ¡ALERTA VECINAL EN PROGRESO!</h2>
      <p id="alertSender" style="font-size: 16px; font-weight: 600; margin-bottom: 4px;">Vecino: -</p>
      <p id="alertNotes" style="font-size: 14px; margin-bottom: 16px;">-</p>
      <button class="btn btn-outline" style="background: white; border-color: #DC2626; color: #DC2626;" onclick="cancelAlert()">Silenciar y Cancelar Alerta General</button>
    </div>

    <div class="card">
      <div class="card-title">Acciones de Emergencia</div>
      <div style="display: flex; gap: 12px; flex-wrap: wrap;">
        <button class="btn btn-danger" onclick="triggerAlert()">
          🔔 Activar Alarma de Prueba (Todos los Dispositivos)
        </button>
        <button class="btn btn-outline" onclick="cancelAlert()">
          Cancelar / Restablecer
        </button>
      </div>
    </div>

    <div class="grid">
      <div class="card">
        <div class="stat-label">Dirección para configurar en la App Móvil:</div>
        <div class="stat-value" style="font-size: 18px; font-family: monospace; color: #4A6FA5;">ws://${localIp}:${PORT}</div>
        <p style="font-size: 12px; color: #64748B; margin-top: 8px;">Coloca esta IP en los teléfonos de los vecinos conectados al mismo WiFi o VPN local.</p>
      </div>
      <div class="card">
        <div class="stat-label">Dispositivos Conectados:</div>
        <div id="connectedCount" class="stat-value">0</div>
        <p style="font-size: 12px; color: #64748B; margin-top: 8px;">Vecinos con la app activa y escuchando alertas.</p>
      </div>
    </div>

    <div class="card">
      <div class="card-title">
        <span>Vecinos Conectados en Línea</span>
        <button class="btn btn-outline" style="padding: 4px 10px; font-size: 12px;" onclick="fetchStatus()">Refrescar</button>
      </div>
      <table>
        <thead>
          <tr>
            <th>Vecino / Casa</th>
            <th>Plataforma</th>
            <th>IP Dispositivo</th>
            <th>Hora Conexión</th>
          </tr>
        </thead>
        <tbody id="clientsTable">
          <tr><td colspan="4" style="text-align: center; color: #94A3B8;">Esperando conexiones de vecinos...</td></tr>
        </tbody>
      </table>
    </div>
  </div>

  <script>
    const socket = new WebSocket('ws://' + window.location.host);

    socket.onopen = () => {
      console.log('Conectado al WebSocket local');
      socket.send(JSON.stringify({ type: 'REGISTER', sender: 'Dashboard Web', platform: 'Web' }));
    };

    socket.onmessage = (event) => {
      try {
        const msg = JSON.parse(event.data);
        if (msg.type === 'EMERGENCY_ALERT') {
          handleAlertActive(msg.alert);
        } else if (msg.type === 'ALERT_CANCELLED') {
          handleAlertCancelled();
        } else if (msg.type === 'STATUS_UPDATE') {
          updateUiWithStatus(msg);
        }
      } catch(e) {
        console.error(e);
      }
    };

    function handleAlertActive(alert) {
      document.getElementById('alertBanner').classList.add('active');
      document.getElementById('alertSender').innerText = 'Vecino que alertó: ' + alert.sender;
      document.getElementById('alertNotes').innerText = alert.notes || '¡Presencia sospechosa o robo!';
      const badge = document.getElementById('statusBadge');
      badge.className = 'badge badge-alert';
      badge.innerHTML = '● ¡ALERTA ACTIVA!';
    }

    function handleAlertCancelled() {
      document.getElementById('alertBanner').classList.remove('active');
      const badge = document.getElementById('statusBadge');
      badge.className = 'badge badge-ok';
      badge.innerHTML = '● Normal';
    }

    function updateUiWithStatus(data) {
      document.getElementById('connectedCount').innerText = data.connectedCount;
      if (data.activeAlert) {
        handleAlertActive(data.activeAlert);
      } else {
        handleAlertCancelled();
      }

      const tbody = document.getElementById('clientsTable');
      if (!data.clients || data.clients.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" style="text-align: center; color: #94A3B8;">No hay vecinos conectados actualmente.</td></tr>';
        return;
      }

      tbody.innerHTML = data.clients.map(c => \`
        <tr>
          <td><strong>\${c.name}</strong></td>
          <td>\${c.platform || 'Android'}</td>
          <td><span class="ip-tag">\${c.ip}</span></td>
          <td>\${new Date(c.connectedAt).toLocaleTimeString()}</td>
        </tr>
      \`).join('');
    }

    async function fetchStatus() {
      try {
        const res = await fetch('/api/status');
        const data = await res.json();
        updateUiWithStatus(data);
      } catch(e) {
        console.error(e);
      }
    }

    async function triggerAlert() {
      const sender = prompt('Nombre o Casa que emite la alerta:', 'Casa 1 (Prueba)');
      if (!sender) return;
      await fetch('/api/alert', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sender, notes: 'Alerta activada desde el panel local' })
      });
    }

    async function cancelAlert() {
      await fetch('/api/cancel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sender: 'Panel Administrador' })
      });
    }

    fetchStatus();
    setInterval(fetchStatus, 5000);
  </script>
</body>
</html>`);
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not Found');
});

// WebSocket Server initialization
const wss = new WebSocketServer({ server });

wss.on('connection', (ws, req) => {
  const ip = req.socket.remoteAddress.replace(/^.*:/, '') || '127.0.0.1';
  const clientId = 'c_' + Date.now() + '_' + Math.random().toString(36).substr(2, 4);

  connectedClients.set(ws, {
    id: clientId,
    name: `Vecino (${ip})`,
    ip,
    platform: 'Android',
    connectedAt: new Date().toISOString()
  });

  console.log(`[CONEXIÓN] Cliente conectado desde ${ip}. Total activos: ${connectedClients.size}`);

  // Send initial state to the client
  ws.send(JSON.stringify({
    type: 'INIT',
    clientId,
    serverIp: localIp,
    activeAlert,
    connectedCount: connectedClients.size
  }));

  // If there's an ongoing alert, inform client immediately
  if (activeAlert) {
    ws.send(JSON.stringify({
      type: 'EMERGENCY_ALERT',
      alert: activeAlert
    }));
  }

  broadcastStatus();

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message.toString());

      if (data.type === 'REGISTER') {
        const clientInfo = connectedClients.get(ws);
        if (clientInfo) {
          clientInfo.name = data.sender || clientInfo.name;
          clientInfo.platform = data.platform || clientInfo.platform;
          connectedClients.set(ws, clientInfo);
        }
        console.log(`[REGISTRO] ${clientInfo.name} (${clientInfo.platform})`);
        broadcastStatus();
      } else if (data.type === 'PING') {
        ws.send(JSON.stringify({ type: 'PONG', timestamp: Date.now() }));
      } else if (data.type === 'ALERT') {
        triggerEmergencyAlert(data.sender, data.notes);
        broadcastStatus();
      } else if (data.type === 'CANCEL_ALERT') {
        cancelEmergencyAlert(data.sender);
        broadcastStatus();
      }
    } catch (e) {
      console.error('Error parseando mensaje WS:', e.message);
    }
  });

  ws.on('close', () => {
    const client = connectedClients.get(ws);
    console.log(`[DESCONEXIÓN] ${client ? client.name : 'Cliente'} desconectado.`);
    connectedClients.delete(ws);
    broadcastStatus();
  });

  ws.on('error', (err) => {
    console.error('[ERROR WS]:', err.message);
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n======================================================`);
  console.log(`🚨 SERVIDOR DE ALERTA VECINAL INICIADO CON ÉXITO`);
  console.log(`======================================================`);
  console.log(`📍 IP Local detectada:   ${localIp}`);
  console.log(`🌐 Panel Web / REST:     http://${localIp}:${PORT}`);
  console.log(`⚡ WebSocket URL:         ws://${localIp}:${PORT}`);
  console.log(`💻 Localhost:            http://localhost:${PORT}`);
  console.log(`======================================================\n`);
});
