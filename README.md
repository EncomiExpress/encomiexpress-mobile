# EncomiExpress - App Flutter

Aplicación móvil para gestión de anticipos de conductores.

## Requisitos Previos

- Flutter SDK 3.11.0+
- Node.js 14+ (para el backend)
- PostgreSQL 12+

## Instalación

```bash
# 1. Instalar dependencias Flutter
cd EncomiExpress_Movil-Flutter
flutter pub get

# 2. Ejecutar la app
flutter run
```

## Configuración del Backend

El backend debe estar corriendo en `http://localhost:3000`

### Cambios en la Base de Datos (PostgreSQL)

**1. Permitir idRuta nulo en anticipoExcedente:**
```sql
ALTER TABLE "anticipoExcedente" ALTER COLUMN "idRuta" DROP NOT NULL;
```

**2. Permitir idRuta nulo en encomiendaVenta:**
```sql
ALTER TABLE "encomiendaVenta" ALTER COLUMN "idRuta" DROP NOT NULL;
```

**3. Crear usuario conductor (desde psql o pgAdmin):**

```sql
-- Insertar usuario
INSERT INTO usuario ("idRol", "tipoIdentificacion", "numeroIdentificacion", nombre, apellido, telefono, email, password, habilitado)
VALUES (
    3, 
    'CC', 
    '87654321', 
    'Conductor', 
    'Demo', 
    '3001234567', 
    'conductor@encomiexpress.com',
    '$2a$10$XveXAx1WR0eRp27VE0OXE.r3l8Sa3Kud1gMuOTrm8QvDIxN8KSxaa', 
    true
);

-- Insertar conductor (referenciando al usuario)
INSERT INTO conductor ("idUsuario", "categoriaLicencia", "numeroLicencia", "vencimientoLicencia", "estado", "habilitado")
VALUES (
    (SELECT "idUsuario" FROM usuario WHERE email = 'conductor@encomiexpress.com'),
    'B1',
    '87654321',
    '2027-12-31',
    'activo',
    true
);
```

**Nota:** La contraseña encriptada `'$2a$10$XveXAx1WR0eRp27VE0OXE.r3l8Sa3Kud1gMuOTrm8QvDIxN8KSxaa'` corresponde a `conductor123`

Para generar una nueva contraseña:
```bash
# En la terminal del backend
node -e "const bcrypt = require('bcryptjs'); bcrypt.hash('tuPassword', 10).then(h => console.log(h))"
```

## Credenciales de Prueba

| Rol | Email | Contraseña |
|-----|-------|-----------|
| Administrador | admin@encomiexpress.com | admin123 |
| Conductor | conductor@encomiexpress.com | conductor123 |

## Rutas de la API

- Backend: `http://localhost:3000`
- Login: `POST /api/auth/login`
- Anticipos: `GET/POST /api/anticipos`

## Estructura del Proyecto

```
lib/
├── config/           # Configuración (API, etc.)
├── models/          # Modelos de datos
├── screens/        # Pantallas UI
│   ├── admin/      # Vistas de administrador
│   └── driver/     # Vistas de conductor
├── services/       # Servicios API
└── widgets/        # Componentes reutilizables
```

## Estado de Implementación

### Conductor ✅
- Login
- Ver anticicipos asignados
- Actualizar anticipo (gasto, soporte, fecha legalización)
- Cerrar sesión

### Administrador ✅
- Login
- Crear anticipo
- Ver lista de anticipos
- Aprobar/Rechazar anticipos
- Editar anticipo

### Pendiente
- Subir archivos al servidor (manual por ahora)
- Ver imagen del soporte en la app

## Notas

- El campo `soporte` guarda solo el nombre del archivo. Los archivos deben copiarse manualmente a la carpeta `uploads/` del backend.
- Para ver el soporte: `http://localhost:3000/uploads/nombre_archivo`