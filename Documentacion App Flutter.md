# Documentación Exhaustiva de la Aplicación "Modus Pampa v3"

## 1\. Resumen y Arquitectura General

### 1.1. Propósito de la Aplicación

Modus Pampa v3 es un sistema de gestión integral diseñado para una asociación o sindicato. Su propósito principal es digitalizar y automatizar la administración de sus miembros (afiliados), las finanzas y los eventos. La aplicación permite:

  * **Gestión de Afiliados:** Mantener un registro detallado de los miembros, incluyendo datos personales, de contacto, fotografías y estado financiero.
  * **Control Financiero:** Administrar los aportes o cuotas de los afiliados y registrar multas por diversas infracciones (ej. retrasos, faltas).
  * **Gestión de Asistencia:** Crear y gestionar listas de asistencia para eventos o reuniones, registrando la presencia de los afiliados mediante escaneo de QR o de forma manual.
  * **Sincronización Offline-First:** Funcionar de manera efectiva sin conexión a internet, guardando todas las operaciones localmente y sincronizándolas con un servidor central cuando la conexión se restablece.
  * **Generación de Reportes:** Crear informes en PDF detallados sobre el estado financiero de un afiliado, su historial de aportes, multas y asistencias.
  * **Control de Acceso:** Ofrecer diferentes niveles de acceso: un modo "invitado" para que los afiliados consulten su propia información y un modo administrativo con plenos poderes de gestión.

### 1.2. Arquitectura del Proyecto

La aplicación sigue una **arquitectura limpia y modular**, organizada por funcionalidades (features). Esta estructura promueve la escalabilidad, el mantenimiento y la separación de responsabilidades.

  * `lib/`: Directorio raíz del código Dart.
      * `core/`: Contiene la lógica central y transversal de la aplicación.
          * `config/`: Constantes (`constants.dart`), temas (`theme.dart`) y configuración general.
          * `database/`: El helper de la base de datos (Singleton `DatabaseHelper`).
          * `navigation/`: La configuración de la navegación con `GoRouter` (`app_router.dart`).
          * `providers/`: Providers de Riverpod de alcance global (ej. `dioProvider`, `connectivity_provider`).
      * `data/`: Se encarga de la capa de datos.
          * `models/`: Define las clases del modelo de datos (ej. `Affiliate`, `Fine`, `Contribution`). Son estructuras de datos inmutables con métodos de serialización (`toMap`, `fromMap`).
          * `repositories/`: Contiene la lógica de acceso a datos. Actúan como un puente entre los providers y las fuentes de datos (base de datos local y API remota). Son responsables de la lógica offline/online.
      * `features/`: El corazón de la aplicación, donde cada funcionalidad es un módulo autocontenido.
          * `auth/`, `affiliates/`, `attendance/`, etc.: Cada carpeta contiene:
              * `providers/`: Los `StateNotifier` y `FutureProvider` específicos de la funcionalidad, que gestionan el estado y la lógica de negocio.
              * `screens/`: Los widgets que componen las pantallas de la UI.
              * `widgets/`: Widgets reutilizables dentro de esa funcionalidad.
      * `shared/`: Contiene widgets y utilidades que se reutilizan a lo largo de varias funcionalidades.
          * `utils/`: Clases de utilidad como `Validators`.
          * `widgets/`: Widgets comunes como el `SideMenu`.

### 1.3. Gestión de Estado

La aplicación utiliza **Flutter Riverpod** como su solución de gestión de estado. Esta elección permite un manejo de estado desacoplado, reactivo y robusto.

  * **`Provider`**: Utilizado para proveer instancias inmutables de clases, como repositorios o servicios. Ejemplo: `affiliateRepositoryProvider` provee una instancia de `AffiliateRepository`.
  * **`StateProvider`**: Para estados simples y síncronos, como valores booleanos, enums o strings. Ejemplo: `guestAffiliateProvider` mantiene el estado del afiliado invitado actual.
  * **`FutureProvider`**: Ideal para operaciones asíncronas de una sola vez, como obtener una lista de datos de la base de datos. La UI puede reaccionar a los estados `data`, `loading`, y `error`. Ejemplo: `affiliateListProvider` (ahora parte de un `StateNotifier`) o `pendingContributionsProvider`.
  * **`StateNotifierProvider`**: Es la pieza central para la lógica de negocio y estados más complejos.
      * **Propósito**: Los `StateNotifier` (ej. `AffiliateOperationNotifier`, `AuthNotifier`) contienen los métodos que modifican el estado de la aplicación (ej. `createAffiliate`, `login`).
      * **Funcionamiento**: Las pantallas invocan los métodos del notifier (`ref.read(provider.notifier).myMethod()`). El notifier ejecuta la lógica, actualiza su estado interno (`state = ...`), y la UI que está observando (`ref.watch(provider)`) se reconstruye automáticamente para reflejar el nuevo estado.
      * **Interacción**: Los notifiers interactúan con los repositorios para realizar operaciones de datos y luego actualizan el estado para que la UI reaccione. También pueden invalidar otros providers (`_ref.read(affiliateListNotifierProvider.notifier).loadAffiliates()`) para forzar una recarga de datos.

### 1.4. Flujo de Datos

El flujo de datos sigue un patrón unidireccional claro y predecible, típico de arquitecturas limpias.

**Flujo de Escritura/Acción (Usuario -\> Backend):**

1.  **UI (Pantalla)**: Un usuario interactúa con un widget (ej. presiona un botón de "Guardar" en `AffiliateFormScreen`).
2.  **Llamada al Provider**: El evento `onPressed` llama a un método del `StateNotifier` correspondiente usando `ref.read(affiliateOperationProvider.notifier).createAffiliate(affiliate)`.
3.  **Lógica de Negocio (Notifier)**: El `AffiliateOperationNotifier` recibe la llamada. Realiza validaciones y prepara los datos.
4.  **Repositorio**: El notifier invoca el método del repositorio apropiado (`_repository.createAffiliate(affiliate)`).
5.  **Capa de Datos (Repository)**:
      * El `AffiliateRepository` intenta la operación en la **base de datos local (SQLite)** primero, asegurando la persistencia inmediata (`db.insert`).
      * Verifica la conexión a internet con `_isConnected()`.
      * Si hay conexión, intenta enviar los datos al **Backend API** a través de `_sendToBackend('/affiliates', OperationType.CREATE, affiliate.toMap())`.
      * Si la llamada a la API falla o no hay conexión, crea una `PendingOperation` y la guarda en la base de datos local a través de `_pendingOpRepo.createPendingOperation(op)`.
6.  **Actualización de Estado**: El notifier actualiza su estado para reflejar el resultado (`state = AffiliateOperationSuccess(...)` o `AffiliateOperationError(...)`).
7.  **Feedback en la UI**: La pantalla, que está escuchando los cambios con `ref.listen`, muestra un `SnackBar` de éxito o error. Además, la UI se reconstruye si depende del estado (`ref.watch`).

**Flujo de Lectura (Datos -\> UI):**

1.  **UI (Pantalla)**: El método `build` de una pantalla utiliza `ref.watch(affiliateListNotifierProvider)` para obtener el estado de la lista de afiliados.
2.  **Provider (`StateNotifier`)**: El provider obtiene los datos llamando al repositorio (`_repository.getAllAffiliates()`).
3.  **Repositorio**: El repositorio consulta directamente la **base de datos local (SQLite)** para obtener los datos (`db.query(...)`).
4.  **Estado a UI**: Los datos fluyen de vuelta al provider, que los envuelve en un estado (`AsyncData`, `AsyncLoading`, `AsyncError`).
5.  **Renderizado en UI**: La pantalla usa un bloque `.when()` para construir la UI correspondiente a cada estado, mostrando un loader, una lista de datos o un mensaje de error.

-----

## 2\. Análisis de Dependencias (Archivo pubspec.yaml)

El archivo `pubspec.yaml` no fue proporcionado. Sin embargo, el propósito y uso de las dependencias clave se pueden deducir del código fuente.

  * **`flutter_riverpod`**:

      * **Propósito**: Es el framework de gestión de estado principal. Se utiliza para proveer dependencias (inyección de dependencias), gestionar el estado de la UI y manejar la lógica de negocio de manera reactiva y desacoplada.
      * **Ubicación**: Se utiliza en toda la aplicación. Los providers se definen en las carpetas `core/providers` y `features/.../providers`. Las pantallas y widgets consumen estos providers.
      * **Ejemplo de uso**: En `affiliates_screen.dart`, `ref.watch(affiliateListNotifierProvider)` observa los cambios en la lista de afiliados para reconstruir la UI, mientras que `ref.read(affiliateListNotifierProvider.notifier).loadAffiliates()` invoca la lógica para recargar los datos.

  * **`go_router`**:

      * **Propósito**: Gestiona la navegación de la aplicación de forma declarativa y basada en URLs. Permite un enrutamiento complejo, manejo de rutas protegidas y paso de parámetros.
      * **Ubicación**: La configuración central se encuentra en `lib/core/navigation/app_router.dart`.
      * **Ejemplo de uso**: `app_router.dart` define las rutas (`GoRoute`), incluyendo una `ShellRoute` que envuelve las pantallas principales con un `MainScaffold`. El `redirect` es crucial, ya que observa el `authStateProvider` para redirigir a los usuarios no autenticados a la pantalla de login.

  * **`dio`**:

      * **Propósito**: Cliente HTTP avanzado para realizar peticiones a la API del backend. Es preferible a `http` por su soporte a interceptores, timeouts y manejo de errores.
      * **Ubicación**: Se provee globalmente a través de `lib/core/providers/dio_provider.dart`. Es inyectado y utilizado en todos los repositorios (`AffiliateRepository`, `FineRepository`, etc.) para comunicarse con el backend.
      * **Ejemplo de uso**: En `affiliate_repository.dart`, el método `_sendToBackend` utiliza la instancia de `Dio` (`_dio`) para realizar peticiones `POST`, `PUT`, y `DELETE` al servidor.

  * **`sqflite` / `sqflite_common_ffi`**:

      * **Propósito**: Implementación de la base de datos local SQLite. `sqflite` es para móvil y `sqflite_common_ffi` permite que funcione en plataformas de escritorio (Windows, Linux, macOS). Es la única fuente de verdad para los datos que se muestran en la UI.
      * **Ubicación**: La configuración y el esquema de la base de datos se definen en `lib/core/database/database_helper.dart`. `main.dart` se encarga de la inicialización para plataformas de escritorio (`databaseFactory = databaseFactoryFfi;`).
      * **Ejemplo de uso**: `DatabaseHelper` usa `db.execute(...)` para crear las tablas en `_onCreate` y los repositorios usan `db.insert`, `db.query`, `db.update`, y `db.delete` para las operaciones CRUD.

  * **`connectivity_plus`**:

      * **Propósito**: Permite a la aplicación verificar el estado de la conexión de red (WiFi, datos móviles, offline) y reaccionar a los cambios en tiempo real.
      * **Ubicación**: `lib/core/providers/connectivity_provider.dart` expone un `StreamProvider` que emite el estado de la conexión.
      * **Ejemplo de uso**: Los repositorios usan `Connectivity().checkConnectivity()` para decidir si intentan una operación de red. El `syncTriggerProvider` en `sync_service.dart` escucha este stream para iniciar la sincronización automática cuando el dispositivo vuelve a estar en línea.

  * **`cloudinary_public`**:

      * **Propósito**: Facilita la subida de archivos de imagen a los servidores de Cloudinary.
      * **Ubicación**: La lógica está encapsulada en `lib/features/settings/services/cloudinary_service.dart`.
      * **Ejemplo de uso**: En `sync_service.dart`, antes de sincronizar un afiliado creado offline, el servicio verifica si la URL de la foto es una ruta local. Si es así, llama a `cloudinaryService.uploadImage` para subirla y obtener la URL real antes de enviarla al backend.

  * **`pdf` / `printing`**:

      * **Propósito**: `pdf` se usa para generar documentos PDF mediante código Dart, y `printing` proporciona widgets para previsualizar, compartir e imprimir esos PDFs en diferentes plataformas.
      * **Ubicación**: La lógica de generación de PDFs está centralizada en `lib/features/reports/services/pdf_service.dart`. La pantalla `pdf_viewer_screen.dart` utiliza `PdfPreview` del paquete `printing`.
      * **Ejemplo de uso**: En `affiliate_form_screen.dart`, al presionar un botón del `SpeedDialFabWidget`, se llama a un método como `pdfService.generateAffiliateSummaryReport(...)`, que devuelve los bytes del PDF (`Uint8List`), los cuales se pasan a `PdfViewerScreen` para su visualización.

  * **`shared_preferences`**:

      * **Propósito**: Para almacenar datos simples y no críticos de forma persistente (clave-valor), como las preferencias del usuario.
      * **Ubicación**: Se inicializa como una variable global en `main.dart`.
      * **Ejemplo de uso**: `theme_provider.dart` lo utiliza para guardar la preferencia del tema claro/oscuro del usuario (`isDarkMode`). `auth_providers.dart` lo usa para guardar el UUID del usuario logueado (`session_user_uuid`) y mantener la sesión.

-----

## 3\. Módulo Core (Estructura Central)

### 3.1. Base de Datos (`database_helper.dart`)

La clase `DatabaseHelper` implementa el patrón **Singleton** para asegurar que solo exista una única instancia de la base de datos en toda la aplicación, previniendo conflictos y fugas de memoria.

**Detalle de las Tablas SQL (`_onCreate`):**

  * `CREATE TABLE users`: Almacena los usuarios administradores.
      * `uuid TEXT PRIMARY KEY`: Identificador único universal.
      * `email TEXT UNIQUE NOT NULL`: El email es único para evitar duplicados.
      * `role TEXT NOT NULL`: Define el nivel de permiso (`superAdmin`, `admin`, etc.).
  * `CREATE TABLE affiliates`: La tabla central, almacena los datos de los afiliados.
      * `uuid TEXT PRIMARY KEY`: ID principal para relaciones.
      * `id TEXT UNIQUE NOT NULL`: ID legible por humanos (ej. "AP-001"), también único.
      * `ci TEXT UNIQUE NOT NULL`: Cédula de Identidad, también única.
      * `total_paid REAL`, `total_debt REAL`: Campos calculados para un acceso rápido al estado financiero.
  * `CREATE TABLE contributions`: Define los aportes o cuotas generales.
      * `uuid TEXT UNIQUE PRIMARY KEY NOT NULL`: Identificador único del aporte.
  * `CREATE TABLE contribution_affiliates`: Tabla de enlace (muchos a muchos) entre `contributions` y `affiliates`.
      * `FOREIGN KEY (contribution_uuid) REFERENCES contributions (uuid) ON DELETE CASCADE`: Si se borra un aporte, todos sus enlaces se eliminan automáticamente.
      * `FOREIGN KEY (affiliate_uuid) REFERENCES affiliates (uuid) ON DELETE CASCADE`: Si se borra un afiliado, todos sus aportes asignados se eliminan.
      * `is_paid BOOLEAN DEFAULT 0`: Bandera para saber si el afiliado ya completó este aporte.
  * `CREATE TABLE fines`: Almacena las multas generadas.
      * `FOREIGN KEY (affiliate_uuid) REFERENCES affiliates (uuid) ON DELETE CASCADE`: Relación uno (afiliado) a muchos (multas). Si se borra el afiliado, sus multas también.
      * `related_attendance_uuid TEXT`: Enlace opcional a una lista de asistencia si la multa se generó por falta o retraso.
  * `CREATE TABLE attendance_lists`: Define las listas de asistencia.
      * `uuid TEXT PRIMARY KEY`: Identificador de la lista.
      * `status TEXT NOT NULL`: Estado actual de la lista (`PREPARADA`, `INICIADA`, `FINALIZADA`).
  * `CREATE TABLE attendance_records`: Almacena cada registro de asistencia.
      * `FOREIGN KEY (list_uuid) REFERENCES attendance_lists (uuid) ON DELETE CASCADE`: Si se borra una lista, todos sus registros se eliminan.
      * `FOREIGN KEY (affiliate_uuid) REFERENCES affiliates (uuid) ON DELETE CASCADE`: Si se borra un afiliado, sus registros de asistencia se eliminan.
  * `CREATE TABLE pending_operations`: Tabla crucial para la funcionalidad offline.
      * `operation_type TEXT NOT NULL`: `CREATE`, `UPDATE` o `DELETE`.
      * `table_name TEXT NOT NULL`: La tabla a la que afecta la operación.
      * `data TEXT NOT NULL`: El payload de datos en formato JSON que se enviará al backend.
  * `CREATE TABLE app_settings`: Almacena configuraciones globales de la aplicación como los montos de las multas y la URL del backend.

### 3.2. Navegación (`app_router.dart`)

`GoRouter` se configura para manejar toda la navegación de forma declarativa.

  * **Rutas Protegidas (`redirect`)**: El `redirect` es un guardián de rutas. Observa el `authStateProvider`. Si el usuario no está autenticado (`isAuthenticated` es falso) y está intentando acceder a una ruta que no está en la lista de `publicRoutes`, es redirigido automáticamente a `AppRoutes.login`. Esto protege eficazmente todas las rutas administrativas.
  * **`ShellRoute`**: Se utiliza para envolver un conjunto de rutas con una UI común. En este caso, todas las rutas administrativas (`affiliates`, `contributions`, etc.) se renderizan dentro del `MainScaffold`. Esto significa que todas esas pantallas compartirán la misma `AppBar` y el mismo `SideMenu`, creando una experiencia de usuario consistente sin duplicar código.
  * **Rutas de Invitado**: La ruta `/guest-detail` es especial. No utiliza la `ShellRoute` porque necesita un layout diferente. Recibe el objeto `Affiliate` a través del parámetro `extra` de `GoRouter`. Para asegurar que la navegación reaccione a los cambios del estado de invitado (inicio/cierre de sesión), el `GoRouter` tiene un `refreshListenable` que escucha un stream del `guestAffiliateProvider`.

### 3.3. Conectividad (`dio_provider.dart`, `connectivity_provider.dart`)

  * **`dioProvider`**: Provee una única instancia de `Dio` configurada con timeouts de conexión y recepción de 30 segundos. Centralizar la creación de `Dio` aquí permite añadir fácilmente interceptores en el futuro (para logging, añadir tokens de autenticación, etc.) sin tener que modificar cada repositorio.
  * **`connectivityStreamProvider`**: Proporciona un `Stream` que emite un nuevo valor (`List<ConnectivityResult>`) cada vez que el estado de la conexión del dispositivo cambia. Esto permite que otras partes de la aplicación, como el `syncTriggerProvider`, reaccionen en tiempo real a la disponibilidad de la red.

-----

## 4\. Módulo de Datos (Models y Repositories)

A continuación se detalla el funcionamiento de cada repositorio, que sigue un patrón consistente de "offline-first".

### `AffiliateRepository` (`lib/data/repositories/affiliate_repository.dart`)

  * **Propósito**: Gestionar todas las operaciones CRUD (Crear, Leer, Actualizar, Borrar) para la entidad `Affiliate`.
  * **Métodos Principales**:
      * `Future<void> createAffiliate(Affiliate affiliate)`:
        1.  **DB Local**: Inserta el nuevo afiliado en la tabla `affiliates` de la base de datos local usando `db.insert`. Se usa `ConflictAlgorithm.fail` para lanzar un error si ya existe.
        2.  **Conexión**: Llama a `_isConnected()` para verificar si hay internet.
        3.  **Sincronización (Online)**: Si hay conexión, llama a `_sendToBackend('/affiliates', OperationType.CREATE, affiliate.toMap())`. Si el backend responde con éxito (`statusCode == 200`), la operación termina.
        4.  **Operación Pendiente (Offline)**: Si no hay conexión o la llamada al backend falla, crea un objeto `PendingOperation` con el tipo `CREATE`, el nombre de la tabla (`DatabaseHelper.tableAffiliates`) y los datos del afiliado. Luego, lo guarda en la base de datos local a través de `_pendingOpRepo.createPendingOperation(op)`.
      * `Future<void> updateAffiliate(Affiliate affiliate)`: Sigue la misma lógica que `createAffiliate`, pero usa `db.update` para la base de datos local y `OperationType.UPDATE` para la sincronización.
      * `Future<void> bulkUpdateAffiliateDebts(Map<String, double> debtChanges)`:
          * **Propósito**: Este es un método de optimización crucial. Actualiza las deudas de múltiples afiliados en una sola transacción de base de datos, lo cual es mucho más eficiente que realizar múltiples actualizaciones individuales.
          * **Lógica**: Obtiene los afiliados actuales, crea un `db.batch()`, itera sobre los afiliados añadiendo operaciones `batch.update` al lote con la nueva deuda calculada y finalmente ejecuta todas las actualizaciones de una sola vez con `batch.commit()`.
      * `Future<void> applyPaymentToAffiliate(...)`:
          * **Propósito**: Gestiona la lógica de aplicar un pago a un afiliado.
          * **Lógica**: Utiliza una **transacción de base de datos (`db.transaction`)** para garantizar que la lectura y la escritura de los datos del afiliado sean atómicas. Calcula los nuevos `totalPaid` y `totalDebt`, actualiza el registro localmente y luego intenta sincronizar el objeto `Affiliate` completo y actualizado con el backend, creando una operación pendiente de tipo `UPDATE` si falla.

### `ContributionRepository` (`lib/data/repositories/contribution_repository.dart`)

  * **Propósito**: Gestionar la entidad `Contribution` y su relación muchos-a-muchos con los afiliados.
  * **Métodos Principales**:
      * `Future<void> createContributionInTransaction(Contribution contribution, List<ContributionAffiliateLink> links)`:
          * **Propósito**: Crea una contribución y sus múltiples enlaces a afiliados como una sola unidad de trabajo.
          * **Lógica**:
            1.  **Transacción Local**: Ejecuta todas las inserciones en la base de datos (`contributions` y `contribution_affiliates`) dentro de un `db.transaction`. Esto garantiza que si una de las inserciones falla, todas las anteriores se revierten.
            2.  **Sincronización (Online)**: Si hay conexión, prepara un único payload JSON que contiene la contribución y la lista de todos sus enlaces. Lo envía al endpoint `/api/contributions`.
            3.  **Operación Pendiente (Offline)**: Si la sincronización falla, crea **una única operación pendiente** con un `tableName` personalizado: `'custom_contribution_creation'`. El `SyncService` sabrá cómo manejar esta operación especial. El `data` de esta operación contiene tanto la contribución como la lista de enlaces.

### `FineRepository` (`lib/data/repositories/fine_repository.dart`)

  * **Propósito**: Gestionar la entidad `Fine`.
  * **Métodos Principales**:
      * `Future<void> createFine(Fine fine)`: Sigue el patrón estándar: inserción local, intento de sincronización y creación de operación pendiente si falla.
      * `Future<void> deleteFine(Fine fine)`: Es importante notar que para borrar en la base de datos local (`db.delete`), utiliza el `id` autoincremental de la multa. Sin embargo, para la operación pendiente que se enviará al backend, el `data` contiene el `uuid` (`{'uuid': fine.uuid}`), que es el identificador que el backend reconoce.

### `AuthRepository` (`lib/data/repositories/auth_repository.dart`)

  * **Propósito**: Gestionar la autenticación y los usuarios.
  * **Métodos Principales**:
      * `Future<User?> login(String email, String passwordHash)`: Este método funciona **únicamente de forma local**. Comprueba las credenciales contra la tabla `users` en la base de datos local. La sincronización de usuarios se maneja por separado en el `SyncService`.
      * `Future<void> register(User user)`: Sigue el patrón estándar de registro local e intento de sincronización, creando una operación pendiente en caso de fallo.

-----

## 5\. Desglose por Funcionalidad (Features)

### Módulo `Affiliates`

  * **Providers (`affiliate_providers.dart`)**:
      * `AffiliateListNotifier`: Gestiona el estado de la lista de afiliados y su filtrado por tags. Su método `loadAffiliates` obtiene los datos del `AffiliateRepository` y los coloca en `state.allAffiliates`. El método `filterByTags` actualiza el conjunto de `activeTags`, y la UI reacciona gracias al getter `filteredAffiliates`.
      * `AffiliateOperationNotifier`: Gestiona las operaciones de crear, actualizar y eliminar. Cada uno de sus métodos (`createAffiliate`, `updateAffiliate`) realiza validaciones de negocio (ej. `checkIfIdExists`), luego llama al repositorio, y finalmente **invalida el provider de la lista** llamando a `_ref.read(affiliateListNotifierProvider.notifier).loadAffiliates()` para asegurar que la UI muestre los datos actualizados.
  * **Pantallas (`affiliates_screen.dart`, `affiliate_form_screen.dart`)**:
      * `AffiliatesScreen`:
          * Consume el estado con `ref.watch(affiliateListNotifierProvider)`.
          * Usa el getter `.filteredAffiliates.when(...)` para mostrar la UI correspondiente a los datos, el estado de carga o el error.
          * El `FloatingActionButton` navega a `AffiliateFormScreen` para crear un nuevo afiliado.
      * `AffiliateFormScreen`:
          * Es un formulario para crear o editar un afiliado. El botón "GUARDAR" llama al método `_saveAffiliate`.
          * `_saveAffiliate` primero intenta subir las imágenes a Cloudinary si hay conexión. Luego, llama al notifier `ref.read(affiliateOperationProvider.notifier).updateAffiliate(...)` o `.createAffiliate(...)`.
          * Utiliza `ref.listen` para observar el `affiliateOperationProvider` y mostrar un `SnackBar` de éxito o error cuando la operación termina.
  * **Widgets (`affiliate_card.dart`)**:
      * `AffiliateCard` es un widget reutilizable que muestra la información resumida de un afiliado. Maneja la lógica de mostrar una imagen de perfil desde una URL de red (`CachedNetworkImageProvider`) o desde un archivo local (`FileImage`) si la imagen fue tomada offline y aún no se ha sincronizado.

### Módulo `Auth`

  * **Providers (`auth_providers.dart`, `guest_login_provider.dart`)**:
      * `AuthNotifier`: Gestiona el ciclo de vida de la autenticación del administrador. El método `_init` comprueba `SharedPreferences` para una sesión existente. `login` verifica las credenciales localmente y `register` crea un nuevo usuario, gestionando los estados `AuthLoading`, `Authenticated`, y `AuthError`.
      * `GuestLoginNotifier`: Maneja la lógica para el inicio de sesión de invitados. Su método `loginAsGuest` busca en el `AffiliateRepository` un afiliado por ID y CI, y actualiza el estado para la UI.
  * **Pantallas (`login_screen.dart`, `guest_login_screen.dart`, `register_screen.dart`)**:
      * `LoginScreen`: Presenta el formulario de inicio de sesión para administradores. Al presionar "INICIAR SESIÓN", llama a `ref.read(authStateProvider.notifier).login(...)`.
      * `GuestLoginScreen`: Formulario para que los afiliados consulten su información. Llama a `ref.read(guestLoginProvider.notifier).loginAsGuest(...)`. En caso de éxito (`GuestLoginSuccess`), establece el `guestAffiliateProvider` y navega a la ruta de detalle del invitado.
      * `RegisterScreen`: Permite crear una nueva cuenta de administrador, que por defecto tiene el rol `superAdmin`.

### Módulo `Attendance`

  * **Providers (`attendance_providers.dart`)**:
      * `AttendanceNotifier`: Orquesta toda la lógica de asistencia.
          * `createAttendanceList`: Crea una nueva lista.
          * `registerAffiliate`: Registra a un afiliado. Determina si el estado es `PRESENTE` o `RETRASO` basándose en el estado de la lista. Si es `RETRASO`, crea una `Fine` llamando al `FineOperationNotifier`.
          * `finalizeList`: Es un método crítico que encuentra a los afiliados ausentes, genera una multa por falta para cada uno, cambia el estado de la lista a `FINALIZADA` y finalmente llama a `attendanceRepo.syncFinalizedList` para sincronizar la lista completa con el backend.
  * **Pantallas (`attendance_screen.dart`, `attendance_detail_screen.dart`)**:
      * `AttendanceScreen`: Muestra la lista de todos los eventos de asistencia. Permite crear y eliminar listas.
      * `AttendanceDetailScreen`: Es la pantalla principal de operación. Incluye el visor de `QR_code_scanner_plus` (`QRView`). El stream `scannedDataStream` procesa los códigos QR, busca al afiliado y llama a `_processRegistration` para registrarlo. También permite el registro manual a través de un `AffiliateSearchDelegate`.

-----

## 6\. Sincronización y Modo Offline (`sync_service.dart`)

El `SyncService` es el componente más crítico para la resiliencia de la aplicación. Orquesta la comunicación bidireccional entre la base de datos local y el backend.

### 6.1. Propósito del SyncService

Es el cerebro de la sincronización. Se encarga de enviar los cambios locales al servidor (`push`) y de traer las actualizaciones del servidor para aplicarlas localmente (`pull`), asegurando que la base de datos local sea una réplica consistente del estado del servidor.

### 6.2. `pushChanges()` - Subida de Cambios

1.  **Obtener Operaciones**: Llama a `pendingOpRepo.getPendingOperations()` para obtener la lista de operaciones guardadas localmente, ordenadas por fecha.
2.  **Procesar en Bucle**: Itera sobre cada `PendingOperation`.
3.  **Manejo Especial de Imágenes**: Si la operación es sobre la tabla `affiliates` y contiene rutas de archivo locales para las fotos (ej. `/data/user/.../image.jpg`), primero llama a `cloudinaryService.uploadImage()` para subir las imágenes y reemplaza las rutas locales por las URLs seguras de Cloudinary en el payload de datos antes de enviarlo.
4.  **Ejecutar Petición**: Utiliza un `switch` sobre `op.tableName` para determinar el endpoint y el método HTTP correcto.
      * Para operaciones simples (ej. crear multa), hace una petición `POST` a `/api/fines`.
      * Para operaciones complejas como `'custom_contribution_creation'`, construye un payload específico que el backend espera y lo envía a `/api/contributions`.
5.  **Eliminar Operación**: Si la petición al backend es exitosa, elimina la operación de la tabla local con `pendingOpRepo.deletePendingOperation(op.id!)`.

### 6.3. `pullChanges()` - Descarga de Cambios

1.  **Obtener Cambios**: Realiza una petición `GET` al endpoint `/api/sync/pull`. Envía la fecha de la última sincronización (`lastSync`) para que el backend solo devuelva los cambios ocurridos desde entonces.
2.  **Procesar `updated`**: Itera sobre los datos en la sección `updated` de la respuesta. Para cada entidad (ej. `affiliates`, `fines`), llama al método `upsert...` del repositorio correspondiente. Un "upsert" (update or insert) actualiza un registro si ya existe localmente o lo inserta si es nuevo.
3.  **Procesar `deleted`**: Itera sobre los UUIDs en la sección `deleted` de la respuesta. Llama al método `deleteLocally...` del repositorio para eliminar los registros correspondientes de la base de datos local.
4.  **Recalcular Totales (`_recalculateTotalsForAffiliates`)**:
      * **Propósito Crucial**: Este paso es **fundamental** para mantener la consistencia de los datos. En lugar de intentar ajustar los totales de deudas y pagos de forma incremental (lo que es propenso a errores), este método recalcula los valores desde cero para cada afiliado que fue afectado por la sincronización.
      * **Lógica**: Para cada afiliado afectado, el método obtiene **todas** sus multas y **todos** sus aportes de la base de datos local, suma sus montos para obtener la deuda total (`totalDebt`) y los pagos (`totalPaid`), y finalmente llama a `affiliateRepo.updateAffiliateTotals` para escribir estos valores frescos y correctos en la base de datos.
5.  **Actualizar Timestamp**: Si hubo cambios, guarda la nueva fecha y hora de sincronización en `SharedPreferences`.

### 6.4. `syncTriggerProvider`

Este provider escucha el `connectivityStreamProvider`. Cuando detecta una transición de offline a online (`wasOffline` es true y `isOnline` es true), automáticamente invoca a `ref.read(syncServiceProvider).pushChanges()` para iniciar la subida de operaciones pendientes. También gestiona la conexión y desconexión del `WebSocketService` para la sincronización en tiempo real.

-----

## 7\. Flujos de Usuario Críticos (End-to-End)

1.  **Flujo: Crear un nuevo Afiliado con foto (Online/Offline)**:
    1.  **UI**: Usuario abre `AffiliateFormScreen`, llena los datos y selecciona una imagen de perfil.
    2.  **Acción**: Presiona "GUARDAR". El método `_saveAffiliate` se ejecuta.
    3.  **Offline**: Si no hay conexión, `finalProfileUrl` se guarda como la ruta local del archivo (ej. `/path/to/image.jpg`). `AffiliateOperationNotifier.createAffiliate` es llamado. El `AffiliateRepository` inserta el afiliado localmente con la ruta de archivo y crea una `PendingOperation` para `affiliates`.
    4.  **Online**: `_saveAffiliate` primero llama a `cloudinaryService.uploadImage`, que sube la imagen y devuelve una URL `https://...`. Luego, `createAffiliate` en el repositorio inserta el afiliado localmente y lo envía directamente al backend.
    5.  **Sincronización Posterior**: Cuando la app vuelve a estar online, `SyncService.pushChanges` procesa la operación pendiente. Detecta que `profile_photo_url` no es una URL HTTP, por lo que llama a `cloudinaryService` para subirla, actualiza el payload con la nueva URL y luego envía el afiliado completo al backend.
2.  **Flujo: Crear un Aporte y asignarlo a múltiples afiliados**:
    1.  **UI**: Usuario abre el diálogo `CreateContributionDialog`, selecciona varios afiliados y presiona "Crear".
    2.  **Notifier**: `ContributionOperationNotifier.createContribution` es llamado.
    3.  **Repositorio (Transacción)**: El notifier llama a `ContributionRepository.createContributionInTransaction`. Este método, dentro de una transacción de BD, inserta el `Contribution` y todos los `ContributionAffiliateLink` asociados.
    4.  **Actualización de Deuda**: Inmediatamente después, el notifier llama a `AffiliateRepository.bulkUpdateAffiliateDebts`, que actualiza la deuda de todos los afiliados seleccionados en una sola operación eficiente.
    5.  **Sincronización**: Si está offline, se crea una única `PendingOperation` con `tableName: 'custom_contribution_creation'`.
3.  **Flujo: Registrar asistencia de un afiliado (presente y con retraso)**:
    1.  **UI**: Admin en `AttendanceDetailScreen` escanea el QR de un afiliado.
    2.  **Notifier**: `_onQRViewCreated` procesa el QR y llama a `AttendanceNotifier.registerAffiliate`.
    3.  **Lógica de Estado**: El notifier determina el estado. Si la lista está `INICIADA`, el `recordStatus` es `PRESENTE`. Si está `TERMINADA`, el status es `RETRASO`.
    4.  **Generación de Multa**: Si el estado es `RETRASO`, el notifier crea un objeto `Fine` con la descripción "Multa por retraso...", el monto obtenido del `lateFineAmountProvider`, y lo guarda llamando a `FineOperationNotifier.createFine`. Esto también actualiza la deuda del afiliado.
4.  **Flujo: Finalizar una lista de asistencia**:
    1.  **UI**: En `AttendanceDetailScreen`, el admin presiona "FINALIZAR".
    2.  **Notifier**: Se llama a `AttendanceNotifier.finalizeList`.
    3.  **Lógica de Multas**: El notifier encuentra a los `missingAffiliates`. Itera sobre los ausentes y crea una `Fine` por falta para cada uno, usando el monto de `absentFineAmountProvider`.
    4.  **Sincronización Completa**: Cambia el estado de la `AttendanceList` a `FINALIZADA` localmente y llama a `attendanceRepo.syncFinalizedList`, que empaqueta la lista finalizada y **todos** sus registros en un solo payload y lo envía al backend (o lo pone en cola para sincronización).
5.  **Flujo: Pagar una multa**:
    1.  **UI**: Admin abre el diálogo `FinesDetailsDialog` y toca una multa para pagar.
    2.  **Notifier**: Se llama a `FineOperationNotifier.payFine`.
    3.  **Repositorios**: `FineRepository.payFine` es llamado para actualizar el `amountPaid` de la multa. `AffiliateRepository.applyPaymentToAffiliate` es llamado para actualizar los campos `totalDebt` y `totalPaid` del afiliado.
    4.  **Sincronización**: Ambas operaciones (actualización de la multa y del afiliado) se intentan sincronizar con el backend, creando operaciones pendientes si fallan.

-----

## 8\. Modelos de Datos y Estructura de la Base de Datos

### 8.1. Diagrama de Entidad-Relación (Textual)

```
[users] 1--* [pending_operations] (Implicit relation by logic)

[affiliates] 1--* [fines]
  (affiliates.uuid -> fines.affiliate_uuid)

[affiliates] 1--* [contribution_affiliates]
  (affiliates.uuid -> contribution_affiliates.affiliate_uuid)

[contributions] 1--* [contribution_affiliates]
  (contributions.uuid -> contribution_affiliates.contribution_uuid)

[affiliates] 1--* [attendance_records]
  (affiliates.uuid -> attendance_records.affiliate_uuid)

[attendance_lists] 1--* [attendance_records]
  (attendance_lists.uuid -> attendance_records.list_uuid)

[attendance_lists] 1--* [fines] (Optional relation)
  (attendance_lists.uuid -> fines.related_attendance_uuid)
```

### 8.2. Modelos de Datos (`..._model.dart`)

Para cada clase de modelo, el patrón es consistente:

  * **`Affiliate`** (`lib/data/models/affiliate_model.dart`)
      * **Propósito**: Representa a un miembro de la asociación.
      * **Atributos**: Contiene todos los datos personales (`firstName`, `lastName`, `ci`), de contacto, multimedia (`profilePhotoUrl`), y financieros (`totalPaid`, `totalDebt`). El `uuid` es el identificador único principal.
      * **Métodos**:
          * `fromMap()` / `toMap()`: Esenciales para la serialización y deserialización desde y hacia la base de datos SQLite. `fromMap` es robusto, manejando posibles valores nulos y parseando tipos de datos.
          * `copyWith()`: Fundamental para la **inmutabilidad del estado**. En lugar de modificar un objeto existente, se crea una copia con los valores actualizados. Esto es una práctica recomendada en Riverpod para evitar efectos secundarios.
          * `operator ==` y `hashCode`: Se sobrescriben para que la comparación entre dos instancias se base en su `uuid`, no en su referencia en memoria.
  * **`Fine`** (`lib/data/models/fine_model.dart`)
      * **Propósito**: Representa una multa impuesta a un afiliado.
      * **Atributos**: Incluye un `id` local autoincremental de SQLite y un `uuid` para la sincronización. Contiene `affiliateUuid` para la relación, el monto, una `FineCategory` (enum), y el `relatedAttendanceUuid` opcional.
      * **Métodos**: Sigue el mismo patrón que `Affiliate` con `fromMap`, `toMap` y `copyWith`.
  * **`Contribution` y `ContributionAffiliateLink`** (`lib/data/models/contribution_model.dart`)
      * **Propósito**: `Contribution` representa el evento de aporte general, mientras que `ContributionAffiliateLink` representa la deuda específica de un afiliado para ese aporte. Esta separación modela correctamente la relación muchos-a-muchos.
      * **Métodos**: Ambos modelos tienen una implementación robusta de serialización e inmutabilidad.
  * **`User`** (`lib/data/models/user_model.dart`)
      * **Propósito**: Representa a un usuario administrador del sistema.
      * **Atributos**: Contiene `uuid`, `userName`, `email`, un `passwordHash` (nunca la contraseña en texto plano) y un `UserRole` (enum para `superAdmin`, `admin`, etc.).
  * **`AttendanceList` y `AttendanceRecord`** (`lib/data/models/attendance_model.dart`)
      * **Propósito**: `AttendanceList` define un evento de asistencia, y `AttendanceRecord` es cada registro individual de un afiliado en esa lista.
  * **`PendingOperation`** (`lib/data/models/pending_operation_model.dart`)
      * **Propósito**: Representa una operación (CREATE, UPDATE, DELETE) que no pudo ser sincronizada con el backend y está esperando ser enviada.
      * **Atributos**: `operationType`, `tableName`, y `data` (un mapa serializado a JSON con el payload de la operación).

-----

## 9\. UI, Theming y Widgets Compartidos

### 9.1. Sistema de Temas (`theme_provider.dart` y `core/config/theme.dart`)

La aplicación implementa un sistema de temas claro/oscuro de manera eficiente.

  * **Gestión de Estado (`theme_provider.dart`)**:
      * Un `ThemeNotifier` gestiona el `ThemeMode` actual (`light` o `dark`).
      * En su constructor, `_loadTheme()` lee de `SharedPreferences` (usando la clave `themePrefsKey`) para recordar la última preferencia del usuario.
      * `toggleTheme()` cambia el estado y guarda la nueva preferencia en `SharedPreferences`.
  * **Definición de Temas (`AppTheme` en `core/config/theme.dart`)**:
      * Esta clase define dos objetos estáticos `ThemeData`: `lightTheme` y `darkTheme`.
      * Cada tema especifica una paleta de colores completa (`ColorScheme`), colores de fondo, estilos de `AppBar`, `ElevatedButton`, `Card`, etc., usando los colores definidos en `AppColors`.
      * Utiliza `GoogleFonts.montserrat` para una tipografía consistente en toda la aplicación.
  * **Aplicación (`app.dart`)**: El widget principal `ModusPampaApp` observa el `themeNotifierProvider` y pasa el `ThemeMode` actual al `MaterialApp.router`, que automáticamente aplica el tema correspondiente.

### 9.2. Widgets Reutilizables (Carpeta `shared/widgets`)

  * **`SideMenu` (`lib/shared/widgets/side_menu.dart`)**:
      * **Propósito**: Proporciona el menú de navegación lateral (drawer).
      * **Parámetros y Lógica**: Es dinámico. Observa el `authStateProvider` para decidir qué cabecera y qué ítems de menú mostrar. Si es un `Authenticated`, muestra los menús administrativos. Si se detecta un `guestAffiliate`, muestra una vista de invitado. Incluye un indicador de conectividad en tiempo real que observa el `connectivityStreamProvider`.
  * **`MainScaffold` (`lib/shared/widgets/main_scaffold.dart`)**:
      * **Propósito**: Actúa como una plantilla para todas las pantallas principales, proporcionando una `AppBar` y el `SideMenu` de forma consistente.
      * **Parámetros**: Acepta un widget `child`, que es la pantalla a mostrar.
      * **Lógica**: Incluye un `GestureDetector` en el título de la `AppBar` que, al ser tocado 3 veces, navega a la pantalla de configuración (`AppRoutes.settings`), una característica oculta para administradores.

-----

## 10\. Manejo de Errores y Excepciones

### 10.1. Estrategia General

La aplicación adopta una estrategia de manejo de errores por capas. Los errores se capturan lo más cerca posible de donde ocurren (`try-catch`), se convierten en un estado definido (`...OperationError`) y se propagan hacia la UI para informar al usuario de manera controlada.

### 10.2. Tipos de Errores

  * **Errores de Red**:
      * En los repositorios, las llamadas a `_sendToBackend` están envueltas en un `try { ... } on DioException catch (e) { ... }`.
      * Si `Dio` lanza una excepción (ej. timeout, sin conexión, error 404), esta se captura. El método devuelve `null`, lo que indica a la lógica del notifier que la operación de red falló y que debe crear una `PendingOperation`.
  * **Errores de Validación de Formularios**:
      * Se utiliza el sistema de validación de `Form` de Flutter. La clase `Validators` (`lib/shared/utils/validators.dart`) proporciona métodos estáticos para validaciones comunes (ej. `email`, `password`, `notEmpty`).
      * Cada `TextFormField` tiene una propiedad `validator` que llama a uno de estos métodos. Si la validación falla, se muestra un mensaje de error directamente en el campo del formulario.
  * **Errores de la Base de Datos Local**: Las operaciones de `sqflite` pueden lanzar excepciones (ej. por una restricción `UNIQUE` violada). Estas son capturadas por los bloques `try-catch` en los notifiers, que luego actualizan el estado a `...OperationError`.
  * **Respuestas de Error del Backend**: Las excepciones `DioException` pueden contener una `response` con códigos de estado 4xx o 5xx. La lógica de `_sendToBackend` no distingue entre estos y los errores de red, simplemente trata cualquier fallo como una razón para operar en modo offline y crear una operación pendiente.

### 10.3. Feedback al Usuario

La comunicación de errores al usuario se realiza principalmente a través de `ref.listen`.

  * **`ref.listen`**: Las pantallas usan `ref.listen` para observar los `StateNotifierProvider` de operaciones (ej. `affiliateOperationProvider`).
  * **Lógica**: El callback de `ref.listen` se ejecuta cada vez que el estado cambia, sin reconstruir el widget. Dentro del callback, se comprueba si el nuevo estado es una instancia de `...OperationError`. Si es así, se muestra un `SnackBar` con el mensaje de error. Lo mismo ocurre para los estados de éxito.

-----

## 11\. Pruebas (Testing)

### 11.1. Estrategia de Pruebas

Basado en la arquitectura limpia del proyecto, se recomienda una estrategia de pirámide de pruebas:

1.  **Pruebas Unitarias (Mayor cantidad)**: Para la lógica de negocio pura.
2.  **Pruebas de Widgets (Cantidad media)**: Para componentes de UI y su interacción con los providers.
3.  **Pruebas de Integración (Menor cantidad)**: Para flujos completos End-to-End.

### 11.2. Pruebas Unitarias

  * **Objetivo**: Probar los **Repositories** y **StateNotifiers** de forma aislada.
  * **Repositorios**:
      * Se debe simular (`mock`) las dependencias: `DatabaseHelper`, `Dio`, y `PendingOperationRepository`.
      * Para probar `AffiliateRepository.createAffiliate`, se escribirían dos casos:
        1.  **Caso Online**: Simular que `_isConnected` devuelve `true` y que `_dio.post` devuelve una respuesta exitosa. Verificar que `db.insert` fue llamado y que **no** se llamó a `pendingOpRepo.createPendingOperation`.
        2.  **Caso Offline**: Simular que `_isConnected` devuelve `false`. Verificar que `db.insert` fue llamado y que `pendingOpRepo.createPendingOperation` **sí** fue llamado.
  * **Notifiers**:
      * Simular el repositorio que utilizan.
      * Llamar a un método del notifier (ej. `AffiliateOperationNotifier.createAffiliate`).
      * Verificar que el estado del notifier transita correctamente (`Initial` -\> `Loading` -\> `Success`/`Error`) y que se llamó al método correcto del repositorio simulado.

### 11.3. Pruebas de Widgets

  * **Objetivo**: Probar los widgets y pantallas, asegurando que la UI reacciona a los cambios de estado.
  * **Widgets Personalizados**: Para `AffiliateCard`, crear una prueba que le pase un objeto `Affiliate` y verifique que el nombre, ID y montos se renderizan correctamente.
  * **Pantallas**:
      * Para probar `AffiliatesScreen`, envolver el widget en un `ProviderScope`.
      * Sobrescribir los providers (`overrideWith`) para devolver estados simulados.
      * **Caso Loading**: Simular que el `affiliateListNotifierProvider` está en estado `AsyncLoading`. Verificar que se muestra un `CircularProgressIndicator`.
      * **Caso Data**: Simular que devuelve `AsyncData` con una lista de afiliados. Verificar que se renderiza una `ListView` con el número correcto de `AffiliateCard`.

-----

## 12\. Guía de Configuración y Despliegue

### 12.1. Configuración del Entorno

1.  **Requisitos Previos**:
      * SDK de Flutter (versión 3.19 o superior recomendada).
      * Editor de código como VS Code con las extensiones de Flutter y Dart.
      * Para desarrollo en escritorio, habilitar el soporte para la plataforma deseada (ej. `flutter config --enable-windows-desktop`).
2.  **Clonar y Ejecutar**:
      * Clonar el repositorio: `git clone <URL_DEL_REPOSITORIO>`
      * Navegar al directorio del proyecto: `cd modus-pampa-v3`
      * Instalar dependencias: `flutter pub get`
      * Ejecutar la aplicación: `flutter run`
3.  **Variables de Entorno**:
      * **Cloudinary**: El servicio `CloudinaryService` (`lib/features/settings/services/cloudinary_service.dart`) tiene las credenciales (`_cloudName` y `_uploadPreset`) hardcodeadas. Para producción, estas deben extraerse a un archivo de configuración (`.env`) y cargarse usando un paquete como `flutter_dotenv`.
          * `_cloudName = 'dwy89tsa0'`
          * `_uploadPreset = 'pampa_app'`
      * **Backend URL**: La URL del backend por defecto se define en `lib/features/settings/providers/settings_provider.dart` y en `lib/data/models/configuration_model.dart`. Aunque se puede cambiar en la app, para una nueva instalación se debe modificar en el código o, idealmente, mover a una variable de entorno.

### 12.2. Proceso de Build

  * **Android APK (para pruebas/distribución directa)**:
    ```bash
    flutter build apk
    ```
    El resultado se encontrará en `build/app/outputs/flutter-apk/app-release.apk`.
  * **Android App Bundle (para publicar en Google Play Store)**:
    ```bash
    flutter build appbundle
    ```
    El resultado se encontrará en `build/app/outputs/bundle/release/app-release.aab`.

### 12.3. Consideraciones Adicionales

  * **Iconos y Splash Screen**: La configuración de los iconos de la aplicación y la pantalla de bienvenida (`splash screen`) se debe realizar a través de paquetes como `flutter_launcher_icons` y `flutter_native_splash`. Se debe verificar el `pubspec.yaml` (no proporcionado) para ver si están configurados y ejecutar sus comandos correspondientes (`flutter pub run ...`). La animación de la splash screen se carga desde `assets/animations/loading_animation.lottie`.