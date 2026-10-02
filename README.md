# 🚨 Alerta Vecinal - Plantilla Base para Alarma Comunitaria

> **Plantilla de código abierto (Starter Kit)** diseñada para que cualquier persona o comunidad pueda crear, personalizar y compilar su propia aplicación de **Alerta Vecinal y Botón de Pánico**, incluso si no tienes mucha experiencia programando.
> 
> Está lista para abrirse en editores con Inteligencia Artificial (**Cursor, Windsurf, Claude, ChatGPT, Copilot**) para que puedas pedirle a la IA los cambios que quieras y compilar tu propio archivo `.apk`.

---

## 🎯 ¿Qué hace este proyecto?

Resuelve el problema de las emergencias o robos en vecindarios donde los mensajes de WhatsApp no despiertan a nadie:
1. **Un vecino presiona el botón de pánico** en su teléfono.
2. La señal viaja a un servidor central en tiempo real por **WebSocket** (sin depender de Firebase ni servicios de pago).
3. **Todos los teléfonos de los vecinos suscritos encienden su pantalla**, suben el volumen al 100%, reproducen una sirena de emergencia penetrante y vibran con fuerza, **incluso si el teléfono está bloqueado o en silencio**.

---

## 🧭 ¿No sabes mucho de programación? Empieza aquí

Este proyecto está dividido en dos partes muy sencillas:

```text
alerta-vecinal/
├── app/        👉 La aplicación para los teléfonos Android (hecha en Flutter)
└── server/     👉 El servidor central que conecta a todos los vecinos (hecho en Node.js)
```

No necesitas tocar código complejo a mano. Sigue estos 3 pasos:

---

## 🚀 PASO 1: Levantar tu propio Servidor (100% Gratis)

Para que los teléfonos de tus vecinos puedan comunicarse entre sí, necesitas tener el servidor corriendo. Tienes dos opciones gratuitas:

### Opción A: En la Nube (24/7 Gratis con Render.com) — *Recomendada si no quieres dejar tu PC encendida*
1. Crea una cuenta gratuita en [render.com](https://render.com/).
2. Haz clic en el botón **New +** y selecciona **Web Service**.
3. Conecta este repositorio de GitHub (o tu fork).
4. En las opciones de configuración escribe:
   - **Root Directory**: `server`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
   - **Plan**: `Free`
5. Render te entregará una dirección pública gratuita similar a:  
   `https://mi-alerta-vecinal.onrender.com`
6. ¡Esa es tu dirección! En la app de los vecinos se usará:  
   `wss://mi-alerta-vecinal.onrender.com`

---

### Opción B: En tu propia PC con Cloudflare Tunnel (100% Gratis) — *Ultra rápido y sin abrir puertos en el router*
Si tienes un computador, notebook o Raspberry Pi en tu casa:
1. Instala Node.js desde [nodejs.org](https://nodejs.org/).
2. Abre la terminal en la carpeta `server` y ejecuta:
   ```bash
   npm install
   node server.js
   ```
   Tu servidor estará funcionando en el puerto `7866` (`http://localhost:7866`).
3. Para que los vecinos se conecten desde la calle o con datos móviles (4G/5G), crea un túnel gratis en [Cloudflare Zero Trust](https://dash.cloudflare.com/):
   - Ve a **Networks** > **Tunnels** > **Create Tunnel**.
   - Agrega un **Public Hostname** (ej. `vecinos.tudominio.com`).
   - Apunta el servicio a: `HTTP` en `localhost:7866`.
   - La dirección para la app será: `wss://vecinos.tudominio.com`.

---

### Opción C: Solo en la Red Local WiFi de tu casa
Si solo quieres hacer pruebas con teléfonos conectados al mismo WiFi:
```bash
cd server
npm install
node server.js
```
El servidor te dirá en pantalla la IP de tu PC (ejemplo: `ws://192.168.1.50:7866`).

---

## 📱 PASO 2: Personalizar y Compilar tu propio APK

Para que cada vecino tenga la app en su teléfono Android, vas a generar tu propio instalador `.apk`.

### Requisitos en tu PC:
1. Tener instalado [Flutter](https://docs.flutter.dev/get-started/install) (es gratuito y de código abierto).
2. Tener Android Studio o el Android SDK instalado.

### 1. Cambiar la dirección del servidor por defecto:
Abre el archivo `app/lib/services/alarm_sync_service.dart` y en la línea 63 pon tu propia dirección:
```dart
String _serverUrl = 'wss://mi-alerta-vecinal.onrender.com'; // O la IP de tu servidor
```

### 2. Compilar tu APK:
Abre la terminal en la carpeta `app` y ejecuta estos 3 comandos:
```bash
cd app
flutter pub get
flutter build apk --target-platform android-arm64
```
¡Listo! Cuando termine, tu archivo instalador estará en:  
📂 `app/build/app/outputs/flutter-apk/app-release.apk`

Copia ese archivo a tu teléfono o compártelo por WhatsApp con tus vecinos para que lo instalen.

---

## ⚠️ PASO OBLIGATORIO AL INSTALAR EN EL TELÉFONO

Cuando tú o tus vecinos abran la app por primera vez, verán un cartel amarillo:
> **Optimización de Batería Activa**  
> *Pulsa en "Excluir de Optimización" y selecciona Permitir*.

👉 **¿Por qué es indispensable?**  
Android normalmente "duerme" las aplicaciones y apaga las antenas de red cuando la pantalla está bloqueada para ahorrar batería. Al darle este permiso, la app puede mantener despierta la conexión en segundo plano y encender la pantalla en el segundo exacto en que alguien toque la alarma.

---

## 🤖 PASO 3: Cómo Programar y Modificar este Proyecto con IA

Esta plantilla está pensada para que la abras en un editor con Inteligencia Artificial como **Cursor**, **Windsurf**, **VS Code con Claude / Copilot**, o uses **ChatGPT / Claude Web**.

### Mapa de Archivos (Para que sepas dónde está cada cosa)

```text
alerta-vecinal/
│
├── server/                                # SERVIDOR CENTRAL
│   └── server.js                          # Controla los mensajes WebSocket y el panel web
│
└── app/                                   # APP MÓVIL (FLUTTER)
    ├── android/
    │   ├── app/src/main/AndroidManifest.xml   # Permisos de Android (batería, volumen, pantalla)
    │   └── app/src/main/kotlin/.../MainActivity.kt # Código nativo para encender pantalla y subir volumen
    │
    ├── assets/sounds/
    │   └── alarm_siren.wav                # Sonido de la sirena de emergencia
    │
    └── lib/
        ├── main.dart                      # Inicio de la app
        ├── models/alert_model.dart        # Qué datos viajan en la alarma (quién la envió, hora, motivo)
        ├── services/
        │   ├── alarm_sync_service.dart    # Conexión con el servidor y reconexión automática
        │   ├── alarm_player_service.dart  # Reproducción de la sirena al 100% y vibración
        │   └── native_alert_service.dart  # Comunicación con las funciones nativas de Android
        ├── screens/
        │   ├── home_screen.dart           # Pantalla principal con el Botón de Pánico
        │   ├── active_alert_dialog.dart   # Pantalla que se muestra cuando la alarma está sonando
        │   └── settings_sheet.dart        # Menú para cambiar el nombre de la casa o el servidor
        └── theme/app_theme.dart           # Colores y estilo visual (Modo Claro limpio y sobrio)
```

---

### 💬 Prompts para Copiar y Pegar en la IA

Puedes copiar y pegar estos textos tal cual en tu IA para que haga los cambios por ti:

#### 🟢 Para cambiar el nombre y diseño para tu condominio o barrio:
> *"Quiero personalizar esta app para mi comunidad llamada 'Condominio Los Alerces'. Revisa `app/lib/screens/home_screen.dart` y `app/lib/theme/app_theme.dart` y actualiza los títulos, el nombre en la barra superior y ajusta los colores de acento para que coincidan con la identidad de mi comunidad."*

#### 🟢 Para agregar envío de ubicación GPS en la alarma:
> *"Agrega soporte de geolocalización. Cuando un vecino presione el botón de pánico en `home_screen.dart`, obtén las coordenadas GPS del teléfono usando el paquete `geolocator` y envíalas dentro de `AlertModel`. Luego en `active_alert_dialog.dart` muestra un botón que diga 'Ver Ubicación en Google Maps'."*

#### 🟢 Para crear diferentes tipos de emergencia (Robo, Fuego, Médico):
> *"Modifica la app para que al presionar el botón de pánico permita elegir entre tres opciones: 1. Robo / Sospechosos, 2. Incendio, 3. Urgencia Médica. Actualiza `AlertModel`, `server.js` y la pantalla de alarma `active_alert_dialog.dart` para que muestre el color e ícono correspondiente a cada tipo."*

#### 🟢 Para cambiar el sonido de la sirena:
> *"Quiero cambiar el sonido de la alarma. Explícame cómo reemplazar `app/assets/sounds/alarm_siren.wav` o cómo modificar `alarm_player_service.dart` para permitir seleccionar entre 3 sonidos diferentes desde la pantalla de configuración."*

---

## 🔬 ¿Cómo logra la app sonar tan fuerte con el teléfono bloqueado?

Por si tienes curiosidad de cómo está programado por dentro:
1. **Canal Nativo en Kotlin (`MainActivity.kt`)**: Utiliza `setShowWhenLocked(true)`, `setTurnScreenOn(true)` y `PowerManager.FULL_WAKE_LOCK` para obligar al teléfono a iluminar la pantalla aunque tenga patrón o huella dactilar.
2. **Volumen de Alarma Forzado**: Utiliza el flujo `STREAM_ALARM` del sistema y lo eleva al 100% programáticamente al recibir la alerta, ignorando si el teléfono estaba en vibrador o volumen bajo.
3. **Servicio en Primer Plano (`flutter_foreground_task`)**: Mantiene un proceso activo permanente con un candado de CPU y candado de WiFi (`allowWakeLock` y `allowWifiLock`), evitando que Android mate la conexión.

---

## 📄 Licencia

Este proyecto está liberado bajo la licencia **[WTFPL](LICENSE)** (*Do What The Fuck You Want To Public License*).  
Puedes hacer absolutamente lo que quieras con el código: usarlo, modificarlo, redistribuirlo o adaptarlo para cualquier comunidad.

