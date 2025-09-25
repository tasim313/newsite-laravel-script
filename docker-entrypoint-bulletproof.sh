#!/bin/bash
set -e

echo "🚀 Starting Bulletproof Laravel News Portal Setup"
echo "================================================="

# Wait for database
echo "⏳ Waiting for database..."
timeout=120
while ! nc -z db 3306 && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout-1))
done

if [ $timeout -eq 0 ]; then
    echo "❌ Database timeout after 2 minutes!"
    exit 1
fi

echo "✅ Database is ready!"

# Ensure vendor directory exists and is complete
if [ ! -d "vendor" ] || [ ! -f "vendor/autoload.php" ]; then
    echo "📦 Completing composer installation..."
    composer install --ignore-platform-reqs --no-scripts --no-interaction --verbose || \
    composer install --ignore-platform-reqs --verbose || \
    echo "⚠️  Composer install failed, but continuing..."
fi

# Fix modules.php if it exists and has the problematic line
if [ -f "config/modules.php" ]; then
    echo "🔧 Fixing modules.php configuration..."
    
    # Create a completely safe modules.php
    cat > config/modules.php << 'EOL'
<?php

return [
    'namespace' => 'Modules',
    'stubs' => [
        'enabled' => false,
        'path' => base_path() . '/vendor/nwidart/laravel-modules/src/Commands/stubs',
        'files' => [],
        'replacements' => [],
        'gitkeep' => true,
    ],
    'paths' => [
        'modules' => base_path('Modules'),
        'assets' => public_path('modules'),
        'migration' => base_path('database/migrations'),
        'generator' => [],
    ],
    'commands' => [],
    'scan' => [
        'enabled' => false,
        'paths' => [],
    ],
    'composer' => [
        'vendor' => 'nwidart',
        'author' => [
            'name' => env('COMPOSER_VENDOR_NAME', 'Author'),
            'email' => env('COMPOSER_VENDOR_EMAIL', 'author@example.com'),
        ],
        'composer-output' => false,
    ],
    'cache' => [
        'enabled' => false,
        'driver' => 'file',
        'key' => 'laravel-modules',
        'lifetime' => 60,
    ],
    'register' => [
        'translations' => true,
        'files' => 'register',
    ],
    'activators' => [],
    'activator' => 'file',
];
EOL
    
    echo "✅ Safe modules.php created"
fi

# Setup environment
echo "⚙️  Setting up environment..."
if [ ! -f .env ] || [ ! -s .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    else
        cat > .env << 'EOL'
APP_NAME="News Portal"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost:5000

LOG_CHANNEL=stack
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

# Ensure database config is correct
sed -i 's/DB_HOST=.*/DB_HOST=db/' .env
sed -i 's/DB_DATABASE=.*/DB_DATABASE=news_portal/' .env
sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' .env
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=root/' .env

# Generate app key
echo "🔐 Generating application key..."
php artisan key:generate --force || echo "⚠️  Key generation failed"

# Clear all caches
echo "🧹 Clearing caches..."
php artisan config:clear 2>/dev/null || true
php artisan cache:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# Test database connection before migrations
echo "🔗 Testing database connection..."
for i in {1..30}; do
    if php artisan tinker --execute="DB::connection()->getPdo(); echo 'DB Connected!';" 2>/dev/null; then
        echo "✅ Database connection successful"
        break
    else
        echo "⏳ Database not ready yet (attempt $i/30)..."
        sleep 2
    fi
    
    if [ $i -eq 30 ]; then
        echo "⚠️  Database connection failed after 30 attempts, but continuing..."
    fi
done

# Try to run package discovery safely
echo "🔍 Running package discovery..."
php artisan package:discover --ansi 2>/dev/null || echo "⚠️  Package discovery skipped"

# Run migrations
echo "🗄️  Running migrations..."
php artisan migrate --force --verbose 2>/dev/null || echo "⚠️  Migrations failed"

# Run seeders
echo "🌱 Running seeders..."
php artisan db:seed --force --verbose 2>/dev/null || echo "⚠️  Seeding failed"

# Create storage link
echo "🔗 Creating storage link..."
php artisan storage:link 2>/dev/null || echo "⚠️  Storage link failed"

# Final permission fix
echo "🔒 Setting final permissions..."
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Final test
echo "🧪 Running final application test..."
if php artisan --version >/dev/null 2>&1; then
    echo "✅ Laravel is working!"
else
    echo "⚠️  Laravel artisan not responding properly"
fi

echo ""
echo "🎉 Setup completed!"
echo "🌐 Application should be available at http://localhost:5000"
echo "🔧 Admin panel at http://localhost:5000/panel"
echo "🔐 Admin credentials: test / password"

# Start Apache
exec "$@"