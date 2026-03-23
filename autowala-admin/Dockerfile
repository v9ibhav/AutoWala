# Multi-stage build for AutoWala Admin Panel
# Optimized React build with Nginx serving

# Build stage
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install dependencies first (for better caching)
COPY package.json package-lock.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:1.24-alpine AS production

# Install security updates
RUN apk upgrade --no-cache

# Create nginx user and group
RUN addgroup -g 1000 -S autowala && \
    adduser -u 1000 -S autowala -G autowala

# Copy built app from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/default.conf /etc/nginx/conf.d/default.conf

# Set permissions
RUN chown -R autowala:autowala /usr/share/nginx/html && \
    chown -R autowala:autowala /var/cache/nginx && \
    chown -R autowala:autowala /var/log/nginx && \
    chown -R autowala:autowala /etc/nginx/conf.d

# Create nginx PID directory
RUN mkdir -p /var/run/nginx && \
    chown autowala:autowala /var/run/nginx

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Expose port
EXPOSE 80

# Switch to app user
USER autowala

# Start nginx
CMD ["nginx", "-g", "daemon off;"]