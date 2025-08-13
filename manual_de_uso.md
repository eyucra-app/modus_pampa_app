# Manual de Uso - Modus Pampa v3

## 📖 Guía Completa del Usuario

Esta guía te ayudará a utilizar todas las funcionalidades de Modus Pampa v3, desde el primer inicio hasta las operaciones avanzadas.

---

## 🚀 Primer Inicio

### 1. Pantalla de Inicio
Al abrir la aplicación por primera vez, verás:
- **Splash Screen**: Verificando conexión con el servidor
- **Estados posibles**:
  - ✅ "Conectado" - Modo online activo
  - ⚠️ "Sin conexión" - Modo offline activo
  - 🔄 "Verificando conexión" - Conectando al servidor

### 2. Inicio de Sesión
**Credenciales por defecto:**
```
Usuario: test@test.com
Contraseña: Test.123#
```

**Proceso:**
1. Ingresa tu email y contraseña
2. Presiona "Iniciar Sesión"
3. Si hay error, verifica las credenciales
4. Una vez autenticado, accedes al menú principal

---

## 🏠 Navegación Principal

### Menú Lateral (Desktop/Web)
- 🏠 **Inicio**: Dashboard principal
- 👥 **Afiliados**: Gestión de miembros
- 📋 **Asistencia**: Control de asistencias
- 💰 **Multas**: Gestión de multas
- 🎯 **Contribuciones**: Aportes y donaciones
- ⚙️ **Configuración**: Ajustes del sistema

### Navegación Inferior (Móvil)
- **Tabs** en la parte inferior para acceso rápido
- **Botón flotante** para acciones principales

---

## 👥 Gestión de Afiliados

### Visualizar Afiliados
1. Ve a la sección **"Afiliados"**
2. **Lista principal** muestra todos los miembros:
   - Foto del afiliado
   - Nombre completo
   - Número de CI
   - Estado de deudas (si tiene pendientes)

### Buscar Afiliados
1. Usa la **barra de búsqueda** en la parte superior
2. **Opciones de búsqueda**:
   - Por nombre
   - Por número de CI
   - Por apellido
3. **Filtros automáticos** mientras escribes

### Crear Nuevo Afiliado
1. Presiona el **botón "+"** (flotante en móvil)
2. **Completa los campos obligatorios**:
   - Nombres
   - Apellidos
   - Cédula de identidad
   - Teléfono
   - Email (opcional)
   - Dirección (opcional)

3. **Agregar fotografía**:
   - Presiona el área de la foto
   - **Opciones**:
     - 📷 Tomar foto (móvil)
     - 🖼️ Seleccionar de galería
     - 🌐 URL de imagen (web)

4. Presiona **"Guardar"**

### Editar Afiliado
1. **Selecciona** un afiliado de la lista
2. Presiona el **ícono de edición** ✏️
3. **Modifica** los campos necesarios
4. **Guardar cambios**

### Ver Detalles del Afiliado
1. **Toca** sobre un afiliado
2. **Información mostrada**:
   - Datos personales completos
   - Historial de asistencias
   - Deudas pendientes
   - Multas aplicadas
   - Contribuciones realizadas

---

## 📋 Sistema de Asistencia

### Crear Lista de Asistencia
1. Ve a **"Asistencia"**
2. Presiona **"Crear Lista"**
3. **Configurar lista**:
   - Nombre de la lista (ej: "Reunión Enero 2025")
   - Fecha y hora
   - Descripción (opcional)
4. Presiona **"Crear"**

### Estados de las Listas
- 🟢 **Iniciada**: Lista activa para registro
- 🟡 **Terminada**: Cerrada para nuevos registros
- 🔴 **Finalizada**: Procesada con multas aplicadas

### Registro de Asistencia

#### En Dispositivos Móviles (Android/iOS)
1. **Abrir lista activa**
2. **Escanear código QR**:
   - La cámara se activa automáticamente
   - Enfoca el código QR del afiliado
   - ✅ Registro automático al detectar código válido

3. **Controles disponibles**:
   - 🔦 Flash on/off
   - 🔄 Cambiar cámara (frontal/trasera)

#### En Windows/Desktop
1. **Abrir lista activa**
2. **Interfaz manual**:
   - Se muestra mensaje: "Registro de Asistencia"
   - Botón prominente **"Registrar Manualmente"**

3. **Proceso manual**:
   - Presiona **"Registrar Manualmente"**
   - Se abre buscador de afiliados
   - Escribe nombre o CI del afiliado
   - Selecciona de la lista de resultados
   - ✅ Confirma el registro

#### En Web
- **Solo registro manual** disponible
- Mismo proceso que Windows/Desktop

### Ver Registros de Asistencia
1. **Abrir lista de asistencia**
2. **Sección "Registrados"** muestra:
   - Nombre del afiliado
   - Hora de registro
   - Estado: "PRESENTE" o "TARDE"
   - Botón de multas (si tiene deudas)

### Gestionar Registros
- **Eliminar registro**: Presiona ❌ junto al registro
- **Ver deudas**: Presiona 💰 si hay deudas pendientes
- **Confirmación**: Todas las eliminaciones requieren confirmación

### Finalizar Lista de Asistencia
1. **Cambiar estado** a "TERMINADA":
   - Presiona **"TERMINAR"** en la barra superior
   - No se permiten más registros

2. **Finalizar lista**:
   - Presiona **"FINALIZAR"**
   - ⚠️ **IMPORTANTE**: Esta acción:
     - Cierra la lista permanentemente
     - Genera multas por falta a los no registrados
     - No se puede deshacer

3. **Confirmación requerida** para finalizar

---

## 💰 Gestión de Multas

### Ver Multas
1. Ve a **"Multas"**
2. **Lista muestra**:
   - Afiliado multado
   - Tipo de multa (Tardanza/Falta)
   - Monto
   - Fecha de la multa
   - Estado de pago

### Tipos de Multas Automáticas
- **Por Tardanza**: Se aplica automáticamente si el registro es después de la hora límite
- **Por Falta**: Se genera al finalizar una lista para quienes no se registraron

### Crear Multa Manual
1. Presiona **"Crear Multa"**
2. **Seleccionar afiliado**:
   - Busca por nombre o CI
   - Selecciona de la lista

3. **Configurar multa**:
   - Monto de la multa
   - Motivo/Descripción
   - Fecha (automática o personalizada)

4. **Guardar multa**

### Gestionar Pagos
1. **Desde el detalle del afiliado**:
   - Ve a un afiliado con deudas
   - Presiona el botón **"Ver deudas"** 💰

2. **Checkout de pagos**:
   - Lista de todas las deudas pendientes
   - Selecciona cuáles pagar
   - Confirma el pago
   - ✅ Las multas se marcan como pagadas

---

## 🎯 Gestión de Contribuciones

### Ver Contribuciones
1. Ve a **"Contribuciones"**
2. **Lista muestra**:
   - Afiliado contribuyente
   - Monto aportado
   - Fecha de la contribución
   - Concepto/Descripción

### Registrar Nueva Contribución
1. Presiona **"Nueva Contribución"**
2. **Seleccionar afiliado**:
   - Busca y selecciona el afiliado

3. **Configurar contribución**:
   - Monto del aporte
   - Concepto (ej: "Donación", "Cuota mensual")
   - Fecha (automática o personalizada)
   - Notas adicionales (opcional)

4. **Guardar contribución**

### Ver Detalles
1. **Toca** una contribución para ver:
   - Información completa del aporte
   - Datos del contribuyente
   - Historial relacionado

---

## 📊 Reportes y PDFs

### Generar Reporte de Asistencia
1. **Desde una lista de asistencia**:
   - Abre la lista deseada
   - Presiona el ícono **PDF** 📄 en la barra superior

2. **Contenido del reporte**:
   - Información de la lista
   - Listado de presentes
   - Listado de tardanzas
   - Listado de faltas
   - Resumen estadístico

3. **Visualizar y compartir**:
   - El PDF se abre en visor integrado
   - Opciones para compartir o descargar

### Reportes Disponibles
- **Asistencia**: Por lista específica
- **Multas**: Resumen financiero (futuro)
- **Contribuciones**: Historial de aportes (futuro)

---

## ⚙️ Configuración

### Acceder a Configuración
1. Ve al menú **"Configuración"**
2. **Opciones disponibles**:
   - Configuración de multas
   - URL del backend
   - Operaciones pendientes
   - Información del sistema

### Configurar Montos de Multas
1. **Multa por Tardanza**:
   - Ajusta el monto automático
   - Valor por defecto: $5.00

2. **Multa por Falta**:
   - Ajusta el monto automático
   - Valor por defecto: $20.00

3. **Guardar cambios**: Los nuevos montos se aplican a futuras multas

### Configurar URL del Backend
1. **Cambiar servidor**:
   - Modifica la URL si es necesario
   - Por defecto: `https://modus-pampa-backend-oficial.onrender.com`

2. **Aplicar cambios**: Reinicia la app para que tome efecto

### Operaciones Pendientes
1. **Ver cola de sincronización**:
   - Lista de operaciones esperando conexión
   - Útil en modo offline

2. **Forzar sincronización**:
   - Presiona **"Sincronizar"** para forzar el proceso
   - Solo funciona con conexión activa

---

## 🌐 Modos de Conectividad

### Modo Online
**Características:**
- ✅ Sincronización automática cada 30 segundos
- ✅ Datos en tiempo real con WebSocket
- ✅ Backup automático en el servidor
- ✅ Todas las funcionalidades disponibles

**Indicador:** 🟢 "Conectado" en la barra superior

### Modo Offline
**Características:**
- ✅ Funcionalidad completa sin internet
- ✅ Datos guardados localmente
- ✅ Cola de operaciones pendientes
- ⏳ Sincronización automática al recuperar conexión

**Indicador:** 🔴 "Sin conexión" en la barra superior

### Transición Entre Modos
1. **Online → Offline**:
   - Detección automática de pérdida de conexión
   - Notificación visual del cambio
   - Todas las operaciones se guardan localmente

2. **Offline → Online**:
   - Detección automática de conexión restaurada
   - Sincronización automática de datos pendientes
   - Actualización con datos del servidor

---

## 🔍 Búsqueda y Filtros

### Búsqueda Global
**Disponible en:**
- Lista de afiliados
- Registro manual de asistencia
- Selección para multas
- Selección para contribuciones

**Funcionalidad:**
- Búsqueda en tiempo real
- Filtros por nombre, apellido, CI
- Resultados instantáneos mientras escribes

### Filtros Avanzados
**Por estado de deudas:**
- Afiliados con deudas pendientes
- Afiliados al día

**Por fecha:**
- Multas por rango de fechas
- Contribuciones por período

---

## 🛠️ Solución de Problemas Comunes

### 1. No Puedo Iniciar Sesión
**Verificar:**
- ✅ Credenciales correctas: `test@test.com` / `Test.123#`
- ✅ Conexión a internet activa
- ✅ Estado del servidor (indicador de conexión)

**Solución:**
- Verifica la URL del backend en Configuración
- Intenta en modo offline si hay datos locales

### 2. QR No Funciona
**En Windows/Desktop:**
- ✅ **Comportamiento esperado**: QR no disponible
- ✅ Usa **"Registrar Manualmente"**

**En Móvil:**
- Verifica permisos de cámara
- Asegúrate de que el código QR sea válido
- Intenta con mejor iluminación

### 3. Datos No Se Sincronizan
**Verificar:**
- Estado de conexión (indicador superior)
- Operaciones pendientes en Configuración

**Solución:**
- Espera a tener conexión estable
- Fuerza sincronización desde Configuración
- Verifica URL del backend

### 4. Aplicación Muy Lenta
**Causas comunes:**
- Base de datos local muy grande
- Conexión lenta al servidor

**Solución:**
- Reinicia la aplicación
- Verifica la calidad de conexión
- Usa modo offline para operaciones locales

### 5. Error al Cargar Imágenes
**Verificar:**
- Conexión a internet para imágenes de Cloudinary
- Permisos de cámara/galería en móvil

**Solución:**
- Intenta recargar la pantalla
- Verifica permisos de la app
- Usa imágenes de menor tamaño

---

## 📱 Diferencias por Plataforma

### Funcionalidades por Dispositivo

| Característica | Móvil | Desktop | Web |
|----------------|-------|---------|-----|
| Escaneo QR | ✅ Cámara | ❌ Manual | ❌ Manual |
| Carga de fotos | ✅ Cámara/Galería | ✅ Archivos | ✅ Archivos |
| Modo offline | ✅ Completo | ✅ Completo | ✅ Completo |
| Reportes PDF | ✅ Compartir | ✅ Descargar | ✅ Descargar |
| Notificaciones | 🔄 Futuro | ❌ No | ❌ No |

### Navegación por Plataforma

**Móvil:**
- Navegación con tabs inferiores
- Menú hamburguesa para opciones
- Gestos de deslizamiento

**Desktop/Windows:**
- Menú lateral siempre visible
- Atajos de teclado disponibles
- Interfaz optimizada para mouse

**Web:**
- Interfaz adaptativa
- Compatible con todos los navegadores
- Funcionalidad completa

---

## 💡 Consejos y Mejores Prácticas

### Para Administradores
1. **Gestión de listas**:
   - Crea listas con nombres descriptivos
   - Finaliza listas solo cuando estés seguro
   - Revisa deudas antes de checkout

2. **Registro de afiliados**:
   - Mantén fotos actualizadas
   - Verifica datos de contacto
   - Usa códigos QR cuando sea posible

3. **Sincronización**:
   - Verifica conexión antes de operaciones críticas
   - Revisa operaciones pendientes regularmente
   - Mantén backup de datos importantes

### Para Usuarios Finales
1. **Registro de asistencia**:
   - Llega temprano para evitar multas
   - Ten tu código QR listo en móviles
   - Reporta problemas de registro inmediatamente

2. **Gestión personal**:
   - Revisa tus deudas regularmente
   - Mantén tus datos actualizados
   - Conserva comprobantes de pagos

### Mantenimiento
1. **Rendimiento**:
   - Reinicia la app semanalmente
   - Mantén la app actualizada
   - Libera espacio de almacenamiento

2. **Seguridad**:
   - No compartas credenciales
   - Cierra sesión en dispositivos compartidos
   - Reporta accesos no autorizados

---

## 📞 Soporte y Ayuda

### Cuando Necesites Ayuda
1. **Consulta este manual** primero
2. **Verifica la sección de problemas comunes**
3. **Revisa los logs de la aplicación**
4. **Contacta al administrador del sistema**

### Información del Sistema
**Versión actual:** 1.0.0+1  
**Plataformas soportadas:** Web, Windows, Android, iOS  
**Última actualización:** Agosto 2025

### Reportar Problemas
**Incluye siempre:**
- Plataforma utilizada (Web/Windows/Móvil)
- Pasos para reproducir el problema
- Mensaje de error (si aparece)
- Hora aproximada del incidente

---

*Este manual se actualiza constantemente. Para la versión más reciente, consulta la documentación oficial del proyecto.*