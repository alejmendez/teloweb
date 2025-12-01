alias stop_services="sudo systemctl stop nginx ; sudo systemctl stop php8.3-fpm ; sudo systemctl stop octane"
alias start_services="sudo systemctl start octane ; sudo systemctl start php8.3-fpm ; sudo systemctl start nginx"
alias update_app_with_migrations="stop_services ; git pull ; bun run build ; composer install --optimize-autoloader --no-dev ; php artisan migrate --force ; php artisan optimize ; start_services"
alias update_app="stop_services ; git pull ; bun run build ; composer install --optimize-autoloader --no-dev ; composer dump-autoload ; php artisan optimize ; php artisan filament:optimize ; start_services"
