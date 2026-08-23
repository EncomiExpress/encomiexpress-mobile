# EncomiExpress - App Móvil

Aplicación móvil para conductores y administradores de OsvaldoC Mensajería y Logística S.A.S., empresa especializada en el transporte de encomiendas. Diseñada como una herramienta de acceso rápido desde el dispositivo móvil, permite al conductor registrar la entrega de sus paquetes asignados y gestionar sus anticipos, complementando el panel web encargado de la administración y validación de la información del sistema.

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
| **Conductor** | - Pestaña "Anticipos": ver "Mis anticipos" con búsqueda por ruta y filtro por estado <br> - Legalizar anticipos: registrar el valor gastado y cargar los comprobantes (fotos/documentos) — el excedente se calcula automáticamente <br> - Pestaña "Paquetes": paquetes asignados agrupados por ruta, solo se pueden marcar mientras la ruta está "En Ruta" <br> - Registrar cada paquete como Entregado o Devuelto, con foto de evidencia obligatoria y observación opcional <br> - Consulta y edición de perfil propio (datos personales y foto) <br> - Recuperar contraseña |
| **Administrador** | - Dashboard: anticipos totales, gastado, excedentes pendientes, faltantes pendientes y por confirmar <br> - Listado de anticipos con filtros por Estado, Año y Mes <br> - Registrar anticipo eligiendo una ruta (vehículo y conductor se autocompletan del convoy de esa ruta) <br> - Editar anticipo (solo mientras sigue "Entregado") <br> - Confirmar devolución de excedente o reposición de faltante, con diálogo de confirmación previo <br> - Ver detalle de cualquier anticipo <br> - Perfil propio (solo lectura) |
| **General** | - Inicio y cierre de sesión <br> - Recuperar contraseña <br> - Navegación basada en el rol devuelto por el backend <br> - Modo oscuro / modo claro <br> - Paleta de colores personalizable (rojo / azul), misma paleta que el panel web <br> - Recargar por gesto de "pull-to-refresh" (arrastrar hacia abajo), igual que Facebook/Instagram/YouTube — sin botón de refrescar aparte <br> - Menú inferior único estilo YouTube (ícono + texto pequeño, en una sola fila) |

---

## Stack Tecnológico

- Flutter + Dart
- dio — Consumo de API REST (`^5.4.0`)
- shared_preferences — Persistencia de datos de usuario y preferencia de tema (`^2.2.2`)
- file_picker — Selección de archivos y comprobantes de anticipo (`^11.0.3`)
- image_picker — Foto de evidencia de entrega/devolución y foto de perfil (`^1.1.2`)
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
│   ├── models.dart            # UserModel, Anticipo, LicenciaCategoria, AppColors
│   ├── widgets.dart           # Componentes reutilizables (SectionCard, StatCard, FilterSelect, BottomMenuBar, ...)
│   ├── image_viewer.dart      # Visor de imágenes a pantalla completa (comprobantes/evidencias)
│   ├── theme/                 # Modo claro/oscuro + paleta rojo/azul
│   └── services/               # ApiClient, AuthService, AnticipoService, ConductorService, PaqueteService
└── features/                  # Funcionalidades específicas por rol
    ├── auth/screens/           # Login, recuperar contraseña
    ├── admin/screens/          # Dashboard, listado, detalle, crear/editar anticipo, perfil
    └── driver/screens/         # Home (pestañas Anticipos/Paquetes + menú inferior),
                                 # paquetes agrupados por ruta con registro de entrega
                                 # (foto de evidencia + observación), perfil propio
```

### Principios de Arquitectura Implementados

- **Separación de responsabilidades**: Cada capa tiene un propósito bien definido
- **Inyección de dependencias**: Servicios como `ApiClient` y `ThemeController` se inicializan desde `main.dart`
- **Modelos consistentes**: `UserModel`, `Anticipo` y `LicenciaCategoria` definidos en `core/models.dart`
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
   - `DriverHome`: dos pestañas — **Anticipos** (los suyos) y **Paquetes** (todos los asignados al conductor, con registro de entrega)
   - Ambas pantallas comparten el mismo `BottomMenuBar` (menú inferior único estilo YouTube, ícono + texto): Tema, Perfil y, según el rol, las pestañas o la opción de registrar un anticipo nuevo
   - Ambas pantallas incluyen cierre de sesión (desde el menú de Perfil)

La navegación se implementa con `Navigator.pushReplacement` tras un login exitoso.

---

## Sistema de Tema

- **`ThemeController`** (`core/theme/theme_controller.dart`) — `ChangeNotifier` singleton con `darkMode` y `paletteKey` (`'red'` | `'blue'`), persistidos en `shared_preferences`
- **`theme_tokens.dart`** — cuatro paletas (rojo/azul × claro/oscuro), mismos valores hex que `shared/styles/theme.js` del panel web
- **`AppColors`** (`core/models.dart`) — colores estáticos que `ThemeController` actualiza en cada cambio; los widgets los leen directo en cada build

El selector vive en el bottom sheet "Personalizar", que se abre desde el ícono "Tema" del menú inferior.

---

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/EncomiExpress/encomiexpress-mobile.git
cd encomiexpress-mobile

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar la aplicación (por defecto apunta a http://localhost:3000)
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
- Perfil del usuario autenticado (login): `GET /api/auth/profile`
- Recuperar contraseña: `POST /api/auth/recuperar-password`, `POST /api/auth/cambiar-password`
- Rutas disponibles (para el formulario de crear/editar anticipo — solo "Programada" y habilitadas): `GET /api/rutas?estado=Programada&habilitado=true`
- Anticipos (admin): `GET/POST /api/anticipos`, `GET /api/anticipos/:id`, `PUT /api/anticipos/:id`, `GET /api/anticipos/anios-disponibles`
- Anticipos (conductor): `GET /api/conductores/mis-anticipos`
- Confirmar devolución de excedente / reposición de faltante: `PATCH /api/anticipos/:id/entregar-excedente`
- Soporte de anticipo (comprobantes): `POST /api/anticipos/:id/soporte`
- Perfil del conductor: `GET/PUT /api/conductores/perfil`
- Paquetes asignados al conductor: `GET /api/paquetes?idConductor=`
- Registrar entrega/devolución de un paquete (foto de evidencia + observación): `PATCH /api/paquetes/:id/evidencia`

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