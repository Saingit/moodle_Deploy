# =============================================================================
# php/Dockerfile
# PHP 8.3-FPM + extensiones requeridas por Moodle 5.1
# =============================================================================
FROM php:8.3-fpm

# Dependencias de sistema necesarias para compilar/usar las extensiones PHP.
# Se incluye "locales" para poder generar los locales que Moodle necesita
# (es_CO.UTF-8 y en_US.UTF-8); sin esto, Moodle solo encuentra C/C.utf8/POSIX
# y cae al locale global del sistema host (ej. en_AU.UTF-8) para fechas y
# formato de números.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libxml2-dev \
    libxslt1-dev \
    libcurl4-openssl-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    libicu-dev \
    libsodium-dev \
    unzip \
    git \
    postgresql-client \
    locales \
    && rm -rf /var/lib/apt/lists/*s

# Generación de locales: Debian no trae locales generados por defecto (solo
# C/C.utf8/POSIX) para no inflar la imagen con todos los idiomas posibles.
# Hay que descomentar explícitamente las líneas deseadas en /etc/locale.gen
# y correr locale-gen. Se generan es_CO.UTF-8 (español Colombia, idioma
# principal del sitio) y en_US.UTF-8 (inglés, idioma base de Moodle/fallback).
RUN sed -i -e 's/# es_CO.UTF-8 UTF-8/es_CO.UTF-8 UTF-8/' \
           -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen

# Variables de entorno de locale por defecto del sistema dentro del
# contenedor. Moodle internamente usa su propio selector de idioma por
# usuario/sitio, pero estas variables son las que consultan funciones de PHP
# como setlocale()/strftime() cuando Moodle no especifica un locale exacto.
ENV LANG=es_CO.UTF-8 \
    LANGUAGE=es_CO:en_US \
    LC_ALL=es_CO.UTF-8

# Extensiones requeridas/recomendadas por Moodle:
# pgsql (BD), gd (imágenes), intl (i18n), mbstring (cadenas), xml/xsl,
# zip (backups/cursos), soap (webservices), opcache (rendimiento), sodium.
RUN docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install -j$(nproc) \
        pdo_pgsql \
        pgsql \
        gd \
        intl \
        mbstring \
        xsl \
        zip \
        soap \
        opcache \
        sodium \
        exif \
        curl \
    && pecl install apcu \
    && docker-php-ext-enable apcu

# Configuración recomendada de PHP para Moodle en producción.
COPY php.ini /usr/local/etc/php/conf.d/moodle-recommended.ini

# Script de primera instalación (clona Moodle, ajusta permisos, corre el
# instalador CLI). Se ejecuta manualmente vía "docker compose exec", NO
# como CMD/entrypoint del contenedor.
COPY install-moodle.sh /var/www/install-moodle.sh
RUN chmod +x /var/www/install-moodle.sh

WORKDIR /var/www/html

# NOTA sobre el usuario: el proceso maestro de php-fpm arranca como root
# (necesario para poder bajar privilegios y abrir el socket), y sus
# *workers* ya corren como www-data según la configuración por defecto de
# la imagen (ver /usr/local/etc/php-fpm.d/www.conf: user/group=www-data).
# Por eso NO se fija aquí un "USER www-data" fijo para todo el contenedor:
# de hacerlo, no podríamos ejecutar install-moodle.sh (necesita root para
# git clone y chown). La seguridad de ejecución del código PHP de cara al
# usuario final sigue garantizada por la configuración de pool de php-fpm.

EXPOSE 9000