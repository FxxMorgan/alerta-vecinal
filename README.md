# 🚨 Alerta Vecinal - Sistema de Emergencia Comunitaria

> **MVP Fast** diseñado para comunidades, condominios y pasajes que necesitan una alarma de pánico en tiempo real, de máxima penetración sonora y capaz de **despertar los teléfonos móviles incluso si están con pantalla bloqueada o en reposo**, sin depender de servicios de terceros como Firebase.

---

## 🧭 ¿Para qué es este proyecto?

En situaciones de peligro o robos, los grupos de WhatsApp o alarmas silenciosas no sirven porque:
- Los mensajes no suenan si el vecino tiene el teléfono silenciado o en "No Molestar".
- Android entra en ahorro de batería profundo (**Doze Mode**) y posterga las notificaciones.
- La gente no se despierta en la madrugada con una notificación normal.

**Alerta Vecinal** soluciona esto:
1. Un vecino pulsa el botón de pánico en la app móvil.
2. La señal viaja al servidor por **WebSocket**.
3. **Todos los teléfonos despiertan su pantalla de inmediato**, suben su volumen al 100%, activan una sirena de emergencia penetrante en bucle continuo y vibran con máxima intensidad.

---

## 📦 1. Probar en 2 Minutos (Instalar APK en tu Teléfono)

Si solo quieres usar la app en tu teléfono sin tocar código:
1. Descarga el archivo **[`releases/AlertaVecinal-ARMv8.apk`](releases/AlertaVecinal-ARMv8.apk)** directamente a tu teléfono Android.
2. Ábrelo e instálalo (si te lo pide, autoriza *Instalar aplicaciones de fuentes desconocidas*).
3. **⚠️ PASO OBLIGATORIO DE BATERÍA**: Al abrir la app verás un aviso amarillo:
   > **Optimización de Batería Activa**
   > *Pulsa en "Excluir de Optimización" y selecciona Permitir*.
   > 
   > **¿Por qué?** Android apaga las antenas WiFi/4G y suspende apps cuando la pantalla se bloquea. Al excluirla, la conexión se mantiene viva 24/7 para que la alarma suene al instante.
4. En el ícono de tuerca (⚙️) puedes colocar tu nombre (ej. *"Casa 4B - Los Aromos"*) y la dirección del servidor.

---

## ☁️ 2. Dónde y Cómo Subir el Backend 100% Gratis

> **Nota técnica importante sobre Vercel**: Vercel es una plataforma *serverless* pensada para webs que responden en milisegundos y luego se duermen. **Las funciones serverless de Vercel no permiten conexiones WebSocket continuas de 24 horas**. Para que los vecinos estén escuchando siempre alertas en tiempo real necesitas un proceso persistente. Aquí tienes las dos mejores opciones **100% gratuitas**:

---

### Opción A: Cloudflare Tunnel (Recomendada - Gratis y Ultra Rápida)
Puedes correr el servidor en tu propia PC, notebook o una Raspberry Pi vieja en tu casa, y Cloudflare te dará un dominio público seguro con HTTPS/WSS gratis, sin abrir puertos en el router y sin IP pública.

1. Crea una cuenta gratuita en [Cloudflare](https://dash.cloudflare.com/).
2. Ve a **Zero Trust** > **Networks** > **Tunnels**.
3. Crea un nuevo túnel (ej. `alerta-vecinos`) y copia el comando que te entrega para instalar `cloudflared` en tu máquina.
4. En la pestaña **Public Hostnames** del túnel, agrega una ruta:
   - **Subdominio**: `vecinos` (o el que quieras de tu dominio, ej: `vecinos.tudominio.com`).
   - **Type**: `HTTP`.
   - **URL**: `localhost:7866`.
5. ¡Listo! Tu servidor local en el puerto `7866` ahora tiene una URL segura global:
   - Web: `https://vecinos.tudominio.com`
   - WebSocket para la App: `wss://vecinos.tudominio.com`

---

### Opción B: Render.com o Koyeb (En la Nube 24/7 Gratis)
Si prefieres que esté en la nube sin depender de tu PC encendida:

#### En Render.com:
1. Crea una cuenta gratuita en [render.com](https://render.com/).
2. Haz clic en **New +** > **Web Service**.
3. Conecta este repositorio de GitHub (`FxxMorgan/alerta-vecinal`).
4. Configura:
   - **Root Directory**: `server`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
   - **Plan**: `Free`
5. Render te dará una URL como `https://alerta-vecinal.onrender.com`.
   - En la app Flutter solo pones en la configuración: `wss://alerta-vecinal.onrender.com`.

---

### Opción C: Ejecutar en tu PC / Red Local WiFi

Si solo quieres probar en tu casa o red local:
```bash
cd server
npm install
node server.js
```
El servidor te mostrará en consola:
```text
======================================================
🚨 SERVIDOR DE ALERTA VECINAL INICIADO CON ÉXITO
======================================================
📍 IP Local detectada:   192.168.1.100
🌐 Panel Web / REST:     http://192.168.1.100:7866
⚡ WebSocket URL:         ws://192.168.1.100:7866
💻 Localhost:            http://localhost:7866
======================================================
```
Abre `http://localhost:7866` en tu navegador para ver el panel de administración en vivo.

---

## 🤖 3. Guía para Programar y Modificar este Código con IA

Si usas **Cursor, Claude, Windsurf, GitHub Copilot, Antigravity o ChatGPT**, esta sección te explica cómo está estructurado el código para que le pidas cambios a la IA fácilmente.

### Mapa del Código Fuente

```text
alerta-vecinal/
│
├── server/                                # BACKEND NODE.JS
│   └── server.js                          # Servidor HTTP + WebSocket + Dashboard Web integrado
│
└── app/                                   # APLICACIÓN MÓVIL FLUTTER
    ├── android/
    │   ├── app/src/main/AndroidManifest.xml   # Permisos de batería, wake lock y foreground service
    │   └── app/src/main/kotlin/.../MainActivity.kt # Código nativo Kotlin: despierta pantalla y sube volumen
    │
    ├── assets/sounds/
    │   └── alarm_siren.wav                # Archivo de audio de la sirena de emergencia
    │
    └── lib/
        ├── main.dart                      # Punto de entrada de la aplicación
        ├── models/
        │   └── alert_model.dart           # Estructura del mensaje de alerta (id, sender, notes, timestamp)
        ├── services/
        │   ├── alarm_sync_service.dart    # Conexión WebSocket, reconexión automática y Foreground Service
        │   ├── alarm_player_service.dart  # Reproducción en bucle de la sirena, vibración y WakeLock
        │   └── native_alert_service.dart  # Canal de comunicación con Android nativo (batería y pantalla)
        ├── screens/
        │   ├── home_screen.dart           # Pantalla principal con el Botón de Pánico circular
        │   ├── active_alert_dialog.dart   # Pantalla completa de emergencia cuando suena la alarma
        │   └── settings_sheet.dart        # Configuración de nombre de vecino y servidor
        └── theme/
            └── app_theme.dart             # Paleta de colores (Modo Claro estricto / Swiss Clean)
```

---

### 💬 Prompts Listos para Copiar y Pegar en tu Asistente de IA

Copia y pega cualquiera de estos prompts en tu editor con IA para agregar nuevas funciones:

#### 💡 Prompt 1: Enviar Ubicación GPS del Vecino en la Alerta
> *"Actuando como desarrollador experto en Flutter y Node.js, agrega la función de geolocalización al proyecto. Cuando el vecino presione el botón de pánico en `app/lib/screens/home_screen.dart`, obtén las coordenadas GPS usando el paquete `geolocator` y agrégalas al `AlertModel`. Luego, en `app/lib/screens/active_alert_dialog.dart` y en el panel web `server/server.js`, muestra un enlace de Google Maps con la ubicación exacta donde se originó la alarma."*

#### 💡 Prompt 2: Selector de Tipo de Emergencia (Robo, Fuego, Médica)
> *"Quiero que antes o al disparar la alarma en `app/lib/screens/home_screen.dart`, el vecino pueda elegir entre tres tipos de alerta: 1) Robo / Sospechosos, 2) Incendio, 3) Emergencia Médica. Actualiza `AlertModel`, el servidor en `server/server.js` y el diseño visual de la pantalla de alerta para que muestre el color y el ícono correspondiente según el tipo."*

#### 💡 Prompt 3: Soporte para Múltiples Calles o Pasajes (Canales)
> *"Modifica `server/server.js` y `app/lib/services/alarm_sync_service.dart` para soportar canales o grupos de vecinos (ej: 'Pasaje Los Aromos', 'Calle Central'). Cada cliente debe poder suscribirse a su pasaje o al canal general, y las alertas deben emitirse solo a los vecinos pertenecientes a ese grupo."*

#### 💡 Prompt 4: Cambiar o Personalizar el Sonido de la Sirena
> *"Explícame cómo reemplazar el archivo `app/assets/sounds/alarm_siren.wav` por un tono personalizado y cómo configurar `app/lib/services/alarm_player_service.dart` para que el usuario pueda elegir entre diferentes tonos de alarma desde `settings_sheet.dart`."*

---

## 🛠️ 4. Cómo Compilar la App Flutter

Si hiciste cambios en el código y quieres generar un nuevo instalador `.apk`:

1. Asegúrate de tener Flutter instalado (`flutter --version`).
2. Abre la terminal en la carpeta `app`:
   ```bash
   cd app
   ```
3. Descarga las librerías:
   ```bash
   flutter pub get
   ```
4. Verifica que el código no tenga errores:
   ```bash
   dart analyze lib
   ```
5. Compila el APK optimizado para arquitectura ARMv8 (64-bit):
   ```bash
   flutter build apk --target-platform android-arm64
   ```
6. El nuevo APK estará en:
   `app/build/app/outputs/flutter-apk/app-release.apk`

---

## 🔬 5. ¿Cómo funciona por dentro la Alerta Máxima?

El gran desafío en Android moderno es evitar que el sistema duerma la aplicación cuando el teléfono tiene la pantalla apagada. Así está resuelto:

1. **Permiso de Ignorar Optimización de Batería (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`)**:
   - Evita que el Doze Mode de Android congele las conexiones de red.
2. **Foreground Service Activo (`flutter_foreground_task`)**:
   - Crea un servicio en primer plano persistente con permisos `FOREGROUND_SERVICE_REMOTE_MESSAGING` y `FOREGROUND_SERVICE_DATA_SYNC` (Android 14+ compatible).
   - Mantiene activos los bloqueos de procesador y antena (`WakeLock` y `WifiLock`).
3. **Despertar Pantalla Bloqueada (Código Nativo en Kotlin)**:
   - En `MainActivity.kt`:
     ```kotlin
     setShowWhenLocked(true)
     setTurnScreenOn(true)
     val wakeLock = powerManager.newWakeLock(
         PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
         "AlertaVecinal:EmergencyWakeLock"
     )
     wakeLock.acquire(15000L)
     keyguardManager.requestDismissKeyguard(this, null)
     ```
4. **Forzado de Volumen Máximo**:
   - Usa `AudioManager.STREAM_ALARM` ajustado programáticamente al 100% de su capacidad en el milisegundo exacto en que llega la emergencia, sobrepasando los perfiles normales de volumen.

---

## 🎨 6. Principios de Diseño Visual

La interfaz de la app y el panel web siguen estrictamente las directrices de **Modo Claro Primero (Swiss Clean / Enterprise)**:
- **Fondos**: Blanco puro (`#FFFFFF`) y porcelana (`#F8FAFC`).
- **Bordes**: Pizarra fina (`#E2E8F0`).
- **Tipografía**: Pizarra profunda (`#0F172A` / `#1E293B`).
- **Colores de Estado**:
  - 🟢 **Verde Salvia (`#68A678`)**: En línea y red protegida.
  - 🟡 **Ámbar (`#E09F67`)**: Reconectando o permiso de batería pendiente.
  - 🔴 **Carmesí Muted (`#DC2626`)**: Alerta de emergencia activa.

---

## 📄 Licencia

Proyecto de código abierto desarrollado para la seguridad y protección de vecinos y comunidades. Libre para usar, modificar y distribuir.
