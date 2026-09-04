# Versiones

La version sale de `pubspec.yaml` (`version: <versionName>+<versionCode>`).
Play Console rechaza un `versionCode` repetido: **subilo en cada build que se
sube**, aunque el `versionName` no cambie.

| versionName | versionCode | Fecha | Notas |
|---|---|---|---|
| 1.0.4 | 5 | 2026-09-04 | Tiempo real (live tracking, beacon pre-carrera) |
| 1.0.3 | 4 | 2026-09-03 | Rol de organizador |
| 1.0.2 | 3 | 2026-08-29 | Busqueda de usuarios, fix permisos GPS y mapas |
| 1.0.1 | 2 | 2026-08-29 | Rebuild: el code 1 ya estaba usado en Play |
| 1.0.0 | 1 | 2026-08-29 | Primera subida (rechazada por code duplicado) |

Despues de tocar `pubspec.yaml`, regenerar el bundle con `make aab`.
