# Modus Pampa v3

Una aplicación Flutter completa para gestión de afiliados, asistencia y administración organizacional con soporte multiplataforma (Web, Windows, Android, iOS).

## 📱 Características Principales

### 🏢 Gestión de Afiliados
- **Registro completo**: Datos personales, fotografías, información de contacto
- **Búsqueda avanzada**: Filtros por nombre, CI, estado de membresía
- **Gestión de deudas**: Seguimiento automático de multas y contribuciones
- **Carga de imágenes**: Integración con Cloudinary para almacenamiento

### 📋 Sistema de Asistencia
- **Listas dinámicas**: Creación y gestión de listas de asistencia
- **Registro QR**: Escaneo de códigos QR en dispositivos móviles
- **Registro manual**: Interfaz simplificada para Windows/Desktop
- **Estados automáticos**: Presente, tardanza con multa automática
- **Reportes PDF**: Generación de reportes de asistencia

### 💰 Gestión Financiera
- **Multas automáticas**: Por tardanza y faltas según configuración
- **Contribuciones**: Registro y seguimiento de aportes
- **Checkout de pagos**: Interfaz para liquidación de deudas
- **Reportes financieros**: Seguimiento de ingresos y pendientes

### ⚙️ Configuración Avanzada
- **Sincronización automática**: Datos en tiempo real con backend
- **Modo offline**: Funcionamiento sin conexión con sincronización posterior
- **Configuración remota**: Ajustes centralizados desde el backend
- **WebSocket**: Comunicación en tiempo real

## 🚀 Tecnologías

### Framework y Arquitectura
- **Flutter 3.7.2+**: Desarrollo multiplataforma
- **Clean Architecture**: Separación de responsabilidades
- **Riverpod 2.x**: Gestión de estado reactiva
- **GoRouter**: Navegación declarativa

### Base de Datos
- **SQLite**: Almacenamiento local
- **sqflite**: Para Android/iOS
- **sqflite_ffi**: Para Windows/Linux/MacOS
- **sqflite_ffi_web**: Para Web

### Conectividad y Sincronización
- **Dio**: Cliente HTTP avanzado
- **WebSocket**: Comunicación en tiempo real
- **Connectivity Plus**: Detección de conectividad
- **Sincronización bidireccional**: Pull/Push automático

### Multimedia y UI
- **QR Code Scanner Plus**: Escaneo QR en móviles
- **Camera**: Acceso a cámara del dispositivo
- **Cached Network Image**: Carga optimizada de imágenes
- **PDF Generation**: Reportes en formato PDF
- **Google Fonts**: Tipografías personalizadas

## 🛠️ Instalación y Configuración

### Prerrequisitos
```bash
flutter --version  # Debe ser 3.7.2 o superior
```

### Configuración del Proyecto
```bash
# Clonar el repositorio
git clone <repository-url>
cd modus_pampa_v3

# Instalar dependencias
flutter pub get

# Generar código (providers, modelos)
flutter packages pub run build_runner build
```

### Configuración de Base de Datos
La aplicación inicializa automáticamente la base de datos SQLite en el primer arranque. Las migraciones se ejecutan automáticamente.

### Configuración del Backend
Por defecto, la aplicación se conecta a:
```
https://modus-pampa-backend-oficial.onrender.com
```

Para cambiar la URL del backend:
1. Ir a **Configuración** en la aplicación
2. Modificar **URL del Backend**
3. Reiniciar la aplicación

## 📱 Ejecución por Plataforma

### Web
```bash
flutter run -d chrome
```
**Características específicas:**
- Funcionalidad completa de gestión
- Registro manual de asistencia
- Sincronización automática

### Windows
```bash
flutter run -d windows
```
**Características específicas:**
- Interfaz optimizada para escritorio
- Registro manual en lugar de QR
- Todas las funcionalidades administrativas

### Android/iOS
```bash
flutter run -d <device-id>
```
**Características específicas:**
- Escaneo QR para asistencia
- Acceso completo a cámara
- Notificaciones push (futuro)

## 🌐 Despliegue en Vercel

### Aplicación Desplegada
**URL Principal**: https://modus-pampa-v3.vercel.app  
**Credenciales de acceso**:
- Usuario: `test@test.com`
- Contraseña: `Test.123#`

### Despliegue Automático desde GitHub

1. **Conectar repositorio a Vercel:**
   - Ve a [vercel.com](https://vercel.com) e inicia sesión
   - Clic en "New Project"
   - Conecta tu cuenta GitHub
   - Selecciona el repositorio `modus_pampa_app`
   - Vercel detectará automáticamente la configuración

2. **Configuración automática:**
   - Build Command: `chmod +x install.sh && ./install.sh && ./flutter/bin/flutter build web --release`
   - Output Directory: `build/web`
   - Install Command: Personalizado con Flutter

3. **Deploy automático:**
   - Cada push a `main` despliega automáticamente
   - Build toma aproximadamente 2-3 minutos
   - SSL y CDN incluidos automáticamente

### Despliegue Manual con Vercel CLI

```bash
# Instalar Vercel CLI
npm install -g vercel

# Login en Vercel
vercel login

# Deploy en producción
vercel --prod --yes
```

### Archivos de Configuración

- **`vercel.json`**: Configuración de build y rutas
- **`install.sh`**: Script de instalación de Flutter
- **`package.json`**: Metadata del proyecto
- **`.vercelignore`**: Archivos excluidos del deploy

### Características del Deploy

- ✅ **PWA Ready**: Instalable como app nativa
- ✅ **Offline Support**: Service Worker incluido
- ✅ **Responsive**: Optimizado para todos los dispositivos
- ✅ **SSL**: Certificado automático
- ✅ **CDN Global**: Distribución mundial
- ✅ **Build Optimizado**: Tree-shaking y compresión

## 🏗️ Arquitectura del Proyecto

```
lib/
├── core/                    # Núcleo de la aplicación
│   ├── config/             # Configuraciones (tema, constantes)
│   ├── database/           # Helper de base de datos SQLite
│   ├── navigation/         # Configuración de rutas
│   └── providers/          # Providers globales (Dio, conectividad)
│
├── data/                   # Capa de datos
│   ├── models/            # Modelos de datos (User, Affiliate, etc.)
│   └── repositories/      # Repositorios para acceso a datos
│
├── features/              # Características por módulos
│   ├── affiliates/       # Gestión de afiliados
│   ├── attendance/       # Sistema de asistencia
│   ├── auth/            # Autenticación y autorización
│   ├── contributions/   # Gestión de contribuciones
│   ├── fines/          # Sistema de multas
│   ├── reports/        # Generación de reportes
│   └── settings/       # Configuraciones y sincronización
│
├── shared/               # Componentes compartidos
│   └── widgets/         # Widgets reutilizables
│
├── app.dart             # Configuración principal de la app
└── main.dart           # Punto de entrada
```

### Patrón por Feature
Cada feature sigue la estructura:
```
feature_name/
├── providers/           # Estado y lógica de negocio
├── screens/            # Pantallas de la UI
├── widgets/           # Componentes específicos
└── services/         # Servicios especializados
```

## 🔐 Autenticación

### Credenciales por Defecto
```
Usuario: test@test.com
Contraseña: Test.123#
```

### Roles de Usuario
- **Admin**: Acceso completo a todas las funcionalidades
- **User**: Acceso limitado a consultas y operaciones básicas

### Seguridad
- Contraseñas hasheadas con SHA256
- Sesiones persistentes con tokens
- Validación de permisos por rol

## 🌐 Sincronización y Conectividad

### Modos de Operación

#### Modo Online
- Sincronización automática cada 30 segundos
- WebSocket para actualizaciones en tiempo real
- Backup automático en la nube

#### Modo Offline
- Funcionalidad completa sin internet
- Cola de operaciones pendientes
- Sincronización automática al recuperar conexión

### Detección de Conectividad
```dart
// La app detecta automáticamente:
- Conexión WiFi
- Datos móviles
- Cambios de estado de red
- Disponibilidad del backend
```

## 📊 Base de Datos

### Esquema Principal
- **users**: Usuarios del sistema
- **affiliates**: Registro de afiliados
- **attendance_lists**: Listas de asistencia
- **attendance_records**: Registros individuales
- **fines**: Sistema de multas
- **contributions**: Contribuciones y aportes
- **pending_operations**: Cola de sincronización
- **app_settings**: Configuraciones locales

### Migraciones
Las migraciones se ejecutan automáticamente:
```dart
// Versión actual de DB: 8
// Migraciones incluidas:
- Creación de tablas iniciales
- Añadir campos de sincronización
- Optimizaciones de rendimiento
- Índices para búsquedas
```

## 🎨 Configuración de UI

### Tema y Colores
```dart
// Esquema de colores personalizable
Primary: Material 3 Dynamic Colors
Secondary: Complementario automático
Background: Modo claro/oscuro (automático)
```

### Responsive Design
- **Mobile**: Navegación bottom tabs
- **Desktop**: Sidebar navigation
- **Web**: Interfaz adaptativa

## 📱 Funcionalidades por Plataforma

| Característica | Web | Windows | Android | iOS |
|----------------|-----|---------|---------|-----|
| Gestión Afiliados | ✅ | ✅ | ✅ | ✅ |
| **Asistencia QR** | ✅ | ❌ | ✅ | ✅ |
| Registro Manual | ✅ | ✅ | ✅ | ✅ |
| Reportes PDF | ✅ | ✅ | ✅ | ✅ |
| Carga Imágenes | ✅ | ✅ | ✅ | ✅ |
| Sincronización | ✅ | ✅ | ✅ | ✅ |
| Modo Offline | ✅ | ✅ | ✅ | ✅ |

### 📱 Detalles del Sistema QR

#### **Plataformas con QR Scanner**
- **✅ Web**: `qr_code_scanner_plus` con acceso a cámara web
- **✅ Android**: `qr_code_scanner_plus` con cámara nativa
- **✅ iOS**: `qr_code_scanner_plus` con cámara nativa

#### **Controles de Cámara QR**
- **🔦 Flash**: Toggle on/off en todas las plataformas QR
- **🔄 Cambiar Cámara**: Frontal/Trasera disponible
- **🎯 Overlay**: Marco visual unificado para escaneo

#### **Plataformas Solo Manual**
- **❌ Windows**: Interfaz optimizada de registro manual
- **❌ macOS**: Interfaz optimizada de registro manual  
- **❌ Linux**: Interfaz optimizada de registro manual

#### **Funcionalidad Híbrida**
Todas las plataformas con QR también incluyen registro manual como respaldo:
- **Web + Móvil**: QR Scanner + Botón "Registrar Manualmente"
- **Desktop**: Solo "Registrar Manualmente" (interfaz optimizada)

## 🔧 Configuración Avanzada

### Variables de Entorno
```dart
// En lib/core/config/constants.dart
static const String defaultBackendUrl = 
  'https://modus-pampa-backend-oficial.onrender.com';
```

### Configuración de Cloudinary
```dart
// Para carga de imágenes
cloudName: 'your-cloud-name'
apiKey: 'your-api-key'
apiSecret: 'your-api-secret'
```

### Timeouts y Reintentos
```dart
// Configuración de red
connectTimeout: 30 segundos
receiveTimeout: 30 segundos
sendTimeout: 30 segundos
maxRetries: 3
```

## 🐛 Solución de Problemas

### Problemas Comunes

#### 1. Error de Conexión al Backend
```bash
# Verificar:
- Conectividad a internet
- URL del backend en configuración
- Estado del servidor backend
```

#### 2. Problemas de Sincronización
```bash
# Solución:
1. Ir a Configuración > Operaciones Pendientes
2. Verificar operaciones en cola
3. Forzar sincronización manual
```

#### 3. QR No Funciona en Windows
```bash
# Esperado:
Windows usa registro manual por diseño
Usar botón "Registrar Manualmente"
```

#### 4. Imágenes No Cargan
```bash
# Verificar:
- Configuración de Cloudinary
- Permisos de cámara/galería
- Conectividad a internet
```

### Logs y Debugging
```bash
# Para logs detallados:
flutter run --verbose

# Para logs de red:
# Verificar consola para mensajes con 🔧 🚀 ✅ ❌
```

## 🤝 Contribución

### Estructura de Commits
```bash
git commit -m "feat: descripción del feature"
git commit -m "fix: descripción del bug fix"
git commit -m "docs: actualización de documentación"
```

### Desarrollo
```bash
# Ejecutar tests
flutter test

# Análisis de código
flutter analyze

# Formateo de código
flutter format .
```

## 📄 Licencia

Este proyecto es propietario y confidencial. Todos los derechos reservados.

## 📞 Soporte

Para soporte técnico o consultas:
- Revisar logs de la aplicación
- Verificar configuración de red
- Contactar al equipo de desarrollo

---

**Versión**: 1.0.0+1  
**Última actualización**: Agosto 2025  
**Plataformas soportadas**: Web, Windows, Android, iOS