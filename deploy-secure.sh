#!/bin/bash

set -e
clear

echo "================================================="
echo "   🚀 AT LOOPS - Secure Deployment Script"
echo "   👨‍💻 By Eng Mohamed Fahmy"
echo "================================================="
echo ""

# ===============================
# Update Server
# ===============================
echo "🔄 Updating server..."
sudo apt update -y && sudo apt upgrade -y

# ===============================
# Install Core Packages
# ===============================
echo "📦 Installing core packages..."
sudo apt install -y apache2 mysql-server \
php php-cli php-fpm libapache2-mod-php \
php-mbstring php-xml php-curl php-zip php-mysql \
unzip tar curl software-properties-common apache2-utils ufw

sudo systemctl enable apache2 mysql
sudo systemctl start apache2 mysql

# ===============================
# Optional MySQL Hardening
# ===============================
echo "🔐 MySQL secure installation is recommended."
read -p "Run mysql_secure_installation now? (y/n): " RUN_MYSQL_SECURE

if [[ "$RUN_MYSQL_SECURE" == "y" ]]; then
    sudo mysql_secure_installation
fi

# ===============================
# Install & Secure phpMyAdmin
# ===============================
echo "📦 Installing phpMyAdmin..."
sudo apt install -y phpmyadmin

if [[ ! -L /var/www/html/phpmyadmin ]]; then
    sudo ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
fi

echo "🔐 Securing phpMyAdmin..."
read -p "phpMyAdmin username: " PMA_USER
sudo htpasswd -c /etc/phpmyadmin/.htpasswd "$PMA_USER"

sudo tee /etc/apache2/conf-available/phpmyadmin-security.conf > /dev/null <<EOF
<Directory /usr/share/phpmyadmin>
    AuthType Basic
    AuthName "Restricted Access"
    AuthUserFile /etc/phpmyadmin/.htpasswd
    Require valid-user
</Directory>
EOF

sudo a2enconf phpmyadmin-security
sudo systemctl reload apache2

# ===============================
# Firewall
# ===============================
echo "🔥 Configuring firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# ===============================
# Create Linux Admin User
# ===============================
echo "👤 Create Linux admin user"
read -p "Username: " USERNAME
read -s -p "Password: " PASSWORD
echo ""

if ! id "$USERNAME" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | sudo chpasswd
    sudo usermod -aG sudo "$USERNAME"
fi

# ===============================
# Project Inputs
# ===============================
read -p "📦 Is project compressed? (y/n): " IS_COMPRESSED

if [[ "$IS_COMPRESSED" == "y" ]]; then
    read -p "📁 Archive full path: " ARCHIVE_PATH
else
    read -p "📁 Project folder path: " PROJECT_PATH
fi

read -p "📝 Project name: " PROJECT_NAME
read -p "🌍 Domain name: " DOMAIN_NAME
read -p "📧 Email for SSL notifications: " SSL_EMAIL

echo ""
echo "⚙️ Select project technology:"
echo "1) Laravel"
echo "2) PHP"
echo "3) Node.js API"
echo "4) Vue.js"
echo "5) React"
read -p "👉 Choice [1-5]: " TECH_CHOICE

APACHE_ROOT="/var/www/$PROJECT_NAME"
sudo mkdir -p "$APACHE_ROOT"

# ===============================
# Copy / Extract Project
# ===============================
echo "📂 Preparing project files..."

if [[ "$IS_COMPRESSED" == "y" ]]; then
    case $ARCHIVE_PATH in
        *.zip) sudo unzip "$ARCHIVE_PATH" -d "$APACHE_ROOT" ;;
        *.tar.gz|*.tgz) sudo tar -xzf "$ARCHIVE_PATH" -C "$APACHE_ROOT" ;;
        *) echo "❌ Unsupported archive format"; exit 1 ;;
    esac
else
    sudo cp -R "$PROJECT_PATH"/* "$APACHE_ROOT"
fi

sudo chown -R www-data:www-data "$APACHE_ROOT"
sudo chmod -R 755 "$APACHE_ROOT"

# ===============================
# Technology Handling
# ===============================
if [[ "$TECH_CHOICE" == "1" ]]; then
    echo "🧩 Laravel detected..."

    if ! command -v composer &>/dev/null; then
        curl -sS https://getcomposer.org/installer | php
        sudo mv composer.phar /usr/local/bin/composer
    fi

    cd "$APACHE_ROOT"
    composer install --no-dev --optimize-autoloader

    php artisan key:generate --force
    php artisan config:clear
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache

    sudo chmod -R 775 storage bootstrap/cache
    [[ -f .env ]] && sudo chmod 640 .env

    PUBLIC_ROOT="$APACHE_ROOT/public"

elif [[ "$TECH_CHOICE" == "2" ]]; then
    PUBLIC_ROOT="$APACHE_ROOT"

else
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
    cd "$APACHE_ROOT"
    npm install
    npm run build

    [[ "$TECH_CHOICE" == "3" ]] && PUBLIC_ROOT="$APACHE_ROOT"
    [[ "$TECH_CHOICE" == "4" ]] && PUBLIC_ROOT="$APACHE_ROOT/dist"
    [[ "$TECH_CHOICE" == "5" ]] && PUBLIC_ROOT="$APACHE_ROOT/build"
fi

# ===============================
# Apache VirtualHost
# ===============================
APACHE_CONF="/etc/apache2/sites-available/$DOMAIN_NAME.conf"

sudo tee "$APACHE_CONF" > /dev/null <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    ServerAlias www.$DOMAIN_NAME
    DocumentRoot $PUBLIC_ROOT

    <Directory $PUBLIC_ROOT>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$PROJECT_NAME-error.log
    CustomLog \${APACHE_LOG_DIR}/$PROJECT_NAME-access.log combined
</VirtualHost>
EOF

sudo a2enmod rewrite
sudo a2ensite "$DOMAIN_NAME"
sudo a2dissite 000-default.conf || true
sudo systemctl reload apache2

# ===============================
# SSL with Certbot
# ===============================
echo "🔐 Installing SSL with Certbot..."
sudo apt install -y certbot python3-certbot-apache

sudo certbot --apache \
    -d $DOMAIN_NAME \
    -d www.$DOMAIN_NAME \
    --non-interactive \
    --agree-tos \
    -m $SSL_EMAIL \
    --redirect

sudo systemctl reload apache2

# ===============================
# Finish
# ===============================
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "================================================="
echo "✅ Deployment completed successfully!"
echo "🌐 Project: https://$DOMAIN_NAME"
echo "🗄️ phpMyAdmin: https://$DOMAIN_NAME/phpmyadmin"
echo "🚀 By Eng Mohamed Fahmy"
echo "================================================="
