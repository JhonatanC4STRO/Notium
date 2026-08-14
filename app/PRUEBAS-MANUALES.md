# Guion de pruebas manuales — Fase 3.6 (convergencia end-to-end)

Verificación del **criterio de salida de la fase 3**: CU-01 a CU-08 de punta a
punta, convergencia entre dos dispositivos (RNF-02) y sincronización < 30 s tras
recuperar red (RNF-06). Complementa al test automatizado
[`test/integration/convergencia_cu05_test.dart`](test/integration/convergencia_cu05_test.dart),
que ya cubre CU-05 a través del HTTP real contra el backend; aquí se valida la
capa de UI/emulador que ese test no toca.

## Preparación

1. **Backend accesible por ambos emuladores.** Dos opciones:
   - **Backend local** (`cd backend && npm run dev`): el emulador Android ve el
     host en `10.0.2.2` (ya es el default). Sirve para ambos emuladores.
   - **Backend en el VPS** (fase 1.6): usar la URL pública con TLS:
     `flutter run --dart-define=API_BASE_URL=https://api.tudominio.com/v1`.
2. **Dos dispositivos.** En Android Studio → Device Manager, crear/arrancar dos
   emuladores (o un emulador + un teléfono físico por USB). Verificar con
   `flutter devices` que aparecen los dos.
3. **Instalar la app en ambos** (en dos terminales):
   ```bash
   flutter run -d <emulador-1>
   flutter run -d <emulador-2>
   ```

En este guion, **A** y **B** son los dos dispositivos, con la **misma cuenta**.

---

## CU-01 / CU-02 — Registro y login (con y sin red)

1. En **A**: registrar una cuenta nueva (CU-01) → entra a la lista de notas.
2. En **B**: iniciar sesión con esa misma cuenta (CU-02 con red).
3. En **A**: activar modo avión y matar/reabrir la app → entra sin pedir login
   (CU-02 sin red: validación local del token). Desactivar modo avión.

## CU-04 — Nota + adjunto offline, sobrevive al cierre

1. En **A**: modo avión → crear una nota con contenido → adjuntar un archivo
   (< 10 MB) → matar la app (recientes) → reabrir aún sin red.
2. **Esperado**: nota y adjunto íntegros, con indicador ⏱ `PENDING` (RF-04).

## CU-08 — Adjunto que excede 10 MB

1. En **A**: intentar adjuntar un archivo > 10 MB
   (`adb shell "dd if=/dev/zero of=/sdcard/Download/grande.bin bs=1048576 count=11"`).
2. **Esperado**: aviso de rechazo; nada se persiste ni se reintenta.

## CU-05 — Conflicto de edición concurrente (el corazón de la fase)

> Este es el escenario que el test de integración ya verifica a nivel de datos;
> aquí se observa además el reflejo en la UI (RF-04) y el historial.

1. **Precondición**: en **A** crear una nota "Original" y esperar a que
   sincronice (indicador ⏱ → ☁✓). En **B**, esperar a que aparezca "Original"
   (o forzar el sync recuperando red). Ahora ambos la tienen sincronizada.
2. **Ambos offline**: activar modo avión en **A** y **B**.
3. En **A** (más tarde en el reloj real): editar el título a **"edición de A"**.
4. En **B** (antes que A, o simplemente el que reconecta después): editar el
   título a **"edición de B"**. Ambas quedan ⏱ `PENDING`.
5. **Reconectar A primero** (quitar modo avión). Esperar a que **A** muestre
   ☁✓ `SYNCED`. A es ahora el estado autoritativo.
6. **Reconectar B**. Al sincronizar, **B** recibe `409 CONFLICT`.
7. **Esperado (convergencia, RNF-02)**:
   - **A** y **B** muestran el **mismo** título: **"edición de A"** (ganó el
     `updated_at` más reciente, LWW).
   - En **B**, la nota queda ☁✓ `SYNCED` (adoptó el estado del servidor).
   - En **B**, el **historial** de la nota tiene una entrada
     `CONFLICTO_DESCARTADO` con "edición de B" (el cambio perdedor no se pierde,
     RF-05). *(La pantalla de historial es la tarea 4.1; hasta entonces se
     verifica en la BD: `adb shell run-as ...` o el test de integración.)*

## CU-06 — Eliminación con tombstone

1. En **A**: eliminar una nota sincronizada (confirmar el diálogo).
2. Esperar sync en **A**; luego en **B** al sincronizar la nota **desaparece**
   de la lista (tombstone propagado, sección 5.4).

## CU-03 — Refresh de token durante el sync

1. Para forzarlo rápido: en `backend/.env` poner `JWT_ACCESS_TTL_SEGUNDOS=15`,
   reiniciar el backend, iniciar sesión y esperar > 15 s antes de un sync.
2. **Esperado**: el sync funciona sin re-login (el interceptor refresca el token
   de forma transparente). Restaurar el TTL luego.

## CU-07 / RNF-06 — Red intermitente y latencia de sync

1. En **A**: modo avión → crear 2–3 notas (quedan ⏱ `PENDING`).
2. Quitar modo avión y **cronometrar**: los registros deben pasar a ☁✓ `SYNCED`
   en **< 30 s** (RNF-06). El disparo inmediato por `connectivity_plus` suele
   hacerlo en segundos; la tarea periódica de `workmanager` es el respaldo.
3. Repetir activando/desactivando la red varias veces a mitad de sync.
   **Esperado**: ningún registro se **duplica** ni se **pierde** (idempotencia
   por `(uuid, version, operacion, device_id)` en el servidor).

---

## Criterio de salida (marcar cuando pase)

- [ ] CU-01 a CU-08 pasan manualmente de punta a punta.
- [ ] Dos dispositivos convergen al mismo estado (RNF-02).
- [ ] Entrada `CONFLICTO_DESCARTADO` en el historial del perdedor (RF-05).
- [ ] Pendientes sincronizados en < 30 s tras recuperar red (RNF-06).
- [ ] Ningún escenario de red intermitente duplica ni pierde datos.

> El test automatizado `flutter test test/integration/convergencia_cu05_test.dart`
> (con el backend arriba) cubre CU-05, la convergencia y RF-05 sin emulador; este
> guion valida el resto de CU y la capa de UI.
