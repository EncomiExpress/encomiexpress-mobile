# EncomiExpress - App Móvil

Aplicación móvil de OsvaldoC Mensajería y Logística S.A.S., empresa especializada en el transporte de encomiendas, para los tres roles que operan fuera de una oficina: el **conductor** que transporta la carga, el **distribuidor** que hace la entrega final en la sede de destino, y el **administrador**, que gestiona los anticipos entregados a los conductores. Complementa al panel web, encargado de la administración completa del sistema (ventas, rutas, clientes, flota, usuarios).

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
| **Conductor** | - Pestaña "Anticipos": ver "Mis anticipos" con búsqueda y filtro por estado (Pendientes/Completados) <br> - Legalizar anticipos: registrar el valor gastado y cargar los comprobantes — el excedente/faltante se calcula automáticamente, y queda bloqueado mientras falte dejar paquetes en alguna sede de la ruta <br> - Pestaña "Paquetes" — **entrega en dos fases**: agrupados por ruta → sede, un solo botón "Dejar N paquetes en la sede" por sede (foto y novedades opcionales); la entrega final al destinatario la hace el distribuidor, no el conductor <br> - Pestaña "Paquetes de retorno": selector Pendientes / Retorno / Historial — confirma "Llegó a Medellín" para los paquetes no entregados que vuelven en su convoy de regreso <br> - Consulta y edición de perfil propio (nombre, apellido, documento, teléfono, correo, contraseña — sin foto, ese campo no está implementado) <br> - Recuperar contraseña |
| **Distribuidor** | - Pestaña "Paquetes": lista los paquetes "En sede de destino" de la sede que cubre <br> - Entrega final al destinatario: Entregado / No entregado / Intento (foto y novedad obligatorias; tope de 5 intentos, sin límite para Entregado/No entregado) <br> - Contador de insistidera por paquete, con enlace a su historial completo de intentos <br> - Segmento Pendientes / Historial (lo que ya cerró) <br> - Perfil de solo lectura (incluye la sede que cubre) + cerrar sesión |
| **Administrador** | - Dashboard: anticipos totales, gastado, excedentes pendientes, faltantes pendientes y por confirmar <br> - Listado de anticipos con segmento Pendientes/Completados + filtros por Estado, Año y Mes <br> - Registrar anticipo eligiendo una ruta (vehículo y conductor se autocompletan del convoy), con las mismas reglas que el panel web: no ofrece rutas/conductores que ya tengan un anticipo activo, la fecha de entrega no puede ser posterior a la salida de la ruta, y avisa si el vehículo elegido no tiene paquetes asignados <br> - Editar anticipo (solo mientras sigue "Entregado") <br> - Confirmar devolución de excedente o reposición de faltante <br> - Inhabilitar/habilitar un anticipo — si nunca se llegó a entregar, exige declarar un motivo y lo cierra como "Cerrado sin entregar" <br> - Ver detalle de cualquier anticipo <br> - Perfil propio (solo lectura) |
| **General** | - Inicio y cierre de sesión <br> - Solo los roles `conductor`, `distribuidor` y `admin` pueden entrar desde el móvil — cualquier otro rol (ej. `operador_sede`, exclusivo del panel web) se rechaza con un aviso, en vez de caer por defecto en la pantalla de admin <br> - Recuperar contraseña <br> - Modo oscuro / modo claro <br> - Paleta de colores personalizable (rojo / azul), misma paleta que el panel web <br> - Recargar por gesto de "pull-to-refresh" <br> - Menú inferior único estilo YouTube (ícono + texto pequeño) |

---

## Stack Tecnológico

- Flutter + Dart
- dio — Consumo de API REST (`^5.4.0`)
- shared_preferences — Persistencia de datos de usuario y preferencia de tema (`^2.2.2`)
- file_picker — Selección de archivos y comprobantes de anticipo (`^11.0.3`)
- image_picker — Foto de evidencia de entrega/devolución (`^1.1.2`)
- url_launcher — Apertura de enlaces externos (`^6.3.2`)
- Estado gestionado con `setState`/`StatefulWidget`, y `ChangeNotifier` para el tema (`ThemeController`)

---

## Arquitectura Limpia

El proyecto está estructurado siguiendo principios de arquitectura limpia y separación de responsabilidades:

```bash
lib/
├── main.dart                  # Punto de entrada — inicializa ApiClient y arranca en LoginScreen
├── config/
│   └── api_config.dart        # baseUrl configurable por --dart-define
├── core/                      # Servicios, modelos y componentes centrales
│   ├── models.dart            # UserModel, Anticipo, EstadoAnticipo, LicenciaCategoria, AppColors
│   ├── widgets.dart           # Componentes reutilizables (SectionCard, StatCard, AnticipoCard,
│   │                           # FilterSelect, BottomMenuBar, TabPendientesHistorial, ...)
│   ├── image_viewer.dart      # Visor de imágenes a pantalla completa (comprobantes/evidencias)
│   ├── platform_utils.dart    # Detecta móvil vs. escritorio/web (cámara/galería vs. selector de archivos)
│   ├── theme/                 # Modo claro/oscuro + paleta rojo/azul
│   └── services/               # ApiClient, AuthService, AnticipoService, ConductorService, PaqueteService
└── features/                  # Funcionalidades específicas por rol
    ├── auth/screens/           # Login (con el bloqueo de roles sin pantalla propia), recuperar contraseña
    ├── admin/screens/          # Dashboard, listado, detalle, crear/editar anticipo, perfil
    ├── driver/screens/         # Home (pestañas Anticipos/Paquetes), paquetes agrupados por ruta →
    │                           # sede (entrega en dos fases + paquetes de retorno), perfil propio editable
    └── distribuidor/screens/   # Home reducido (Paquetes/Perfil), entrega final al destinatario
```

### Principios de Arquitectura Implementados

- **Separación de responsabilidades**: Cada capa tiene un propósito bien definido
- **Inyección de dependencias**: Servicios como `ApiClient` y `ThemeController` se inicializan desde `main.dart`
- **Modelos consistentes**: `UserModel`, `Anticipo` y `LicenciaCategoria` definidos en `core/models.dart`
- **Navegación basada en roles**: redirección automática según el rol que devuelve el backend en el login, con rechazo explícito de roles sin pantalla propia
- **Pantallas compartidas**: el detalle y el formulario de anticipo son la misma pantalla para admin y conductor (ajustada por un flag), no una copia por rol

---

## Sistema de Navegación

La aplicación utiliza un patrón de navegación basado en roles que determina la pantalla inicial después de la autenticación:

1. **Pantalla de Login (`LoginScreen`)**
   - Punto de entrada para todos los usuarios
   - El rol se obtiene directo de la respuesta de `POST /api/auth/login`, no se adivina

2. **Redirección basada en rol**
   - `conductor` → `DriverHome`
   - `distribuidor` → `DistribuidorHome`
   - `admin` → `AdminHome`
   - cualquier otro rol (ej. `operador_sede`, exclusivo del panel web) → se rechaza el login con un aviso, en vez de caer en `AdminHome` sin tener los permisos que esa pantalla necesita

3. **Navegación interna**
   - `AdminHome`: dashboard, listado y gestión de anticipos
   - `DriverHome`: tres pestañas — **Anticipos** (los suyos), **Paquetes** (dejar en sede) y **Paquetes de retorno**
   - `DistribuidorHome`: **Paquetes** (entrega final en su sede) y **Perfil**
   - Las tres pantallas comparten el mismo `BottomMenuBar` (menú inferior único estilo YouTube)
   - Las tres incluyen cierre de sesión (desde el menú de Perfil)

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

**General**
- Login: `POST /api/auth/login`
- Recuperar contraseña: `POST /api/auth/recuperar-password`, `POST /api/auth/cambiar-password`

**Conductor**
- Perfil propio: `GET/PUT /api/conductores/perfil`
- Mis anticipos: `GET /api/conductores/mis-anticipos`
- Legalizar / subir comprobante: `PUT /api/anticipos/:id`, `POST /api/anticipos/:id/soporte`
- Dejar paquetes en la sede (entrega en dos fases): `PATCH /api/paquetes/sede`
- Paquetes de retorno: `GET /api/paquetes/retorno`, `PATCH /api/paquetes/:id/devolucion`
- Historial de entrega de un paquete puntual: `GET /api/paquetes/:id/historial-entrega`

**Distribuidor**
- Paquetes de su sede: `GET /api/paquetes/sede`
- Historial de lo ya cerrado: `GET /api/paquetes/sede/historial`
- Entrega final (Entregado/No entregado/Intento): `PATCH /api/paquetes/:id/entrega-final`

**Administrador**
- Rutas disponibles para el formulario de anticipo: `GET /api/rutas?estado=Programada&habilitado=true`
- Paquetes por par vehículo/conductor de una ruta (aviso de "vehículo sin paquetes"): `GET /api/encomiendas?idRuta=`
- Anticipos: `GET/POST /api/anticipos`, `GET /api/anticipos/:id`, `PUT /api/anticipos/:id`, `GET /api/anticipos/anios-disponibles`
- Confirmar devolución de excedente / reposición de faltante: `PATCH /api/anticipos/:id/entregar-excedente`
- Inhabilitar / habilitar anticipo: `PATCH /api/anticipos/:id/toggle-habilitado`

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
