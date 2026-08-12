# EncomiExpress - App Móvil

Aplicación móvil para conductores y administradores de OsvaldoC Mensajería y Logística S.A.S., empresa especializada en el transporte de encomiendas. Diseñada como una herramienta de acceso rápido desde el dispositivo móvil, permite al conductor ejecutar sus programaciones (salidas) del día, registrar la entrega de cada paquete y gestionar sus anticipos, complementando el panel web encargado de la administración y validación de la información del sistema.

---

## Integrantes del Equipo

- Valeria Paz Arana
- Santiago Suárez Durán
- Sebastián Valencia Pérez
- Yeferson Andrés Moreno Granda

---

### Índice

- [Características Implementadas](#características-implementadas)
- [Stack Tecnológico](#stack-tecnológico)
- [Arquitectura Limpia](#arquitectura-limpia)
- [Sistema de Navegación](#sistema-de-navegación)
- [Sistema de Tema](#sistema-de-tema)
- [Instalación](#instalación)
- [Rutas de la API](#rutas-de-la-api)
- [Repositorios relacionados](#repositorios-relacionados)
- [Licencia](#licencia)

---

## Características Implementadas

| Rol | Funcionalidades |
|------|----------------|
| **Conductor** | - Pestaña "Rutas": ver sus programaciones (salidas) de hoy y próximas, con indicador "Hoy" <br> - Iniciar una programación ("En curso") y finalizarla, con los errores del backend (documentos vencidos, licencia vencida, paquetes sin resultado) mostrados en pantalla <br> - Ver los paquetes de la programación actual con resumen Por Entregar / Entregados / No Entregados <br> - Registrar cada intento de entrega: exitoso (con nombre de quien recibió) o fallido (con motivo) — el paquete pasa a "Devuelto" automáticamente al agotar el máximo de intentos <br> - Ver "Mis anticipos" con búsqueda y filtro por estado <br> - Legalizar anticipos: registrar el valor gastado y cargar los comprobantes (fotos/documentos) — el excedente se calcula automáticamente <br> - Consulta y edición de perfil propio (datos personales y foto) <br> - Recuperar contraseña |
| **Administrador** | - Dashboard: anticipos totales, gastado, excedentes pendientes y por confirmar <br> - Listado de anticipos con filtros por Estado, Año y Mes <br> - Registrar anticipo eligiendo una programación (el conductor se autocompleta, nunca se elige aparte) <br> - Editar anticipo (solo mientras sigue "Entregado") <br> - Confirmar devolución de excedente, con diálogo de confirmación previo <br> - Ver detalle de cualquier anticipo <br> - Perfil propio (solo lectura) |
| **General** | - Inicio y cierre de sesión <br> - Recuperar contraseña <br> - Navegación basada en el rol devuelto por el backend <br> - Modo oscuro / modo claro <br> - Paleta de colores personalizable (rojo / azul), misma paleta que el panel web |

---

## Stack Tecnológico

- Flutter + Dart
- dio — Consumo de API REST (`^5.4.0`)
- shared_preferences — Persistencia de datos de usuario y preferencia de tema (`^2.2.2`)
- file_picker — Selección de archivos y fotos de perfil (`^6.1.1`)
- url_launcher — Apertura de enlaces externos (`^6.3.2`)
- Estado gestionado con `setState`/`StatefulWidget`, y `ChangeNotifier` para el tema (`ThemeController`)

---

## Arquitectura Limpia

El proyecto está estructurado siguiendo principios de arquitectura limpia y separación de responsabilidades:

```bash
lib/
├── main.dart                  # Punto de entrada — inicializa ApiClient y ThemeController
├── config/
│   └── api_config.dart        # baseUrl configurable por --dart-define
├── core/                      # Servicios, modelos y componentes centrales
│   ├── models.dart            # UserModel, Anticipo, Programacion, AppColors
│   ├── widgets.dart           # Componentes reutilizables (SectionCard, StatCard, FilterSelect, ...)
│   ├── image_viewer.dart      # Visor de imágenes a pantalla completa (comprobantes)
│   ├── theme/                 # Modo claro/oscuro + paleta rojo/azul
│   └── services/               # ApiClient, AuthService, AnticipoService, ConductorService, ProgramacionService, PaqueteService
└── features/                  # Funcionalidades específicas por rol
    ├── auth/screens/           # Login, recuperar contraseña
    ├── admin/screens/          # Dashboard, listado, detalle, crear/editar anticipo, perfil
    └── driver/screens/         # Home (pestañas Rutas/Paquetes/Anticipos), programaciones,
                                 # paquetes de una programación, detalle de paquete + registrar
                                 # intento de entrega, perfil
```

### Principios de Arquitectura Implementados

- **Separación de responsabilidades**: Cada capa tiene un propósito bien definido
- **Inyección de dependencias**: Servicios como `ApiClient` y `ThemeController` se inicializan desde `main.dart`
- **Modelos consistentes**: `UserModel`, `Anticipo` y `Programacion` definidos en `core/models.dart`
- **Navegación basada en roles**: Redirección automática según el rol que devuelve el backend en el login
- **Pantallas compartidas**: el detalle y el formulario de anticipo son la misma pantalla para admin y conductor (ajustada por un flag), no una copia por rol

---

## Sistema de Navegación

La aplicación utiliza un patrón de navegación basado en roles que determina la pantalla inicial después de la autenticación:

1. **Pantalla de Login (`LoginScreen`)**
   - Punto de entrada para todos los usuarios
   - El rol se obtiene directo de la respuesta de `POST /api/auth/login`, no se adivina

2. **Redirección basada en rol**
   - `conductor` → `DriverHome`
   - cualquier otro rol → `AdminHome`

3. **Navegación interna**
   - `AdminHome`: dashboard, listado y gestión de anticipos
   - `DriverHome`: tres pestañas — **Rutas** (programaciones del conductor, iniciar/finalizar, paquetes y registro de entregas), **Paquetes** (todos los paquetes asignados al conductor) y **Anticipos** (los suyos)
   - Ambas pantallas incluyen cierre de sesión

La navegación se implementa con `Navigator.pushReplacement` tras un login exitoso.

---

## Sistema de Tema

- **`ThemeController`** (`core/theme/theme_controller.dart`) — `ChangeNotifier` singleton con `darkMode` y `paletteKey` (`'red'` | `'blue'`), persistidos en `shared_preferences`
- **`theme_tokens.dart`** — cuatro paletas (rojo/azul × claro/oscuro), mismos valores hex que `shared/styles/theme.js` del panel web
- **`AppColors`** (`core/models.dart`) — colores estáticos que `ThemeController` actualiza en cada cambio; los widgets los leen directo en cada build

El selector vive en el bottom sheet "Personalizar" (ícono de paleta en el header).

---

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/EncomiExpress/encomiexpress-mobile.git
cd encomiexpress-mobile

# 2. Cambiar a la rama activa de desarrollo (main está desactualizada)
git checkout apk-flutter

# 3. Instalar dependencias
flutter pub get

# 4. Ejecutar la aplicación (por defecto apunta a http://localhost:3000)
flutter run
```

Si el backend no corre en la misma máquina (emulador Android, dispositivo físico o producción), sobreescribe la URL en tiempo de compilación:

```bash
# Emulador Android
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Dispositivo físico (misma red local)
flutter run --dart-define=API_BASE_URL=http://<IP-LAN-de-tu-máquina>:3000

# Backend de producción
flutter run --dart-define=API_BASE_URL=https://encomiexpress-backend.onrender.com
```

---

## Rutas de la API

- Login: `POST /api/auth/login`
- Recuperar contraseña: `POST /api/auth/recuperar-password`, `POST /api/auth/cambiar-password`
- Programaciones del conductor: `GET /api/programaciones` (filtra automáticamente a las propias del conductor autenticado), `GET /api/programaciones/:id` (incluye sus paquetes)
- Iniciar / finalizar programación: `PATCH /api/programaciones/:id/estado` (el conductor solo puede avanzar el estado de su propia programación)
- Paquetes de una programación: `GET /api/paquetes?idProgramacion=`
- Registrar intento de entrega (exitoso o fallido): `POST /api/paquetes/:id/intentos`
- Detalle/resumen de un paquete: `GET /api/paquetes/:id/resumen`
- Anticipos (admin): `GET/POST /api/anticipos`, `PUT /api/anticipos/:id`, `GET /api/anticipos/anios-disponibles`
- Anticipos (conductor): `GET /api/conductores/mis-anticipos`
- Confirmar devolución de excedente: `PATCH /api/anticipos/:id/entregar-excedente`
- Soporte de anticipo: `POST /api/anticipos/:id/soporte`
- Programaciones disponibles (para el formulario de crear/editar anticipo): `GET /api/programaciones?estado=Programada`
- Perfil del conductor: `GET/PUT /api/conductores/perfil`

---

## Repositorios relacionados

| Repositorio | Descripción | Stack |
|---|---|---|
| [encomiexpress-backend](https://github.com/EncomiExpress/encomiexpress-backend) | API REST del sistema | Node.js · Express · PostgreSQL · Sequelize |
| [encomiexpress-frontend](https://github.com/EncomiExpress/encomiexpress-frontend) | Panel web administrativo | React · Vite · Material UI |

---

## Licencia

Este proyecto está bajo la licencia MIT — ver el archivo [LICENSE](./LICENSE) para más detalles.

---

Desarrollado con apoyo de herramientas de inteligencia artificial Claude (Anthropic) y Kilo Code.