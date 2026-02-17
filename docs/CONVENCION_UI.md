# Convención UI – Regla del proyecto (Chagas App)

Para que el equipo no se desordene con estilos y se evite el error de **ancho infinito** en `Row`, se usa esta convención única en toda la app.

---

## A) Formularios – Acciones principales

Usar **`Expanded`** en `Row` para acciones “grandes”:

- Crear / Guardar / Agregar existente  
- Cancelar / Guardar  

**Patrón estándar:**

```dart
Row(
  children: [
    Expanded(
      child: OutlinedButton(
        onPressed: () {},
        child: const Text('Cancelar'),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: ElevatedButton(
        onPressed: () {},
        child: const Text('Guardar'),
      ),
    ),
  ],
)
```

**Recomendación:** usar el widget reutilizable `FormActionsRow` (ver `lib/widgets/form_actions_row.dart`) para que todas las pantallas queden iguales con una sola línea.

**Ventaja:** se ve consistente y evita al 100% el error de ancho infinito.

---

## B) Acciones chicas tipo “chips”

Si son botones chicos (Filtrar, Más, Cambiar, Ordenar, etc.):

- Usar **`mainAxisSize: MainAxisSize.min`** en el `Row`.
- **No** usar `Expanded`.

**Ejemplo:**

```dart
Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    OutlinedButton(onPressed: () {}, child: const Text('Filtrar')),
    const SizedBox(width: 8),
    OutlinedButton(onPressed: () {}, child: const Text('Ordenar')),
  ],
)
```

---

## C) Regla de oro (para que nadie la cague)

### ❌ Nunca dentro de un `Row`

- `SizedBox(width: double.infinity)`
- `Container(width: double.infinity)`
- Botón con `fixedSize` / `minimumSize` usando `double.infinity` en ancho

### ✅ Siempre

- **`Expanded`** o **`Flexible`** si quieres que los hijos ocupen ancho en el `Row`.
- **`mainAxisSize: MainAxisSize.min`** si son botones chicos (chips).

---

## Resumen

| Contexto              | Solución                          |
|-----------------------|-----------------------------------|
| Acciones principales  | `Expanded` + botones (o `FormActionsRow`) |
| Chips / acciones chicas | `mainAxisSize: MainAxisSize.min`, sin `Expanded` |
| Evitar siempre        | `width: double.infinity` dentro de `Row` |
