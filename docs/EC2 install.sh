sudo apt update
sudo apt upgrade -y

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt update
sudo apt install postgresql-18 -y

sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install php8.3 php8.3-cli php8.3-fpm php8.3-pgsql php8.3-gd php8.3-curl php8.3-mbstring php8.3-xml php8.3-zip php8.3-bcmath php8.3-intl -y

curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

sudo apt install unzip curl git -y
curl -fsSL https://bun.sh/install | bash
source /home/ubuntu/.bashrc

sudo apt install nginx -y

# Instalamos certbot
sudo apt install -y certbot python3-certbot-nginx

git clone https://github.com/alejmendez/teloweb.git teloweb
cd teloweb

composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate

bun install
bun run build

php artisan optimize
php artisan storage:link

sudo nano /etc/nginx/sites-available/telochile.cl

# --- CONFIGURACIÓN SSL Y NGINX ---

# 1. Detenemos Nginx para usar el puerto 80 libremente para la validación
sudo systemctl stop nginx

# 2. Obtenemos certificados (Sin wildcard para evitar validación DNS compleja)
# IMPORTANTE: Asegúrate de que los registros DNS (tipo A) de telochile.cl y www.telochile.cl
# apunten a la IP pública de este servidor ANTES de ejecutar este comando.
# Puedes ver tu IP pública ejecutando: curl ifconfig.me
# Usamos --standalone que levanta un servidor temporal
sudo certbot certonly --standalone -d telochile.cl -d www.telochile.cl --agree-tos --email alejmendez.87@gmail.com --non-interactive

# 3. Creamos la configuración de Nginx apuntando a los certificados YA creados

# Redirige todo el tráfico HTTP a HTTPS
server {
    listen 80;
    server_name telochile.cl www.telochile.cl;
    return 301 https://$host$request_uri;
}

# Bloque HTTPS
server {
    listen 443 ssl;
    server_name telochile.cl www.telochile.cl;
    root /home/ubuntu/teloweb/public;

    # Configuración de compresión gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_min_length 1000;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript application/xml+rss application/atom+xml image/svg+xml;

    # Certificados SSL
    ssl_certificate /etc/letsencrypt/live/telochile.cl/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/telochile.cl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Limitar el tamaño máximo de carga de archivos a 20MB
    client_max_body_size 20M;

    index index.php index.html index.htm;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location ~ /\.ht {
        deny all;
    }
}

# 4. Activamos el sitio y reiniciamos Nginx
sudo ln -s /etc/nginx/sites-available/telochile.cl /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl start nginx

sudo nano /etc/systemd/system/octane.service

[Unit]
Description=Laravel Octane Server
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/teloweb
ExecStart=/usr/bin/php artisan octane:start --server=frankenphp --host=127.0.0.1 --port=8000
Restart=always

[Install]
WantedBy=multi-user.target

sudo systemctl enable octane
sudo systemctl restart octane

php artisan make:filament-user
php artisan shield:generate --all --panel=admin
php artisan shield:super-admin --user=1 --panel=admin

php artisan filament:optimize
composer install --optimize-autoloader --no-dev
composer dump-autoload
php artisan optimize

# Base de datos
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
sudo -u postgres psql -c "CREATE DATABASE teloweb;"


echo -e '\nif [ -f ~/.bash_aliases ]; then\n    . ~/.bash_aliases\nfi\n' >> ~/.bashrc

touch ~/.bash_aliases
echo 'alias stop_services="sudo systemctl stop nginx ; sudo systemctl stop php8.3-fpm ; sudo systemctl stop octane"' >> ~/.bash_aliases
echo 'alias start_services="sudo systemctl start octane ; sudo systemctl start php8.3-fpm ; sudo systemctl start nginx"' >> ~/.bash_aliases
echo 'alias update_app_with_migrations="stop_services ; git pull ; bun run build -- -l silent ; composer install --optimize-autoloader --no-dev ; php artisan migrate --force ; php artisan optimize ; start_services"' >> ~/.bash_aliases
echo 'alias update_only_php="stop_services ; git pull ; composer install --optimize-autoloader --no-dev ; composer dump-autoload ; php artisan optimize ; start_services"' >> ~/.bash_aliases
echo 'alias update_only_js="stop_services ; git pull ; bun run build -- -l silent ; start_services"' >> ~/.bash_aliases
echo 'alias update_app="stop_services ; git pull ; bun run build -- -l silent ; composer install --optimize-autoloader --no-dev ; composer dump-autoload ; php artisan optimize ; start_services"' >> ~/.bash_aliases

source ~/.bashrc
