# flutter_frontend

Frontend móvil de la aplicación (Flutter).

Este repositorio contiene la aplicación móvil desarrollada en Flutter para el proyecto de ISIS3510. El objetivo de este `README` es documentar las funcionalidades implementadas, la estructura del código, la configuración necesaria y otras notaspara su despliegue.

---

## Índice

- Introducción
- Funcionalidades implementadas
- Dependencias principales
- Estructura del proyecto
- Flujos principales y pantallas
- Modelos y esquema de datos local
- Integración con Firebase
- Variables de entorno y configuración
- Instalación y ejecución

---

## Introducción

`flutter_frontend` es la aplicación móvil que sirve como interfaz del sistema. Está pensada para ser mantenible, modular y con separación de responsabilidades entre capas (UI, lógica y datos). Se han implementado integraciones con Firebase, soporte para mapas, manejo de archivos y persistencia local.

## Funcionalidades implementadas

A continuación se listan las funcionalidades ya desarrolladas en la aplicación. Si alguna entrada necesita ampliación con rutas de archivos o ejemplos de código, puedo detallarla.

1. Autenticación
	- Registro y login con correo/contraseña usando `firebase_auth`.
	- Inicio de sesión con Google (`google_sign_in`) integrado con Firebase.
	- Manejadores de sesión y persistencia de token en `shared_preferences`.

2. Gestión de archivos e imágenes
	- Selección de imagen desde galería o cámara (`image_picker`).
	- Selección de archivos genéricos con `file_picker`.
	- Visualización y apertura de archivos locales con `open_filex`.
	- Subida y descarga de archivos desde Firebase Storage (`firebase_storage`).
	- Caché y gestión de imágenes con `cached_network_image` y `flutter_cache_manager`.

3. Persistencia local
	- Base de datos local en SQLite mediante `sqflite` para almacenar entidades clave.
	- Uso de `shared_preferences` para configuraciones y flags simples.
	- Carga de datos iniciales desde assets (por ejemplo `assets/pet_health_db.vaccines.json`).

4. Geolocalización y mapas
	- Obtención de ubicación con `geolocator`.
	- Visualización de mapas y marcadores con `flutter_map` y `latlong2`.

5. Conectividad y comportamiento offline
	- Detección de estado de conexión con `connectivity_plus`.
	- Estrategias simples de reintento y notificaciones de falta de conexión.

6. NFC
	- Lectura/escritura básica de tags NFC con `nfc_manager` (funciones básicas activas en Android compatibles).

7. URLs y navegación externa
	- Apertura de enlaces externos con `url_launcher`.

8. Configuración por entorno
	- Soporte para variables en `.env` mediante `flutter_dotenv`.

9. Internacionalización y recursos
	- Estructura para strings e imágenes en `assets/` (soporta agregar localizaciones posteriormente).

10. Varios utilitarios
	- Manejo de permisos, acceso a cámara/archivos y comprobaciones de runtime.

## Dependencias principales

Las dependencias clave usadas en el proyecto (ver `pubspec.yaml`) son:

- `flutter` (SDK)
- `firebase_core`, `firebase_auth`, `firebase_storage`
- `google_sign_in`
- `image_picker`, `file_picker`, `open_filex`
- `cached_network_image`, `flutter_cache_manager`
- `sqflite`, `shared_preferences`
- `geolocator`, `flutter_map`, `latlong2`
- `connectivity_plus`, `url_launcher`, `nfc_manager`
- `flutter_dotenv`

Revisar `pubspec.yaml` para la lista completa y versiones exactas.

## Estructura del proyecto (relevante)

Vista general de carpetas importantes:

- `lib/` – código fuente principal.
  - `main.dart` – punto de entrada.
  - `app/` – configuración de rutas, proveedores y composición de la aplicación.
  - `core/` – utilidades, constantes, manejo de errores y servicios genéricos.
  - `presentation/` – pantallas, widgets y lógica de UI.
  - `shared/` – widgets reutilizables, temas y estilos.

- `android/`, `ios/` – configuraciones nativas y archivos de servicios (Firebase, permisos).
- `assets/` – imágenes, íconos y datos JSON iniciales.

## Flujos principales y pantallas

Descripción breve de flujos y pantallas implementadas:

- Pantalla de Bienvenida / Splash: carga de configuración y determinación de estado de sesión.
- Pantalla de Login / Registro: formularios para autenticación y control de errores.
- Pantalla Principal / Home: vista con listado de elementos (mascotas / entidades según la app).
- Pantalla de Detalle: muestra información detallada de un elemento, con posibilidad de subir imágenes y archivos.
- Pantalla de Perfil: gestión de datos del usuario y logout.
- Pantalla de Mapas: visualiza ubicaciones relevantes y permite acciones sobre marcadores.
- Pantalla de Configuración: ajustes básicos y manejo de preferencias.

Si quieres, puedo mapear cada pantalla a los archivos exactos (`lib/presentation/...`) y añadir rutas de navegación aquí.

## Modelos y esquema de datos local

Ejemplo de modelo para una entidad `Pet` (simplificado):

```dart
class Pet {
  final int id;
  final String name;
  final String breed;
  final DateTime? lastVaccineDate;
  final String? imageUrl;

  Pet({
	 required this.id,
	 required this.name,
	 required this.breed,
	 this.lastVaccineDate,
	 this.imageUrl,
  });
}
```

Esquema de tabla SQLite (ejemplo):

```sql
CREATE TABLE pets (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  breed TEXT,
  last_vaccine_date TEXT,
  image_url TEXT
);
```

## Integración con Firebase

- `lib/firebase_options.dart` contiene la configuración generada por `flutterfire`.
- `android/app/google-services.json` y `ios/Runner/GoogleService-Info.plist` (iOS) son necesarios para habilitar Firebase.
- Autenticación y Storage están ya integrados; revisar `lib/core/services/firebase_service.dart` (o ruta equivalente) para ver wrappers.

## Variables de entorno y configuración

El proyecto utiliza `.env` para variables sensibles o de entorno. Ejemplo de variables esperadas:

- `API_URL` – URL del backend (si aplica).
- `FIREBASE_API_KEY` – clave generada por Firebase (opcional si se usa `google-services.json`).
- `SENTRY_DSN` – DSN de reporte de errores (si se integra en el futuro).

Coloca un archivo `.env` en la raíz con los valores necesarios y añade `.env` a `.gitignore` para evitar fugas.

## Instalación y ejecución (detallado)

Prerequisitos:

- Flutter SDK (recomendado versión compatible con Dart SDK indicado en `pubspec.yaml`).
- Android SDK / Android Studio o entornos para iOS si aplica.

Pasos:

1. Clona el repositorio.

```bash
git clone <repo-url>
cd flutter_frontend
```

2. Instala dependencias:

```bash
flutter pub get
```

3. Agrega los archivos de configuración de Firebase para las plataformas que vayas a ejecutar.

4. Ejecuta la app en dispositivo/emulador:

```bash
flutter run
```

Notas para Android:

- Asegúrate de que `android/local.properties` apunte al SDK correcto.
- Revisa `AndroidManifest.xml` para permisos requeridos (ubicación, NFC, cámara, almacenamiento).