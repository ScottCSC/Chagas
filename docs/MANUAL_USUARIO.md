# Chagas Tracker — Manual de uso

Plataforma web para **registro epidemiológico territorial anónimo** de casos de Chagas en Monte Patria (Coquimbo, Chile).  
No es un sistema clínico: **no almacena nombre completo, RUT completo, teléfono, correo ni dirección exacta** del paciente.

---

## 1. Requisitos

| Requisito | Detalle |
|-----------|---------|
| Navegador | Chrome, Edge o Firefox (versión reciente) |
| Conexión | Internet estable (datos en Supabase) |
| Cuenta | Usuario creado por el administrador del programa |
| Dispositivo | Computador, tablet o celular (diseño responsivo) |

---

## 2. Inicio de sesión

1. Abra la URL de la aplicación en el navegador.
2. Ingrese **correo** y **contraseña** asignados por el administrador.
3. Pulse **Ingresar**.

**Mensajes frecuentes**

- *Correo o contraseña incorrectos* — revise credenciales.
- *Sin conexión con el servidor* — revise WiFi o datos móviles; no es un error de contraseña.

---

## 3. Navegación principal

Tras iniciar sesión aparecen cuatro secciones:

| Sección | Función |
|---------|---------|
| **Inicio** | Resumen: totales por estado, accesos rápidos, actividad reciente |
| **Nuevo caso** | Formulario de registro epidemiológico |
| **Ver casos** | Listado, búsqueda y filtros |
| **Perfil** | Cuenta del operador y cierre de sesión |

En **escritorio** (pantalla ancha) el menú está a la izquierda. En **móvil**, abajo.

Si aparece la franja naranja **Sin conexión**, la app puede mostrar los últimos datos cargados; las acciones que requieren servidor fallarán hasta recuperar internet.

---

## 4. Inicio (dashboard)

### Tarjetas de acceso rápido

- **Registrar nuevo caso** — abre el formulario de registro.
- **Ver casos** — va al listado (opción de enfocar el buscador).
- **Último caso registrado** — abre el detalle del caso más reciente (si existe).

### Estado actual (KPIs)

Muestra conteos de casos en:

- **Caso nuevo**
- **Reingreso**
- **Tratado**
- **Total**

Puede tocar una tarjeta para ir a **Ver casos** con ese filtro de estado aplicado.

### Sector con más casos

Si hay datos, muestra el sector con mayor cantidad de registros. Al tocarla, abre **Ver casos** filtrado por ese sector.

### Actividad reciente

Lista los últimos casos registrados. Toque una fila para ver el **detalle**.

**Actualizar datos:** deslice hacia abajo (pull-to-refresh) o cambie de pestaña y vuelva a Inicio.

---

## 5. Registrar un nuevo caso

Complete el formulario con datos **epidemiológicos y territoriales**, no identidad personal completa.

### Campos principales

| Campo | Descripción |
|-------|-------------|
| **Sector** | Sector censal / territorial (obligatorio) |
| **Identificador parcial** | Últimos 3 dígitos del documento + dígito verificador (formato `123-K`). **No ingrese el RUT completo.** |
| **Género** | Según opciones del formulario |
| **Fecha de nacimiento** | Para cálculo epidemiológico de edad/rango |
| **Ocupación** | Lista desde catálogo institucional; si no aplica, **No informa** |
| **Número de contactos** | Cantidad de contactos epidemiológicos (no nombres ni teléfonos) |
| **Observaciones** | Texto libre: **no escriba nombres, teléfonos, direcciones ni RUT completo** |

### Duplicados

Al guardar, el sistema puede detectar un caso similar (mismo sector, identificador parcial, fecha de nacimiento y género). En ese caso puede:

- **Cancelar**
- **Ver existente** — abre el caso ya registrado
- **Guardar de todos modos** — continúa el registro

### Guardar

1. Revise que el sector esté seleccionado y los campos obligatorios completos.
2. Pulse **Guardar caso**.
3. Tras éxito, se abre la **ficha del caso** o regresa al flujo anterior según cómo entró al formulario.

---

## 6. Ver casos (listado)

### Búsqueda

Escriba en el buscador: código de caso, sector, ocupación, rango etario o identificador parcial. La búsqueda se aplica con un breve retardo automático.

### Filtros por estado

Chips rápidos: **Todos**, **Caso nuevo**, **Reingreso**, **Tratado**.

### Filtros activos

Arriba aparecen chips removibles (estado, sector, etc.). Use **Limpiar** para quitar todos.

### Filtros avanzados

Abra el panel o modal de filtros para combinar criterios (género, sector, orden por fecha, etc.).

### Tarjetas de caso

Cada fila muestra código, sector, estado, edad efectiva y fecha. **Toque** una tarjeta para abrir el **detalle**.

### Actualizar

Deslice hacia abajo en la lista para recargar desde el servidor.

---

## 7. Detalle de un caso

### Contenido

- **Identificación epidemiológica:** identificador parcial, género, fecha de nacimiento, ocupación, contactos.
- **Ubicación territorial:** sector y comuna (sin dirección exacta).
- **Estado actual** y **historial de cambios de estado**.
- **Observaciones** del registro.

### Acciones (barra inferior)

| Acción | Función |
|--------|---------|
| **Cambiar estado** | Pasa el caso a Caso nuevo, Reingreso o Tratado |
| **Editar datos** | Modifica identificador parcial, género, fecha de nacimiento, ocupación y contactos |
| **Editar observación** | Actualiza el texto de observaciones (respete privacidad) |
| **Exportar** (icono) | Genera PDF del registro para respaldo institucional |

Tras editar estado o datos, al **volver al listado** la lista se actualiza automáticamente.

### Volver atrás

Use la flecha del navegador o del dispositivo. En móvil, el botón atrás del sistema primero vuelve a **Inicio** si está en otra pestaña.

---

## 8. Perfil

Muestra la **cuenta del operador** (correo, rol si está configurado) y avisos de privacidad del acceso autorizado.

- **Cerrar sesión** — finaliza la sesión; deberá volver a iniciar sesión para usar la app.

---

## 9. Buenas prácticas de privacidad

1. Use solo el **identificador parcial** (3 dígitos + DV), nunca el RUT completo.
2. No registre nombres, teléfonos, correos ni direcciones en observaciones.
3. El sector es **territorial agregado**, no domicilio exacto.
4. No comparta capturas de pantalla con datos sensibles fuera del equipo autorizado.
5. Cierre sesión al terminar en equipos compartidos.

---

## 10. Problemas frecuentes

| Situación | Qué hacer |
|-----------|-----------|
| Pantalla en blanco al abrir la URL | Espere la carga; recargue la página (F5) |
| KPIs en cero pero hay casos en Ver | Vaya a Inicio y espere la recarga, o pull-to-refresh |
| No carga el catálogo de ocupaciones | Revise conexión; reintente desde Editar datos |
| Sesión expirada al guardar | Vuelva a iniciar sesión |
| PDF no se abre en el navegador | Pruebe otro navegador o permita ventanas emergentes |

---

## 11. Soporte

Consultas técnicas o altas de usuario: contactar al **administrador del programa Chagas** / responsable del proyecto de tesis.

---

*Chagas Tracker — registro epidemiológico territorial. Versión documentada junto al repositorio del proyecto.*
