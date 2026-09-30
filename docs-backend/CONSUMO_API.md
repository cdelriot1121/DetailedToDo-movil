# Guía de consumo — DetailedToDo API

## Puesta en marcha

Requiere Java 21, Maven y MongoDB. Define estas variables (para local puedes partir de `.env`):

```properties
SPRING_MONGODB_LOCAL=mongodb://localhost:27017
MONGODB_LOCAL_DATABASE=LocalDetailedToDo
JWT_SECRET=<clave aleatoria de al menos 32 caracteres>
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
API_KEY_GEMINI=<clave-de-google-ai-studio>
JWT_EXPIRATION_MS=86400000
GEMINI_MODEL=gemini-3.1-flash-lite
```

En Windows ejecuta `.\mvnw.cmd spring-boot:run`. La API queda en `http://localhost:8000/api`.

Para Atlas/producción, inyecta `SPRING_MONGODB_URI` y `MONGODB_PRODUCTION_DATABASE` con un perfil de producción. No subas URI, contraseñas ni `JWT_SECRET` al repositorio. La URI de Atlas que existe en `.env` debe rotarse si se ha compartido.

## Autenticación

`POST /api/auth/register`

```json
{"name":"Carlos","email":"carlos@example.com","password":"una-clave-segura"}
```

`POST /api/auth/login` devuelve `{ "token": "...", "user": { ... } }`. Guarda el token, por ejemplo usando `flutter_secure_storage`, y envíalo en las rutas privadas:

```http
Authorization: Bearer <token>
Content-Type: application/json
```

El propietario se obtiene del token; Flutter nunca envía `userId`.

## Rutas protegidas

| Recurso | Operaciones |
| --- | --- |
| Usuario | `GET`, `PUT /api/users/me` |
| Notas | CRUD en `/api/notes` |
| Tareas | CRUD en `/api/tasks`; `PATCH /{id}/status` |
| Subtareas | `POST /{id}/subtasks`, `PATCH`/`DELETE /{id}/subtasks/{subtaskId}` |
| Eventos | CRUD en `/api/events` |

Los `POST` devuelven 201 y los borrados 204. Tareas filtra por `status`, `priority`, `folder`, `tag`; notas por `folder`, `tag`; eventos por `from`, `to` ISO-8601. Estados: `PENDING`, `IN_PROGRESS`, `COMPLETED`; prioridades: `LOW`, `MEDIUM`, `HIGH`.

## Catálogo REST completo

La base es `http://localhost:8000/api`; por ello, por ejemplo, la fila `/tasks` significa `http://localhost:8000/api/tasks`. Todos los cuerpos se envían como `Body > raw > JSON` en Postman. Salvo `register` y `login`, todas las rutas requieren `Authorization: Bearer <token>`.

### Autenticación y usuario

| Método | Ruta | Cuerpo |
| --- | --- | --- |
| POST | `/auth/register` | `{"name":"Carlos","email":"carlos@email.com","password":"carlos@11"}` |
| POST | `/auth/login` | `{"email":"carlos@email.com","password":"carlos@11"}` |
| GET | `/users/me` | Sin cuerpo |
| PUT | `/users/me` | `{"name":"Nuevo nombre"}` |

`login` devuelve `token` y `user`; usa sólo el valor de `token` como Bearer token.

### Notas

| Método | Ruta | Cuerpo |
| --- | --- | --- |
| POST | `/notes` | `{"title":"Ideas","content":"...","tags":["proyecto"],"folder":"Personal"}` |
| GET | `/notes?folder=Personal&tag=proyecto` | Sin cuerpo; ambos filtros son opcionales. |
| GET | `/notes/{id}` | Sin cuerpo |
| PUT | `/notes/{id}` | Mismo cuerpo que `POST /notes` |
| DELETE | `/notes/{id}` | Sin cuerpo |

### Tareas y subtareas

| Método | Ruta | Cuerpo |
| --- | --- | --- |
| POST | `/tasks` | JSON de tarea mostrado abajo |
| GET | `/tasks?status=PENDING&priority=HIGH&folder=Universidad&tag=mineria` | Sin cuerpo; cada filtro es opcional. |
| GET | `/tasks/{id}` | Sin cuerpo |
| PUT | `/tasks/{id}` | Mismo cuerpo que `POST /tasks` |
| PATCH | `/tasks/{id}/status` | `{"status":"COMPLETED"}` |
| DELETE | `/tasks/{id}` | Sin cuerpo |
| POST | `/tasks/{id}/subtasks` | `{"title":"Instalar RStudio","description":"Preparar entorno","status":"PENDING","order":1}` |
| PATCH | `/tasks/{id}/subtasks/{subtaskId}` | Mismo cuerpo que crear subtarea |
| DELETE | `/tasks/{id}/subtasks/{subtaskId}` | Sin cuerpo |

```json
{
  "title":"Estudiar minería de datos",
  "description":"Repasar conceptos.",
  "priority":"HIGH",
  "dueDate":"2026-10-02T23:59:00",
  "reminderDate":"2026-10-02T08:00:00",
  "folder":"Universidad",
  "tags":["mineria","estudio"]
}
```

### Eventos

| Método | Ruta | Cuerpo |
| --- | --- | --- |
| POST | `/events` | `{"title":"Presentación","description":"Proyecto final","dateTime":"2026-10-02T10:00:00","reminderDate":"2026-10-01T10:00:00","tags":["universidad"]}` |
| GET | `/events?from=2026-10-01T00:00:00&to=2026-10-07T23:59:59` | Sin cuerpo; fechas opcionales. |
| GET | `/events/{id}` | Sin cuerpo |
| PUT | `/events/{id}` | Mismo cuerpo que crear evento |
| DELETE | `/events/{id}` | Sin cuerpo |

Ejemplo de tarea:

```json
{"title":"Estudiar minería de datos","description":"Repasar conceptos.","priority":"HIGH","dueDate":"2026-10-02T23:59:00","folder":"Universidad","tags":["mineria"]}
```

Actualización de estado:

```json
{"status":"COMPLETED"}
```

Errores usan `{ "status", "error", "message", "timestamp" }`: 400 validación, 401 token inválido/ausente, 403 sin permiso, 404 no existe/no pertenece al usuario, y 409 correo repetido.

## Docker

```bash
docker build -t detailed-todo-backend .
docker run --rm -p 8000:8000 --env-file .env -e JWT_SECRET='<clave-larga-y-secreta>' detailed-todo-backend
```

Desde Docker, Mongo local no es `localhost`: en Docker Desktop usa `SPRING_MONGODB_LOCAL=mongodb://host.docker.internal:27017`.

## IA

La IA requiere JWT y recibe solamente texto natural:

```json
{"content":"Tengo que entregar la actividad de minería de datos este viernes y usar RStudio."}
```

| Ruta | Resultado |
| --- | --- |
| `GET /api/ai/quota` | Uso y solicitudes restantes hoy. |
| `POST /api/tasks/ai` | Crea una tarea y devuelve su JSON; las subtareas se completan en segundo plano. |
| `POST /api/tasks/{id}/subtasks/ai` | Devuelve `202` y cambia `subtasksGenerationStatus` a `PENDING`. |
| `POST /api/notes/ai` | Crea y devuelve una nota estructurada. |
| `POST /api/events/ai` | Crea y devuelve un evento estructurado. |

Ejemplo para cualquiera de `POST /api/tasks/ai`, `/api/notes/ai` y `/api/events/ai`:

```json
{
  "content":"Tengo que entregar la actividad de minería de datos este viernes y usar RStudio."
}
```

`POST /api/tasks/{id}/subtasks/ai` no recibe cuerpo: sólo el Bearer token. Responde `202 Accepted`; consulta después `GET /api/tasks/{id}` hasta que `subtasksGenerationStatus` sea `COMPLETED` o `FAILED`.

Los planes tienen 5 (Free) y 15 (Plus) solicitudes por día. La creación de tarea con IA usa una solicitud para interpretar la tarea y otra para generar subtareas; si no queda cuota, la tarea se conserva y el estado de subtareas termina en `FAILED`. La IA devuelve JSON estructurado, pero el backend sigue asignando el propietario desde JWT y valida los datos antes de persistirlos.
