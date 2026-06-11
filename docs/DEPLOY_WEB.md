# Despliegue web — Chagas Tracker

Checklist previo a publicar la app en hosting estático (Vercel, Netlify, Firebase, etc.).

---

## 1. Compilar en release

Desde la raíz del proyecto:

```powershell
flutter clean
flutter pub get
flutter build web --release `
  --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY_PUBLICA
```

**Desarrollo local** (sin subir secretos al bundle): puedes usar el mismo `.env` ignorado por git:

```powershell
flutter run -d edge --dart-define-from-file=.env
```

El archivo `.env` debe contener solo:

```
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=eyJ...
```

---

## 2. Secretos — qué sí y qué no

| Variable | ¿En el cliente Flutter? | Notas |
|----------|-------------------------|--------|
| `SUPABASE_URL` | Sí | URL pública del proyecto |
| `SUPABASE_ANON_KEY` | Sí | Clave **anon / public** (Settings → API en Supabase) |
| `service_role` | **Nunca** | Solo backend/scripts; bypass RLS |

- **No** incluir `.env` ni `.env.demo` en `pubspec.yaml` → assets.
- **No** commitear `.env` (está en `.gitignore`).
- La app solo inicializa Supabase con `anonKey` en `lib/main.dart`.

---

## 3. Supabase — autorizar la URL del deploy

En [Supabase Dashboard](https://supabase.com/dashboard) → tu proyecto:

### Authentication → URL Configuration

| Campo | Valor |
|-------|--------|
| **Site URL** | URL de producción, p. ej. `https://chagas-tracker.vercel.app` |
| **Redirect URLs** | La misma URL + `http://localhost:*` si pruebas en local |

Ejemplos de Redirect URLs (una por línea):

```
https://chagas-tracker.vercel.app/**
http://localhost:8080/**
http://127.0.0.1:8080/**
```

Para demo en la misma WiFi (opcional):

```
http://192.168.1.159:8080/**
```

(Sustituye por la IP de tu PC en el momento de la demo.)

### Verificar

- Login con email/contraseña funciona desde la URL desplegada.
- RLS activo en tablas expuestas (ver `docs/SUPABASE_RLS.md`).

---

## 4. Contenido a publicar

Sube **solo** el contenido de:

```
build/web/
```

No subas la carpeta `build/` completa ni el repositorio con `.env`.

---

## 5. Comprobación post-build

```powershell
# No debe existir .env dentro del artefacto web
Get-ChildItem -Recurse build\web -Filter ".env*" -ErrorAction SilentlyContinue
```

Si no devuelve archivos, el bundle no empaquetó secretos.

Sirve localmente el release:

```powershell
cd build\web
python -m http.server 8080 --bind 127.0.0.1
```

Abre `http://127.0.0.1:8080`, inicia sesión y prueba registrar/ver un caso.

---

## 6. Variables en CI (Vercel / Netlify)

En el panel del hosting, define variables de entorno y usa en el build command:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

Publish directory: `build/web`

---

*Última revisión alineada con `pubspec.yaml` sin assets `.env`.*
