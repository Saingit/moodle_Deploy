# Moodle Deploy — Stack Docker de producción/laboratorio

Despliegue modular de **Moodle 5.1** con Docker Compose:

- **db** — PostgreSQL 18
- **php** — PHP 8.3-FPM con extensiones requeridas por Moodle
- **web** — Nginx (único servicio expuesto al exterior)
- **cron** — ejecuta `admin/cli/cron.php` cada minuto en contenedor dedicado

Estado actual: **fase de laboratorio**, acceso por IP en intranet vía HTTP
(sin TLS). Ver notas de migración a producción más abajo.

## Requisitos

- Docker Engine + Docker Compose plugin
- Ubuntu Server 26.04 (o cualquier host compatible con Docker)

## Puesta en marcha

1. Clona este repositorio en el servidor:
   ```bash
   git clone https://github.com/Saingit/moodle_Deploy.git
   cd moodle_Deploy
   ```

2. Copia el archivo de variables de entorno y edítalo con tus propios valores
   (contraseñas, IP del servidor, credenciales del admin):
   ```bash
   cp .env.example .env
   nano .env
   ```

3. Levanta el stack:
   ```bash
   docker compose up -d --build
   ```

4. Ejecuta la primera instalación de Moodle (clona el código, ajusta
   permisos y corre el instalador CLI; es idempotente):
   ```bash
   docker compose exec php sh /var/www/install-moodle.sh
   ```

5. Accede desde el navegador a la URL que definiste en `MOODLE_SITE_URL`
   (ej. `http://192.168.1.50`).

## Estructura

```
.
├── docker-compose.yml
├── .env.example
├── nginx/conf.d/moodle.conf   # Webroot apunta a /var/www/html/public (Moodle 5.1+)
└── php/
    ├── Dockerfile             # PHP 8.3-FPM + extensiones Moodle
    ├── php.ini                # Límites recomendados (memoria, uploads, opcache)
    └── install-moodle.sh      # Script de primera instalación
```

## Notas clave

- **moodledata** vive en un volumen Docker separado, nunca dentro del
  docroot servido por Nginx.
- **Webroot real**: desde Moodle 5.1, `config.php` vive en la raíz del
  código clonado, fuera del directorio servido por el navegador. Nginx
  sirve únicamente desde `public/`.
- El stack usa el **tag oficial** `v5.1.0` (no la rama `*_STABLE`, que
  recibe actualizaciones semanales no recomendadas para producción).

## Migración a producción (dominio + TLS)

Pendiente cuando se pase de laboratorio a producción:

1. Apuntar un dominio real al servidor.
2. Obtener certificados (ej. Let's Encrypt) y montarlos en `nginx/certs/`.
3. Restaurar el bloque `listen 443 ssl` en `nginx/conf.d/moodle.conf` y la
   redirección HTTP → HTTPS.
4. Volver a publicar el puerto `443` en `docker-compose.yml`.
5. Actualizar `MOODLE_SITE_URL` a `https://tu-dominio` y ajustar `wwwroot`
   desde *Administración del sitio > Servidor > HTTP/HTTPS* dentro de Moodle.
