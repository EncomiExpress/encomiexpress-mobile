# EncomiExpress - App Móvil

Aplicación móvil para la gestión de anticipos de conductores de OsvaldoC Mensajería y Logística S.A.S., empresa especializada en el transporte de encomiendas. Diseñada como una herramienta de acceso rápido para conductores y administradores, que permite consultar, gestionar y legalizar anticipos desde el dispositivo móvil, complementando el panel web encargado de la administración y validación de la información del sistema.

---

## Características Implementadas

| Rol | Funcionalidades |
|------|----------------|
| **Conductor** | - Consulta de anticipos asignados <br> - Actualización de estado <br> - Consulta y edición de perfil |
| **Administrador** | - Creación de anticipos <br> - Edición de información <br> - Aprobación y rechazo de anticipos |
| **General** | - Inicio de sesión <br> - Cierre de sesión <br> - Navegación basada en roles |

---

## Stack Tecnológico

- Flutter + Dart
- dio — Consumo de API REST (`^5.4.0`)
- shared_preferences — Persistencia de datos de usuario (`^2.2.2`)
- file_picker — Selección de archivos y fotos de perfil (`^6.1.1`)
- url_launcher — Apertura de enlaces externos (`^6.3.2`)
- Estado gestionado con `setState` y `StatefulWidget`

---

## Arquitectura Limpia

El proyecto está estructurado siguiendo principios de arquitectura limpia y separación de responsabilidades:

```bash
lib/
├── main.dart              # Punto de entrada de la aplicación
├── core/                  # Servicios y modelos centrales
│   ├── models.dart        # Modelos de datos y AppColors
│   └── services/          # Servicios API y autenticación
└── features/              # Funcionalidades específicas por rol
    ├── auth/              # Autenticación y login
    ├── admin/             # Funcionalidades de administrador
    └── driver/            # Funcionalidades de conductor
```

### Principios de Arquitectura Implementados

- **Separación de responsabilidades**: Cada capa tiene un propósito bien definido
- **Inyección de dependencias**: Servicios como `ApiClient` y `AuthService` se inicializan desde `main.dart`
- **Modelos consistentes**: `UserModel` y `Anticipo` definidos en `core/models.dart`
- **Navegación basada en roles**: Redirección automática según el rol autenticado

---

## Sistema de Navegación

La aplicación utiliza un patrón de navegación basado en roles que determina la pantalla inicial después de la autenticación:

1. **Pantalla de Login (`LoginScreen`)**
   - Punto de entrada para todos los usuarios

2. **Redirección basada en rol**
   - `administrador` → `AdminHome`
   - `conductor` → `DriverHome`

3. **Navegación interna**
   - `AdminHome`: Gestión de anticipos (crear, visualizar, actualizar, aprobar/rechazar)
   - `DriverHome`: Visualización y gestión de anticipos asignados (actualización de estado y cargue de soportes)
   - Ambas pantallas incluyen funcionalidad de cierre de sesión

La navegación se implementa utilizando `flutter/material.dart` mediante rutas programáticas con `Navigator.pushReplacement`.

---

## Paleta de Colores

| Nombre | Color | Uso |
|---|---|---|
| `adminGradStart` | `#7B2FBE` | Morado principal |
| `adminGradEnd` | `#9B59B6` | Morado complementario |
| `driverGradStart` | `#2563EB` | Azul de acciones y navegación |
| `bgGray` | `#F5F6FA` | Fondo general |
| `cardBg` | `#FFFFFF` | Tarjetas y superficies |
| `textMain` | `#1E293B` | Texto principal |

---

## Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/EncomiExpress/encomiexpress-mobile.git
cd encomiexpress-mobile

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar la aplicación
flutter run
```

---

## Credenciales de Prueba

| Rol | Email | Contraseña |
|---|---|---|
| Administrador | `admin@encomiexpress.com` | `admin123` |
| Conductor | `conductor@encomiexpress.com` | `conductor123` |

---

## Rutas de la API

- Backend: `http://localhost:3000`
- Login: `POST /api/auth/login`
- Anticipos: `GET/POST /api/anticipos`, `PUT /api/anticipos/:id`
- Soporte de anticipo: `POST /api/anticipos/:id/soporte`
- Perfil del conductor: `GET/PUT /api/conductores/perfil`

---

## Repositorios relacionados

| Repositorio | Descripción | Stack |
|---|---|---|
| [encomiexpress-backend](https://github.com/EncomiExpress/encomiexpress-backend) | API REST del sistema | Node.js · Express · PostgreSQL · Sequelize |
| [encomiexpress-frontend](https://github.com/EncomiExpress/encomiexpress-frontend) | Panel web administrativo | React · Vite · Material UI |

---

Desarrollado con apoyo de herramientas de inteligencia artificial Claude (Anthropic) y Kilo Code.
