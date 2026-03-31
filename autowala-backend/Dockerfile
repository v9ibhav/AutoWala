# Optimized single-stage Laravel build for Railway deployment
FROM php:8.2-fpm-alpine

# Set working directory
WORKDIR /var/www

# Install system dependencies
RUN apk add --no-cache \
    postgresql-dev \
    curl-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    bash \
    nginx \
    supervisor \
    autoconf \
    g++ \
    make \
    libc-dev

# Install only necessary PHP extensions (avoid built-ins)
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    bcmath \
    mbstring

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Create app user
RUN addgroup -g 1000 -S autowala && \
    adduser -u 1000 -S autowala -G autowala

# Copy composer files first (for better caching)
COPY composer.json composer.lock* ./

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction

# Copy application code
COPY --chown=autowala:autowala . .

# Create required directories and set permissions
RUN mkdir -p storage/logs storage/framework/{cache,sessions,views} bootstrap/cache && \
    chown -R autowala:autowala storage bootstrap/cache && \
    chmod -R 775 storage bootstrap/cache

# Create nginx directories
RUN mkdir -p /run/nginx /var/log/nginx && \
    chown -R autowala:autowala /run/nginx /var/log/nginx

# Copy configuration files if they exist, otherwise create defaults
RUN if [ -f docker/nginx/autowala.conf ]; then \
        cp docker/nginx/autowala.conf /etc/nginx/http.d/default.conf; \
    else \
        echo "Creating default nginx config"; \
    fi && \
    if [ -f docker/php/php.ini ]; then \
        cp docker/php/php.ini /usr/local/etc/php/conf.d/autowala.ini; \
    else \
        echo "Using default PHP config"; \
    fi && \
    if [ -f docker/supervisord/supervisord.conf ]; then \
        cp docker/supervisord/supervisord.conf /etc/supervisord.conf; \
    else \
        echo "Will create default supervisord config"; \
    fi

# Create default supervisord config if not exists
RUN if [ ! -f /etc/supervisord.conf ]; then \
    echo "[supervisord]" > /etc/supervisord.conf && \
    echo "nodaemon=true" >> /etc/supervisord.conf && \
    echo "user=root" >> /etc/supervisord.conf && \
    echo "" >> /etc/supervisord.conf && \
    echo "[program:nginx]" >> /etc/supervisord.conf && \
    echo "command=nginx -g 'daemon off;'" >> /etc/supervisord.conf && \
    echo "autostart=true" >> /etc/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisord.conf && \
    echo "" >> /etc/supervisord.conf && \
    echo "[program:php-fpm]" >> /etc/supervisord.conf && \
    echo "command=php-fpm" >> /etc/supervisord.conf && \
    echo "autostart=true" >> /etc/supervisord.conf && \
    echo "autorestart=true" >> /etc/supervisord.conf; \
    fi

# Create default nginx config if not exists
RUN if [ ! -f /etc/nginx/http.d/default.conf ]; then \
    echo "server {" > /etc/nginx/http.d/default.conf && \
    echo "    listen 80;" >> /etc/nginx/http.d/default.conf && \
    echo "    server_name _;" >> /etc/nginx/http.d/default.conf && \
    echo "    root /var/www/public;" >> /etc/nginx/http.d/default.conf && \
    echo "    index index.php;" >> /etc/nginx/http.d/default.conf && \
    echo "" >> /etc/nginx/http.d/default.conf && \
    echo "    location / {" >> /etc/nginx/http.d/default.conf && \
    echo "        try_files \$uri \$uri/ /index.php?\$query_string;" >> /etc/nginx/http.d/default.conf && \
    echo "    }" >> /etc/nginx/http.d/default.conf && \
    echo "" >> /etc/nginx/http.d/default.conf && \
    echo "    location ~ \.php\$ {" >> /etc/nginx/http.d/default.conf && \
    echo "        fastcgi_pass 127.0.0.1:9000;" >> /etc/nginx/http.d/default.conf && \
    echo "        fastcgi_index index.php;" >> /etc/nginx/http.d/default.conf && \
    echo "        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;" >> /etc/nginx/http.d/default.conf && \
    echo "        include fastcgi_params;" >> /etc/nginx/http.d/default.conf && \
    echo "    }" >> /etc/nginx/http.d/default.conf && \
    echo "}" >> /etc/nginx/http.d/default.conf; \
    fi

# Generate Laravel application key and optimize (with error handling)
RUN if [ -f .env ]; then \
        echo "Using existing .env file"; \
    else \
        echo "APP_NAME=AutoWala" > .env && \
        echo "APP_ENV=production" >> .env && \
        echo "APP_DEBUG=false" >> .env && \
        echo "APP_KEY=" >> .env && \
        echo "LOG_CHANNEL=stderr" >> .env && \
        echo "DB_CONNECTION=pgsql" >> .env; \
    fi && \
    (php artisan key:generate --no-interaction --force || echo "APP_KEY=base64:$(openssl rand -base64 32)" >> .env) && \
    (php artisan config:cache --no-interaction || echo "Config cache skipped - will cache at runtime") && \
    (php artisan route:cache --no-interaction || echo "Route cache skipped - will cache at runtime")

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/api/health || exit 1

# Expose port
EXPOSE 80

# Start with proper user switching
CMD ["sh", "-c", "supervisord -c /etc/supervisord.conf"]