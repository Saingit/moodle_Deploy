#!/bin/sh
# =============================================================================
# php/install-moodle.sh
# Script de PRIMERA INSTALACIÓN de Moodle 5.1 (laboratorio, HTTP plano).
#
# Es idempotente: si detecta que Moodle ya está clonado y/o ya está instalado
# en la base de datos, salta esos pasos. Pensado para ejecutarse manualmente
# DENTRO del contenedor "php" una sola vez, no como CMD/entrypoint permanente
# (evita reinstalaciones accidentales si el contenedor se reinicia).
#
# Uso (desde el host, con el stack ya levantado):
#   docker compose exec php sh /var/www/install-moodle.sh
# =============================================================================
set -e

MOODLE_DIR="/var/www/html"
MOODLE_TAG="v5.1.0"            # Tag oficial estable, NO la rama *_STABLE.
MOODLE_REPO="https://github.com/moodle/moodle.git"

echo "==> [1/5] Verificando código fuente de Moodle en ${MOODLE_DIR}..."
if [ ! -f "${MOODLE_DIR}/public/version.php" ]; then
  echo "    No se encontró una instalación previa. Clonando ${MOODLE_TAG}..."
  # --depth 1 evita descargar todo el historial de Git (varios GB); solo
  # necesitamos el snapshot del tag, no el log de commits.
  git clone --branch "${MOODLE_TAG}" --depth 1 "${MOODLE_REPO}" /tmp/moodle-src
  # Se copia en vez de clonar directo en MOODLE_DIR porque ese path ya es
  # un volumen montado por Docker (no vacío de metadatos), y "git clone"
  # falla si el directoro destino no está completamente vacío.
  cp -a /tmp/moodle-src/. "${MOODLE_DIR}/"
  rm -rf /tmp/moodle-src
else
  echo "    Código ya presente, se omite la clonación."
fi

echo "==> [2/5] Ajustando permisos..."
# www-data (uid/gid 33) es el usuario bajo el que corre PHP-FPM dentro del
# contenedor. moodledata necesita ser de su propiedad para que Moodle pueda
# escribir cachés, sesiones y archivos subidos por los usuarios.
chown -R www-data:www-data "${MOODLE_DIR}" /var/www/moodledata
chmod -R 750 /var/www/moodledata

echo "==> [3/5] Esperando a que PostgreSQL esté disponible..."
# El healthcheck del servicio "db" en docker-compose.yml ya hace esperar a
# que Postgres esté listo antes de levantar "php", pero esta espera extra
# protege ante ejecuciones manuales del script fuera de ese orden.
until pg_isready -h "${POSTGRES_HOST:-db}" -p "${POSTGRES_PORT:-5432}" -U "${POSTGRES_USER}" > /dev/null 2>&1; do
  echo "    Postgres aún no responde, reintentando en 3s..."
  sleep 3
done

echo "==> [4/5] Verificando si Moodle ya está instalado en la base de datos..."
if php "${MOODLE_DIR}/admin/cli/isinstalled.php" > /dev/null 2>&1; then
  echo "    Moodle ya está instalado. No se ejecuta install.php de nuevo."
else
  echo "    Ejecutando instalador CLI de Moodle (modo no interactivo)..."
  # --non-interactive + --agree-license evita los prompts del wizard.
  # wwwroot se toma de MOODLE_SITE_URL (.env): para el laboratorio debe ser
  # http://<IP-del-servidor>, sin TLS.
  php "${MOODLE_DIR}/admin/cli/install.php" \
    --non-interactive \
    --agree-license \
    --wwwroot="${MOODLE_SITE_URL}" \
    --dataroot="/var/www/moodledata" \
    --dbtype="pgsql" \
    --dbhost="${POSTGRES_HOST:-db}" \
    --dbname="${MOODLE_DATABASE_NAME}" \
    --dbuser="${POSTGRES_USER}" \
    --dbpass="${POSTGRES_PASSWORD}" \
    --dbport="${POSTGRES_PORT:-5432}" \
    --fullname="Plataforma Moodle - Laboratorio" \
    --shortname="LAB-MOODLE" \
    --adminuser="${MOODLE_ADMIN_USER:-admin}" \
    --adminpass="${MOODLE_ADMIN_PASSWORD}" \
    --adminemail="${MOODLE_ADMIN_EMAIL:-admin@example.com}"
fi

echo "==> [5/5] Instalación finalizada."
echo "    Accede desde tu navegador a: ${MOODLE_SITE_URL}"
