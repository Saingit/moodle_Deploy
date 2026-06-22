# =============================================================================
# php/Dockerfile
# PHP 8.3-FPM + extensiones requeridas por Moodle 5.1
# =============================================================================
FROM php:8.3-fpm

# Dependencias de sistema necesarias para compilar/usar las extensiones PHP
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
    && rm -rf /var/lib/apt/lists/*

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
