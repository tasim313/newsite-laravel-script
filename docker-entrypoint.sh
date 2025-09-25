#!/bin/bash
set -e

# Wait for database to be ready
echo "Waiting for database to be ready..."
while ! nc -z db 3306; do
    sleep 1
done
echo "Database is ready!"

# Setup Laravel environment
if [ ! -f .env ]; then
    echo "Setting up Laravel environment..."
    cp .env.example .env
    
    # Update .env file with Docker environment
    sed -i 's/DB_HOST=127.0.0.1/DB_HOST=db/' .env
    sed -i 's/DB_DATABASE=laravel/DB_DATABASE=news_portal/' .env
    sed -i 's/DB_USERNAME=root/DB_USERNAME=root/' .env
    sed -i 's/DB_PASSWORD=/DB_PASSWORD=root/' .env
    
    # Add additional configuration
    echo "" >> .env
    echo "# Additional Configuration" >> .env
    echo "APP_NAME=\"News Portal\"" >> .env
    echo "ADMIN_FULL_NAME=test" >> .env
    echo "ADMIN_USERNAME=test" >> .env
    echo "ADMIN_EMAIL=test@gmail.com" >> .env
    echo "ADMIN_PASSWORD=password" >> .env
    echo "PANEL_PREFIX=panel" >> .env
    echo "MAIL_MAILER=smtp" >> .env
    echo "MAIL_HOST=smtp.mailtrap.io" >> .env
    echo "MAIL_PORT=2525" >> .env
    echo "MAIL_USERNAME=null" >> .env
    echo "MAIL_PASSWORD=null" >> .env
    echo "MAIL_ENCRYPTION=null" >> .env
    echo "MAIL_FROM_ADDRESS=hello@example.com" >> .env
    echo "MAIL_FROM_NAME=\"\${APP_NAME}\"" >> .env
fi

# Generate application key if not exists
if ! grep -q "APP_KEY=base64:" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Clear any cached config
echo "Clearing application cache..."
php artisan config:clear || true
php artisan cache:clear || true
php artisan route:clear || true
php artisan view:clear || true

# Wait a bit more for database to be fully ready
sleep 5

# Run migrations with more detailed output
echo "Running database migrations..."
php artisan migrate --force --verbose

# Run database seeders
echo "Seeding database..."
php artisan db:seed --force --verbose

# Create storage link
echo "Creating storage symbolic link..."
php artisan storage:link

# Set final permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

echo "Laravel application is ready!"

# Execute the original command
exec "$@"