# Multi-stage build for Laravel API with PostGIS support
# Optimized for production deployment

# Build stage
FROM php:8.2-fpm-alpine AS builder

# Set working directory
WORKDIR /var/www

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    postgresql-dev \
    curl-dev \
    oniguruma-dev \
    zip \
    unzip \
    git \
    bash \
    nginx \
    supervisor

# Install PHP extensions including PostGIS dependencies
RUN docker-php-ext-install \
    pdo \
    pdo_pgsql \
    bcmath \
    ctype \
    fileinfo \
    json \
    mbstring \
    tokenizer \
    xml \
    curl

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Install Composer
COPY --from=composer:2.6 /usr/bin/composer /usr/bin/composer

# Copy composer files
COPY composer.json ./
COPY composer.lock* ./

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-scripts

# Production stage
FROM php:8.2-fpm-alpine AS production

# Set working directory
WORKDIR /var/www

# Create app user
RUN addgroup -g 1000 -S autowala && \
    adduser -u 1000 -S autowala -G autowala

# Install runtime dependencies
RUN apk add --no-cache \
    postgresql-dev \
    curl-dev \
    oniguruma-dev \
    nginx \
    supervisor \
    bash

# Install PHP extensions (json and tokenizer are built-in since PHP 8.0)
RUN docker-php-ext-install \
    pdo_pgsql \
    bcmath \
    mbstring

# Install Redis extension
RUN pecl install redis && docker-php-ext-enable redis

# Copy vendor dependencies from builder stage
COPY --from=builder /var/www/vendor ./vendor

# Copy application code
COPY --chown=autowala:autowala . .

# Copy configuration files
COPY docker/nginx/autowala.conf /etc/nginx/http.d/default.conf
COPY docker/php/php.ini /usr/local/etc/php/conf.d/autowala.ini
COPY docker/supervisord/supervisord.conf /etc/supervisord.conf

# Set correct permissions
RUN chown -R autowala:autowala /var/www/storage /var/www/bootstrap/cache && \
    chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Create nginx PID directory
RUN mkdir -p /run/nginx && \
    chown autowala:autowala /run/nginx

# Note: Config caching will be done at runtime via start command
# to ensure environment variables are properly loaded

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/api/health || exit 1

# Expose port
EXPOSE 80

# Switch to app user
USER autowala

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]