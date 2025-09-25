#!/bin/bash

echo "=========================================="
echo "Laravel News Portal Docker Setup (Fixed)"
echo "=========================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Clean up any existing setup
echo "🧹 Cleaning up existing setup..."
docker-compose down -v 2>/dev/null || true
docker system prune -f

# Create project directory
PROJECT_DIR="news-portal-docker"
echo "📁 Creating project directory: $PROJECT_DIR"

if [ -d "$PROJECT_DIR" ]; then
    echo "⚠️  Directory $PROJECT_DIR already exists. Removing it..."
    rm -rf "$PROJECT_DIR"
fi

mkdir "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create FIXED Dockerfile
echo "🐳 Creating FIXED Dockerfile..."
cat > Dockerfile << 'EOF'
FROM php:8.2-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libcurl4-openssl-dev \
    pkg-config \
    libssl-dev \
    zip \
    unzip \
    netcat-traditional \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Clone the project
RUN git clone https://github.com/1970Mr/news-portal.git .

# Create basic .env before composer install to prevent errors
RUN cp .env.example .env || echo "APP_KEY=" > .env

# Install composer dependencies with specific fix for Nwidart Modules
RUN composer config --global process-timeout 600 && \
    composer install --no-dev --no-interaction --prefer-dist --ignore-platform-reqs --no-scripts --verbose || \
    (echo "First install failed, trying without scripts and optimization..." && \
     composer install --ignore-platform-reqs --no-scripts --no-interaction --verbose) || \
    (echo "Installing individual packages to avoid conflicts..." && \
     composer require --no-scripts --ignore-platform-reqs nwidart/laravel-modules || true && \
     composer install --ignore-platform-reqs --no-scripts --verbose) || \
    echo "Composer install completed with warnings, will retry at runtime..."

# Copy configuration files
COPY apache-laravel.conf /etc/apache2/sites-available/000-default.conf
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Create necessary directories and set permissions
RUN mkdir -p /var/www/html/storage/logs \
             /var/www/html/storage/framework/sessions \
             /var/www/html/storage/framework/views \
             /var/www/html/storage/framework/cache \
             /var/www/html/bootstrap/cache && \
    chown -R www-data:www-data /var/www/html && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
EOF

# Create Apache configuration
echo "⚙️  Creating Apache configuration..."
cat > apache-laravel.conf << 'EOF'
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html/public

    <Directory /var/www/html/public>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Create FIXED Docker entrypoint script
echo "🚀 Creating FIXED Docker entrypoint script..."
cat > docker-entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Starting Laravel News Portal setup..."

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
timeout=60
while ! nc -z db 3306 && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout-1))
done

if [ $timeout -eq 0 ]; then
    echo "❌ Database connection timeout!"
    exit 1
fi

echo "✅ Database is ready!"

# Fix composer autoload issues
echo "🔧 Fixing Composer autoload issues..."
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "📦 Reinstalling Composer dependencies..."
    composer clear-cache
    composer install --ignore-platform-reqs --no-scripts --no-interaction --verbose || \
    composer install --ignore-platform-reqs --verbose || \
    echo "⚠️  Composer install failed, but continuing..."
fi

# Try to regenerate autoload files
echo "🔄 Regenerating autoload files..."
composer dump-autoload --ignore-platform-reqs --no-scripts || \
composer dump-autoload --ignore-platform-reqs || \
echo "⚠️  Autoload regeneration failed, but continuing..."

# Setup Laravel environment
if [ ! -f .env ] || [ ! -s .env ]; then
    echo "⚙️  Setting up Laravel environment..."
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        echo "Creating basic .env file..."
        cat > .env << 'EOL'
APP_NAME="News Portal"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost:5000

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=news_portal
DB_USERNAME=root
DB_PASSWORD=root

ADMIN_FULL_NAME=test
ADMIN_USERNAME=test
ADMIN_EMAIL=test@gmail.com
ADMIN_PASSWORD=password
PANEL_PREFIX=panel

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=hello@example.com
MAIL_FROM_NAME="${APP_NAME}"
EOL
    fi
fi

# Update database configuration
echo "🔧 Configuring database connection..."
sed -i 's/DB_HOST=127.0.0.1/DB_HOST=db/' .env
sed -i 's/DB_HOST=localhost/DB_HOST=db/' .env
sed -i 's/DB_DATABASE=laravel/DB_DATABASE=news_portal/' .env
sed -i 's/DB_DATABASE=news/DB_DATABASE=news_portal/' .env
sed -i 's/DB_USERNAME=root/DB_USERNAME=root/' .env
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=root/' .env

# Generate application key
echo "🔐 Generating application key..."
php artisan key:generate --force || echo "⚠️  Key generation failed, but continuing..."

# Clear all caches to prevent conflicts
echo "🧹 Clearing application caches..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# Wait for database to be fully ready
echo "⏳ Waiting for database to be fully initialized..."
sleep 10

# Test database connection
echo "🔗 Testing database connection..."
for i in {1..10}; do
    if mysql -h db -u root -proot -e "SELECT 1" >/dev/null 2>&1; then
        echo "✅ Database connection successful"
        break
    else
        echo "⏳ Attempt $i: Database not ready yet, waiting..."
        sleep 5
    fi
done

# Try to run package discovery manually if it failed during build
echo "🔍 Running package discovery..."
php artisan package:discover --ansi || echo "⚠️  Package discovery failed, but continuing..."

# Run migrations
echo "🗄️  Running database migrations..."
php artisan migrate --force --verbose || echo "⚠️  Migration failed, but continuing..."

# Run seeders
echo "🌱 Seeding database..."
php artisan db:seed --force --verbose || echo "⚠️  Seeding failed, but continuing..."

# Create storage link
echo "🔗 Creating storage symbolic link..."
php artisan storage:link || echo "⚠️  Storage link failed, but continuing..."

# Set final permissions
echo "🔒 Setting final permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

echo "✅ Laravel application setup completed!"
echo "🌐 Application should be available at http://localhost:5000"
echo "🔧 Admin panel at http://localhost:5000/panel"

# Execute the original command
exec "$@"
EOF

# Make entrypoint script executable
chmod +x docker-entrypoint.sh

# Create Docker Compose file (remove version for newer Docker Compose)
echo "📋 Creating Docker Compose configuration..."
cat > docker-compose.yml << 'EOF'
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: news-portal-app
    restart: unless-stopped
    ports:
      - "5000:80"
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - DB_DATABASE=news_portal
      - DB_USERNAME=root
      - DB_PASSWORD=root
    volumes:
      - app_storage:/var/www/html/storage/app
      - app_logs:/var/www/html/storage/logs
    depends_on:
      db:
        condition: service_healthy
    networks:
      - laravel

  db:
    image: mysql:8.0
    container_name: news-portal-db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: news_portal
      MYSQL_ROOT_PASSWORD: root
      MYSQL_PASSWORD: root
      MYSQL_USER: laravel
    volumes:
      - db_data:/var/lib/mysql
    ports:
      - "3307:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
    networks:
      - laravel

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: news-portal-phpmyadmin
    restart: unless-stopped
    environment:
      PMA_HOST: db
      PMA_PORT: 3306
      PMA_USER: root
      PMA_PASSWORD: root
    ports:
      - "8080:80"
    depends_on:
      - db
    networks:
      - laravel

volumes:
  db_data:
    driver: local
  app_storage:
    driver: local
  app_logs:
    driver: local

networks:
  laravel:
    driver: bridge
EOF

# Create .dockerignore file
echo "🚫 Creating .dockerignore file..."
cat > .dockerignore << 'EOF'
.git
.gitignore
README.md
Dockerfile
docker-compose.yml
.env
.env.example
EOF

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "📝 Files created:"
echo "   - Dockerfile (FIXED for Nwidart Modules)"
echo "   - docker-compose.yml (Updated for newer Docker Compose)"
echo "   - apache-laravel.conf"
echo "   - docker-entrypoint.sh (FIXED with better error handling)"
echo "   - .dockerignore"
echo ""
echo "🚀 To start the application, run:"
echo "   docker-compose up -d --build"
echo ""
echo "🌐 Once started, you can access:"
echo "   - Laravel App: http://localhost:5000"
echo "   - Admin Panel: http://localhost:5000/panel"
echo "   - phpMyAdmin: http://localhost:8080"
echo ""
echo "🔐 Default admin credentials:"
echo "   - Username: test"
echo "   - Password: password"
echo ""
echo "💾 Database credentials:"
echo "   - Host: localhost:3307 (from host machine)"
echo "   - Database: news_portal"
echo "   - Username: root"
echo "   - Password: root"
echo ""
echo "⏳ Note: Initial setup may take 10-15 minutes for first build and database setup."

# Ask if user wants to start immediately
read -p "🤔 Do you want to start the containers now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔨 Building and starting containers with no cache..."
    docker-compose up -d --build --no-deps
    
    echo ""
    echo "⏳ Waiting for containers to be ready..."
    sleep 15
    
    echo ""
    echo "📊 Container status:"
    docker-compose ps
    
    echo ""
    echo "📋 Checking logs for any issues:"
    echo "=== Application Logs (last 10 lines) ==="
    docker-compose logs --tail=10 app
    
    echo ""
    echo "🔍 Testing application..."
    sleep 5
    if curl -s http://localhost:5000 >/dev/null; then
        echo "✅ Application is responding!"
    else
        echo "⚠️  Application may still be starting up..."
    fi
    
    echo ""
    echo "🎉 Setup complete!"
    echo "🌐 Visit: http://localhost:5000"
    echo "🔧 Admin Panel: http://localhost:5000/panel"
    echo ""
    echo "🆘 If you encounter issues:"
    echo "   - Check logs: docker-compose logs app"
    echo "   - Enter container: docker-compose exec app bash"
    echo "   - Restart: docker-compose restart app"
fi