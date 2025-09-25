#!/bin/bash

echo "🔧 Complete Laravel News Portal Fix"
echo "===================================="

# Function to fix the modules configuration
fix_modules_config() {
    echo "🔧 Fixing modules configuration..."
    
    # Enter the container and fix the config
    docker-compose exec app bash -c "
        cd /var/www/html
        
        echo '📝 Backing up original modules.php...'
        cp config/modules.php config/modules.php.backup 2>/dev/null || echo 'No modules.php found to backup'
        
        echo '🔄 Creating fixed modules.php configuration...'
        cat > config/modules.php << 'EOL'
<?php

use Nwidart\Modules\Activators\FileActivator;
use Nwidart\Modules\Commands;

return [
    /*
    |--------------------------------------------------------------------------
    | Module Namespace
    |--------------------------------------------------------------------------
    |
    | Default module namespace.
    |
    */

    'namespace' => 'Modules',

    /*
    |--------------------------------------------------------------------------
    | Module Stubs
    |--------------------------------------------------------------------------
    |
    | Default module stubs.
    |
    */

    'stubs' => [
        'enabled' => false,
        'path' => base_path() . '/vendor/nwidart/laravel-modules/src/Commands/stubs',
        'files' => [
            'routes/web' => 'Routes/web.php',
            'routes/api' => 'Routes/api.php',
            'views/index' => 'Resources/views/index.blade.php',
            'views/master' => 'Resources/views/layouts/master.blade.php',
            'scaffold/config' => 'Config/config.php',
            'composer' => 'composer.json',
            'assets/js/app' => 'Resources/assets/js/app.js',
            'assets/sass/app' => 'Resources/assets/sass/app.scss',
            'vite' => 'vite.config.js',
            'package' => 'package.json',
        ],
        'replacements' => [
            'routes/web' => ['LOWER_NAME', 'STUDLY_NAME'],
            'routes/api' => ['LOWER_NAME'],
            'vite' => ['LOWER_NAME'],
            'json' => ['LOWER_NAME', 'STUDLY_NAME', 'MODULE_NAMESPACE', 'PROVIDER_NAMESPACE'],
            'views/index' => ['LOWER_NAME'],
            'views/master' => ['LOWER_NAME', 'STUDLY_NAME'],
            'scaffold/config' => ['STUDLY_NAME'],
            'composer' => [
                'LOWER_NAME',
                'STUDLY_NAME',
                'VENDOR',
                'AUTHOR_NAME',
                'AUTHOR_EMAIL',
                'MODULE_NAMESPACE',
                'PROVIDER_NAMESPACE',
            ],
        ],
        'gitkeep' => true,
    ],
    'paths' => [
        /*
        |--------------------------------------------------------------------------
        | Modules path
        |--------------------------------------------------------------------------
        |
        | This path is used to save the generated module.
        | This path will also be added automatically to the list of scanned folders.
        |
        */

        'modules' => base_path('Modules'),
        /*
        |--------------------------------------------------------------------------
        | Modules assets path
        |--------------------------------------------------------------------------
        |
        | Here you may update the modules' assets path.
        |
        */

        'assets' => public_path('modules'),
        /*
        |--------------------------------------------------------------------------
        | The migrations path
        |--------------------------------------------------------------------------
        |
        | Where you run the 'module:publish-migration' command, where do you publish the
        | the migration files?
        |
        */

        'migration' => base_path('database/migrations'),
        /*
        |--------------------------------------------------------------------------
        | Generator path
        |--------------------------------------------------------------------------
        | Customise the paths where the folders will be generated.
        | Set the generate key to false to not generate that folder
        */
        'generator' => [
            'config' => ['path' => 'Config', 'generate' => true],
            'command' => ['path' => 'Console', 'generate' => true],
            'migration' => ['path' => 'Database/Migrations', 'generate' => true],
            'seeder' => ['path' => 'Database/Seeders', 'generate' => true],
            'factory' => ['path' => 'Database/Factories', 'generate' => true],
            'model' => ['path' => 'Entities', 'generate' => true],
            'routes' => ['path' => 'Routes', 'generate' => true],
            'controller' => ['path' => 'Http/Controllers', 'generate' => true],
            'filter' => ['path' => 'Http/Middleware', 'generate' => true],
            'request' => ['path' => 'Http/Requests', 'generate' => true],
            'provider' => ['path' => 'Providers', 'generate' => true],
            'assets' => ['path' => 'Resources/assets', 'generate' => true],
            'lang' => ['path' => 'Resources/lang', 'generate' => true],
            'views' => ['path' => 'Resources/views', 'generate' => true],
            'test' => ['path' => 'Tests/Unit', 'generate' => true],
            'test-feature' => ['path' => 'Tests/Feature', 'generate' => true],
            'repository' => ['path' => 'Repositories', 'generate' => false],
            'event' => ['path' => 'Events', 'generate' => false],
            'listener' => ['path' => 'Listeners', 'generate' => false],
            'policies' => ['path' => 'Policies', 'generate' => false],
            'rules' => ['path' => 'Rules', 'generate' => false],
            'jobs' => ['path' => 'Jobs', 'generate' => false],
            'emails' => ['path' => 'Emails', 'generate' => false],
            'notifications' => ['path' => 'Notifications', 'generate' => false],
            'resource' => ['path' => 'Transformers', 'generate' => false],
            'component-view' => ['path' => 'Resources/views/components', 'generate' => false],
            'component-class' => ['path' => 'View/Components', 'generate' => false],
        ],
    ],

    /*
    |--------------------------------------------------------------------------
    | Package commands
    |--------------------------------------------------------------------------
    |
    | Here you can define which commands will be visible and used in your
    | application. You can add your own commands to merge section.
    |
    */

    'commands' => [
        Commands\CommandMakeCommand::class,
        Commands\ControllerMakeCommand::class,
        Commands\DisableCommand::class,
        Commands\DumpCommand::class,
        Commands\EnableCommand::class,
        Commands\EventMakeCommand::class,
        Commands\JobMakeCommand::class,
        Commands\ListenerMakeCommand::class,
        Commands\MailMakeCommand::class,
        Commands\MiddlewareMakeCommand::class,
        Commands\NotificationMakeCommand::class,
        Commands\ProviderMakeCommand::class,
        Commands\RouteProviderMakeCommand::class,
        Commands\InstallCommand::class,
        Commands\ListCommand::class,
        Commands\ModuleDeleteCommand::class,
        Commands\ModuleMakeCommand::class,
        Commands\FactoryMakeCommand::class,
        Commands\PolicyMakeCommand::class,
        Commands\RequestMakeCommand::class,
        Commands\RuleMakeCommand::class,
        Commands\MigrateCommand::class,
        Commands\MigrateRefreshCommand::class,
        Commands\MigrateResetCommand::class,
        Commands\MigrateRollbackCommand::class,
        Commands\MigrateStatusCommand::class,
        Commands\MigrationMakeCommand::class,
        Commands\ModelMakeCommand::class,
        Commands\PublishCommand::class,
        Commands\PublishConfigurationCommand::class,
        Commands\PublishMigrationCommand::class,
        Commands\PublishTranslationCommand::class,
        Commands\SeedCommand::class,
        Commands\SeedMakeCommand::class,
        Commands\SetupCommand::class,
        Commands\UnUseCommand::class,
        Commands\UpdateCommand::class,
        Commands\UseCommand::class,
        Commands\ResourceMakeCommand::class,
        Commands\TestMakeCommand::class,
        Commands\LaravelModulesV6Migrator::class,
        Commands\ComponentClassMakeCommand::class,
        Commands\ComponentViewMakeCommand::class,
    ],

    /*
    |--------------------------------------------------------------------------
    | Scan Path
    |--------------------------------------------------------------------------
    |
    | Here you define which folder will be scanned. By default will scan vendor
    | directory. This is useful if you host the package in packagist website.
    |
    */

    'scan' => [
        'enabled' => false,
        'paths' => [
            base_path('vendor/*/*'),
        ],
    ],
    /*
    |--------------------------------------------------------------------------
    | Composer File Template
    |--------------------------------------------------------------------------
    |
    | Here is the template that will be used to generate the composer.json file.
    |
    */

    'composer' => [
        'vendor' => 'nwidart',
        'author' => [
            'name' => env('COMPOSER_VENDOR_NAME', 'Nicolas Widart'),
            'email' => env('COMPOSER_VENDOR_EMAIL', 'n.widart@gmail.com'),
        ],
        'composer-output' => false,
    ],

    /*
    |--------------------------------------------------------------------------
    | Caching
    |--------------------------------------------------------------------------
    |
    | Here is the config for setting up the caching feature.
    |
    */
    'cache' => [
        'enabled' => false,
        'driver' => 'file',
        'key' => 'laravel-modules',
        'lifetime' => 60,
    ],
    /*
    |--------------------------------------------------------------------------
    | Choose what laravel-modules will register as custom namespaces.
    | Setting one to false will require you to register that part
    | in your own Service Provider class.
    |--------------------------------------------------------------------------
    */
    'register' => [
        'translations' => true,
        /**
         * load files on boot or register method
         *
         * Note: boot not compatible with asgardcms
         *
         * @example boot|register
         */
        'files' => 'register',
    ],

    /*
    |--------------------------------------------------------------------------
    | Activators
    |--------------------------------------------------------------------------
    |
    | You can define new types of activators here, file, database, etc. The only
    | required parameter is 'class'.
    | The file activator will store the activation status in storage/installed_modules
    */
    'activators' => [
        'file' => [
            'class' => FileActivator::class,
            'statuses-file' => base_path('modules_statuses.json'),
            'cache-key' => 'activator.installed',
            'cache-lifetime' => 604800,
        ],
    ],

    'activator' => 'file',
];
EOL

        echo '✅ Fixed modules.php configuration created'
        
        echo '🔄 Clearing configuration cache...'
        php artisan config:clear || echo 'Config clear failed but continuing...'
        
        echo '📦 Re-running composer dump-autoload...'
        composer dump-autoload --ignore-platform-reqs --no-scripts || echo 'Autoload dump failed but continuing...'
        
        echo '🔍 Testing configuration...'
        php artisan config:cache || echo 'Config cache failed but continuing...'
        
        echo '✅ Configuration fix completed!'
    "
}

# Function to reinstall the modules package
reinstall_modules_package() {
    echo "📦 Reinstalling Nwidart Modules package..."
    
    docker-compose exec app bash -c "
        cd /var/www/html
        
        echo '🗑️  Removing existing modules package...'
        composer remove nwidart/laravel-modules --ignore-platform-reqs --no-scripts || echo 'Remove failed but continuing...'
        
        echo '📥 Installing modules package fresh...'
        composer require nwidart/laravel-modules --ignore-platform-reqs --no-scripts || echo 'Install failed but continuing...'
        
        echo '🔄 Dumping autoload...'
        composer dump-autoload --ignore-platform-reqs --no-scripts
        
        echo '📝 Publishing modules config if needed...'
        php artisan vendor:publish --provider=\"Nwidart\\Modules\\LaravelModulesServiceProvider\" --force || echo 'Publish failed but continuing...'
    "
}

# Function to create a minimal modules config
create_minimal_config() {
    echo "📝 Creating minimal modules configuration..."
    
    docker-compose exec app bash -c "
        cd /var/www/html
        
        echo '🔧 Creating minimal modules.php...'
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
            'name' => 'Author',
            'email' => 'author@example.com',
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
        
        echo '🧹 Clearing caches...'
        php artisan config:clear || true
        php artisan cache:clear || true
        
        echo '✅ Minimal config created!'
    "
}

# Main execution
echo ""
echo "🚀 Starting complete fix process..."

# Check if containers are running
if ! docker-compose ps | grep -q "news-portal-app.*Up"; then
    echo "⚠️  App container is not running. Starting containers..."
    docker-compose up -d
    sleep 15
fi

echo ""
echo "Choose fix method:"
echo "1. Fix modules configuration (recommended)"
echo "2. Reinstall modules package"
echo "3. Create minimal modules config"
echo "4. Complete rebuild from scratch"
echo "5. All fixes (comprehensive)"

read -p "Choose option (1-5): " choice

case $choice in
    1)
        fix_modules_config
        ;;
    2)
        reinstall_modules_package
        ;;
    3)
        create_minimal_config
        ;;
    4)
        echo "🔄 Complete rebuild..."
        docker-compose down -v
        docker-compose build --no-cache
        docker-compose up -d
        sleep 30
        fix_modules_config
        ;;
    5)
        echo "🔄 Running all fixes..."
        create_minimal_config
        sleep 2
        reinstall_modules_package
        sleep 2
        fix_modules_config
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

# Test the application
echo ""
echo "🧪 Testing the application..."
sleep 5

# Check if the container is still running
if docker-compose ps | grep -q "news-portal-app.*Up"; then
    echo "✅ Container is running"
    
    # Test the web response
    echo "🌐 Testing web response..."
    if curl -s -f http://localhost:5000 >/dev/null 2>&1; then
        echo "✅ Application is responding!"
        echo "🎉 SUCCESS! Your application is now working!"
        echo ""
        echo "🌐 Access points:"
        echo "   - Main app: http://localhost:5000"
        echo "   - Admin panel: http://localhost:5000/panel" 
        echo "   - phpMyAdmin: http://localhost:8080"
        echo ""
        echo "🔐 Admin credentials:"
        echo "   Username: test"
        echo "   Password: password"
    else
        echo "⚠️  Application is not responding on port 5000"
        echo "📋 Checking recent logs:"
        docker-compose logs --tail=10 app
    fi
else
    echo "❌ Container stopped running. Checking logs:"
    docker-compose logs --tail=20 app
fi

echo ""
echo "🆘 If issues persist:"
echo "   - View logs: docker-compose logs app"
echo "   - Enter container: docker-compose exec app bash"
echo "   - Restart: docker-compose restart"