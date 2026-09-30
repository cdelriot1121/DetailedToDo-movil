# Documentación Completa y Guía de Consumo de la API de DetailedToDo Backend

Bienvenido a la documentación técnica y de integración oficial del backend de **DetailedToDo**. Este documento está diseñado específicamente para desarrolladores frontend y móviles (Flutter, Web, etc.) que necesitan integrar todos los endpoints del servicio backend de manera robusta, conociendo los flujos de autenticación, manejo de errores, esquemas de datos exactos, capacidades de Inteligencia Artificial (Google Gemini) y consideraciones de arquitectura.

---

## 1. Información General y Configuración del Servidor

- **URL Base Local:** `http://localhost:8000/api`
- **Formato de Solicitudes y Respuestas:** JSON (`Content-Type: application/json`)
- **Autenticación:** JSON Web Tokens (JWT) mediante el header HTTP `Authorization: Bearer <token>`.
- **Zona Horaria de Fechas:** Formato estándar **ISO-8601** (`yyyy-MM-dd'T'HH:mm:ss`), ejemplo: `2026-10-02T23:59:00`.

### Variables de Entorno del Backend
Para levantar o desplegar el servidor correctamente, asegúrate de configurar:
```properties
SPRING_MONGODB_LOCAL=mongodb://localhost:27017
MONGODB_LOCAL_DATABASE=LocalDetailedToDo
JWT_SECRET=<clave secreta aleatoria de al menos 32 caracteres>
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
API_KEY_GEMINI=<clave-de-google-ai-studio>
JWT_EXPIRATION_MS=86400000
GEMINI_MODEL=gemini-3.1-flash-lite
```

---

## 2. Flujo de Autenticación y Seguridad

El sistema utiliza autenticación basada en JWT. El flujo completo para una aplicación cliente es el siguiente:

1. **Registro o Inicio de Sesión**: El usuario se registra (`POST /api/auth/register`) o inicia sesión (`POST /api/auth/login`).
2. **Obtención del Token**: El backend responde con un objeto que contiene el token JWT y los datos del perfil del usuario.
3. **Almacenamiento Seguro**: La aplicación móvil debe guardar el token de forma segura (ej. utilizando `flutter_secure_storage`).
4. **Envío en Peticiones Protegidas**: En cada solicitud subsiguiente a rutas protegidas, se debe enviar la cabecera:
   ```http
   Authorization: Bearer <token_jwt_almacenado>
   Content-Type: application/json
   ```
   *Nota importante:* El backend extrae automáticamente el ID del usuario (`userId`) desde el token JWT decodificado. El cliente **nunca** debe enviar el `userId` en los cuerpos de las solicitudes de recursos.

---

## 3. Catálogo Detallado de Endpoints

### A. Autenticación (`/api/auth`)

#### 1. Registrar Nuevo Usuario
- **Método:** `POST`
- **Ruta:** `/api/auth/register`
- **Autenticación:** Pública (No requiere Token)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "name": "Carlos Pérez",
    "email": "carlos@example.com",
    "password": "PasswordSeguro123"
  }
  ```
- **Respuestas:**
  - `201 Created`: Retorna el token JWT y los datos del usuario.
  - `400 Bad Request`: Datos inválidos o campos faltantes.
  - `409 Conflict`: El correo electrónico ya está registrado.

#### 2. Iniciar Sesión (Login)
- **Método:** `POST`
- **Ruta:** `/api/auth/login`
- **Autenticación:** Pública (No requiere Token)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "email": "carlos@example.com",
    "password": "PasswordSeguro123"
  }
  ```
- **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsIn...",
    "user": {
      "id": "670f...abc",
      "name": "Carlos Pérez",
      "email": "carlos@example.com",
      "role": "USER",
      "plan": "FREE"
    }
  }
  ```

---

### B. Gestión de Usuario (`/api/users`)

#### 1. Obtener Perfil del Usuario Actual
- **Método:** `GET`
- **Ruta:** `/api/users/me`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo:** Ninguno.
- **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "id": "670f...abc",
    "name": "Carlos Pérez",
    "email": "carlos@example.com",
    "role": "USER",
    "plan": "FREE"
  }
  ```

#### 2. Actualizar Perfil del Usuario
- **Método:** `PUT`
- **Ruta:** `/api/users/me`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "name": "Carlos Alberto Pérez"
  }
  ```
- **Respuesta Exitosa (`200 OK`):** Retorna el objeto de usuario actualizado.

---

### C. Notas (`/api/notes`)

Las notas permiten almacenar información enriquecida, ideas o textos libres organizados por carpetas y etiquetas.

#### 1. Crear Nota
- **Método:** `POST`
- **Ruta:** `/api/notes`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "title": "Ideas para el proyecto",
    "content": "Investigar arquitecturas limpias y patrones en Flutter.",
    "tags": ["proyecto", "flutter"],
    "folder": "Desarrollo"
  }
  ```
- **Respuesta Exitosa (`201 Created`):** Retorna la nota creada incluyendo su ID autogenerado y marcas de tiempo (`createdAt`, `updatedAt`).

#### 2. Listar Notas (con filtros opcionales)
- **Método:** `GET`
- **Ruta:** `/api/notes`
- **Parámetros de Consulta (Query Params - Opcionales):**
  - `folder` (string): Filtrar por nombre de carpeta exacto.
  - `tag` (string): Filtrar por etiqueta específica.
- **Ejemplo:** `/api/notes?folder=Desarrollo&tag=flutter`
- **Respuesta Exitosa (`200 OK`):** Lista en formato JSON de objetos de notas del usuario autenticado.

#### 3. Obtener Nota por ID
- **Método:** `GET`
- **Ruta:** `/api/notes/{id}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Respuesta Exitosa (`200 OK`):** Objeto de la nota solicitada.
- **Respuestas de Error:** `404 Not Found` si la nota no existe o pertenece a otro usuario.

#### 4. Actualizar Nota
- **Método:** `PUT`
- **Ruta:** `/api/notes/{id}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):** Mismo formato que `POST /api/notes`.
- **Respuesta Exitosa (`200 OK`):** Nota actualizada.

#### 5. Eliminar Nota
- **Método:** `DELETE`
- **Ruta:** `/api/notes/{id}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Respuesta Exitosa (`204 No Content`):** Sin cuerpo de respuesta.

---

### D. Tareas y Subtareas (`/api/tasks`)

El núcleo de la aplicación DetailedToDo. Permite gestionar tareas detalladas con prioridades, fechas límite, recordatorios, carpetas, etiquetas y una lista estructurada de subtareas.

#### 1. Crear Tarea
- **Método:** `POST`
- **Ruta:** `/api/tasks`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "title": "Estudiar minería de datos",
    "description": "Repasar conceptos clave de algoritmos de clustering.",
    "priority": "HIGH",
    "dueDate": "2026-10-02T23:59:00",
    "reminderDate": "2026-10-02T08:00:00",
    "folder": "Universidad",
    "tags": ["mineria", "estudio"]
  }
  ```
  *Valores permitidos para `priority`:* `LOW`, `MEDIUM`, `HIGH`.
- **Respuesta Exitosa (`201 Created`):** Tarea creada con estado inicial `PENDING` y lista de subtareas vacía.

#### 2. Listar Tareas (con filtros opcionales)
- **Método:** `GET`
- **Ruta:** `/api/tasks`
- **Parámetros de Consulta (Query Params - Opcionales):**
  - `status` (`PENDING`, `IN_PROGRESS`, `COMPLETED`)
  - `priority` (`LOW`, `MEDIUM`, `HIGH`)
  - `folder` (string)
  - `tag` (string)
- **Ejemplo:** `/api/tasks?status=PENDING&priority=HIGH`
- **Respuesta Exitosa (`200 OK`):** Lista de tareas filtradas.

#### 3. Obtener Tarea por ID
- **Método:** `GET`
- **Ruta:** `/api/tasks/{id}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Respuesta Exitosa (`200 OK`):** Objeto detallado de la tarea, incluyendo sus subtareas y el estado de generación de IA (`subtasksGenerationStatus`: `IDLE`, `PENDING`, `COMPLETED`, `FAILED`).

#### 4. Actualizar Tarea Completa
- **Método:** `PUT`
- **Ruta:** `/api/tasks/{id}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):** Mismo formato que `POST /api/tasks`.
- **Respuesta Exitosa (`200 OK`):** Tarea actualizada.

#### 5. Actualizar Estado Rápido de Tarea
- **Método:** `PATCH`
- **Ruta:** `/api/tasks/{id}/status`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "status": "COMPLETED"
  }
  ```
  *(Estados válidos: `PENDING`, `IN_PROGRESS`, `COMPLETED`)*
- **Respuesta Exitosa (`200 OK`):** Tarea actualizada.

#### 6. Eliminar Tarea
- **Método:** `DELETE`
- **Ruta:** `/api/tasks/{id}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Respuesta Exitosa (`204 No Content`):** Sin cuerpo.

#### 7. Agregar Subtarea a una Tarea
- **Método:** `POST`
- **Ruta:** `/api/tasks/{id}/subtasks`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "title": "Instalar RStudio y paquetes",
    "description": "Preparar entorno de trabajo local.",
    "status": "PENDING",
    "order": 1
  }
  ```
- **Respuesta Exitosa (`201 Created`):** Retorna la tarea completa con la nueva subtarea añadida.

#### 8. Actualizar Subtarea
- **Método:** `PATCH`
- **Ruta:** `/api/tasks/{id}/subtasks/{subtaskId}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):** Mismo formato que al crear subtarea.
- **Respuesta Exitosa (`200 OK`):** Tarea actualizada.

#### 9. Eliminar Subtarea
- **Método:** `DELETE`
- **Ruta:** `/api/tasks/{id}/subtasks/{subtaskId}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Respuesta Exitosa (`200 OK`):** Retorna la tarea sin la subtarea eliminada.

---

### E. Eventos (`/api/events`)

Gestión de eventos agendados con fecha y hora específica, recordatorios y etiquetas.

#### 1. Crear Evento
- **Método:** `POST`
- **Ruta:** `/api/events`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "title": "Presentación Final",
    "description": "Defensa del proyecto ante el comité evaluador.",
    "dateTime": "2026-10-02T10:00:00",
    "reminderDate": "2026-10-01T10:00:00",
    "tags": ["universidad", "importante"]
  }
  ```
- **Respuesta Exitosa (`201 Created`):** Objeto de evento creado.

#### 2. Listar Eventos (con rango de fechas opcional)
- **Método:** `GET`
- **Ruta:** `/api/events`
- **Parámetros de Consulta (Query Params - Opcionales):**
  - `from` (ISO-8601, ej. `2026-10-01T00:00:00`)
  - `to` (ISO-8601, ej. `2026-10-07T23:59:59`)
- **Respuesta Exitosa (`200 OK`):** Lista de eventos en el rango especificado.

#### 3. Obtener Evento por ID
- **Método:** `GET`
- **Ruta:** `/api/events/{id}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Respuesta Exitosa (`200 OK`):** Objeto de evento.

#### 4. Actualizar Evento
- **Método:** `PUT`
- **Ruta:** `/api/events/{id}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):** Mismo formato que `POST /api/events`.
- **Respuesta Exitosa (`200 OK`):** Evento actualizado.

#### 5. Eliminar Evento
- **Método:** `DELETE`
- **Ruta:** `/api/events/{id}`
- **Autenticación:** Requerida (`Bearer Token`)
- **Respuesta Exitosa (`204 No Content`):** Sin cuerpo.

---

### F. Inteligencia Artificial / Google Gemini (`/api/ai` y flujos inteligentes)

La aplicación incorpora integración avanzada con Google Gemini para procesar texto en lenguaje natural y convertirlo automáticamente en tareas estructuradas (con subtareas), notas o eventos, respetando cuotas diarias según el plan del usuario (Plan Free: 5 solicitudes/día; Plan Plus: 15 solicitudes/día).

#### 1. Consultar Cuota de IA Actual
- **Método:** `GET`
- **Ruta:** `/api/ai/quota`
- **Autenticación:** Requerida (`Bearer Token`)
- **Respuesta Exitosa (`200 OK`):**
  ```json
  {
    "plan": "FREE",
    "dailyLimit": 5,
    "usedToday": 2,
    "remaining": 3
  }
  ```

#### 2. Crear Tarea con IA a partir de Texto Libre
- **Método:** `POST`
- **Ruta:** `/api/tasks/ai`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "content": "Tengo que entregar la actividad de minería de datos este viernes a las 11pm y usar RStudio."
  }
  ```
- **Respuesta Exitosa (`201 Created`):** Crea y retorna el objeto `Task` interpretado por la IA. Las subtareas se generan de forma concurrente o asíncrona.

#### 3. Solicitar Generación Asíncrona de Subtareas para una Tarea Existente
- **Método:** `POST`
- **Ruta:** `/api/tasks/{taskId}/subtasks/ai`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo:** Ninguno.
- **Respuesta Exitosa (`202 Accepted`):** Cambia el campo `subtasksGenerationStatus` de la tarea a `PENDING`.
- **Flujo de Consumo recomendado en la App Móvil:**
  1. Llamar a `POST /api/tasks/{taskId}/subtasks/ai`.
  2. Recibir `202 Accepted`.
  3. Realizar sondeos (polling) periódicos a `GET /api/tasks/{taskId}` hasta que `subtasksGenerationStatus` cambie a `COMPLETED` o `FAILED`.

#### 4. Crear Nota con IA a partir de Texto Libre
- **Método:** `POST`
- **Ruta:** `/api/notes/ai`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "content": "Resumen de la reunión de arquitectura: se decidió usar MongoDB y Spring Boot por velocidad de desarrollo."
  }
  ```
- **Respuesta Exitosa (`201 Created`):** Retorna la nota estructurada creada automáticamente.

#### 5. Crear Evento con IA a partir de Texto Libre
- **Método:** `POST`
- **Ruta:** `/api/events/ai`
- **Autenticación:** Requerida (`Bearer Token`)
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "content": "Cita con el doctor el próximo martes a las 4 de la tarde en el consultorio 302."
  }
  ```
- **Respuesta Exitosa (`201 Created`):** Retorna el evento estructurado creado automáticamente.

---

## 4. Manejo Estándar de Errores

Ante cualquier fallo en las peticiones, el backend responde con un objeto JSON estructurado con el siguiente formato:

```json
{
  "timestamp": "2026-10-02T12:34:56.789",
  "status": 400,
  "error": "Bad Request",
  "message": "Validation failed for object...",
  "path": "/api/tasks"
}
```

### Códigos de Estado HTTP Principales:
- **`200 OK`**: Solicitud exitosa (GET, PUT, PATCH).
- **`201 Created`**: Recurso creado exitosamente (POST).
- **`204 No Content`**: Recurso eliminado exitosamente (DELETE).
- **`202 Accepted`**: Solicitud aceptada para procesamiento en segundo plano (ej. IA de subtareas).
- **`400 Bad Request`**: Error de validación en los campos enviados o cuerpo JSON malformado.
- **`401 Unauthorized`**: Token JWT ausente, expirado o inválido.
- **`403 Forbidden`**: El usuario no tiene permisos para realizar la acción.
- **`404 Not Found`**: El recurso solicitado no existe o no pertenece al usuario autenticado.
- **`409 Conflict`**: Conflicto de unicidad (ej. intento de registro con un correo electrónico ya existente).

---

## 5. Recomendaciones de Integración para la App Móvil (Flutter)

1. **Gestión de Estado y Repositorio API:**
   Utiliza un cliente HTTP robusto como `Dio` o `http` configurado con un interceptor que inyecte automáticamente el token Bearer en cada petición a `/api/...`.
2. **Manejo de Fechas:**
   Asegúrate de serializar y deserializar las fechas utilizando `DateTime.toIso8601String()` para evitar discrepancias de formato con el backend en Java.
3. **Manejo de Errores en UI:**
   Captura los códigos 401 para redirigir automáticamente al usuario a la pantalla de Login cuando su sesión caduque.
4. **Pruebas en Postman:**
   Puedes importar este documento o utilizar el archivo `docs/CONSUMO_API.md` como referencia rápida para probar directamente las colecciones en Postman utilizando entorno local o de producción.


---

## Nuevo Catalogo para OTP

### A. Autenticación (`/api/auth`)

#### 1. Registrar Nuevo Usuario — Paso 1 de 2: Solicitar OTP
- **Método:** `POST`
- **Ruta:** `/api/auth/register`
- **Autenticación:** Pública (No requiere Token)
- **Descripción:** Valida los datos y, si el email no está registrado, almacena el usuario **pendiente en Redis** y
  envía un código OTP al correo mediante Brevo. El usuario **no se persiste en MongoDB** hasta confirmar el código.
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "name": "Carlos Pérez",
    "email": "carlos@example.com",
    "password": "PasswordSeguro123"
  }
  ```
- **Campos:**

  | Campo | Tipo | Requerido | Validación |
    |---|---|---|---|
  | `name` | string | ✅ | No vacío, máx. 100 caracteres |
  | `email` | string | ✅ | Formato email válido, máx. 254 chars |
  | `password` | string | ✅ | Mín. 8 caracteres, máx. 72 |

- **Respuestas:**
  - `202 Accepted`: OTP enviado al correo. Mostrar pantalla de verificación de código.
  - `400 Bad Request`: Datos inválidos o campos faltantes.
  - `409 Conflict`: El correo electrónico ya está registrado.

> ⚠️ **El OTP expira en 5 minutos.** Si el usuario no confirma a tiempo, debe volver a registrarse desde el paso 1.

---

#### 2. Registrar Nuevo Usuario — Paso 2 de 2: Confirmar OTP
- **Método:** `POST`
- **Ruta:** `/api/auth/verify-otp`
- **Autenticación:** Pública (No requiere Token)
- **Descripción:** Verifica el código OTP ingresado. Si es correcto: **crea el usuario en MongoDB**, borra el código y
  los datos pendientes de Redis (uso único), y devuelve el token JWT listo para usar.
- **Cuerpo de la Solicitud (JSON):**
  ```json
  {
    "email": "carlos@example.com",
    "code": "485920"
  }
  ```
- **Campos:**

  | Campo | Tipo | Requerido | Validación |
    |---|---|---|---|
  | `email` | string | ✅ | Debe coincidir exactamente con el del Paso 1 |
  | `code` | string | ✅ | Exactamente 6 dígitos numéricos |

- **Respuesta Exitosa (`201 Created`):**
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsIn...",
    "user": {
      "id": "670f...abc",
      "name": "Carlos Pérez",
      "email": "carlos@example.com",
      "role": "USER",
      "plan": "FREE"
    }
  }
  ```
- **Respuestas de Error:**
  - `400 Bad Request`: Código inválido, no coincide, o ya expiró en Redis.
  - `409 Conflict`: El email fue registrado desde otro dispositivo durante la ventana del OTP.

>  Tras recibir el `201`, guarda el `token` con `flutter_secure_storage` y navega al home. El usuario ya está
autenticado.

---
