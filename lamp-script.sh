# Upgrade
sudo apt-get update && sudo apt-get upgrade -y

# set timezone
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends tzdata

# install apache2
sudo apt-get install -y apache2 # Need to work out how to set time and date
sudo apt-get install apache2-doc
sudo apt-get install apache2-utils

# enable mod_rewrite
sudo a2enmod rewrite proxy_fcgi
sudo service apache2 restart

# install php
sudo apt-get install -y php7.4-cli php7.4-apcu php7.4-bcmath php7.4-curl php7.4-fpm php7.4-gd php7.4-intl php7.4-mysql php7.4-xml php7.4-zip php7.4-zip php7.4-mbstring php7.4-imagick php7.4-exif

# install composer
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php composer-setup.php
sudo php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer

# install git
sudo apt-get -y install git

# configure php.ini
sudo sed -i 's/memory_limit = .*/memory_limit = '1024M'/' /etc/php/7.4/cli/php.ini
sudo sed -i 's/date.timezone = .*/date.timezone = 'UTC'/' /etc/php/7.4/cli/php.ini
sudo sed -i 's/memory_limit = .*/memory_limit = '512'/' /etc/php/7.4/fpm/php.ini
sudo sed -i 's/date.timezone = .*/date.timezone = 'UTC'/' /etc/php/7.4/fpm/php.ini

# create akeneo-pim.local.conf file
sudo echo "<VirtualHost *:80>
    ServerName akeneo-pim.local

    DocumentRoot /var/www/html/public
    <Directory /var/www/html//public>
        AllowOverride None
        Require all granted

        Options -MultiViews
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>

    <Directory /var/www/html/public/bundles>
        RewriteEngine Off
    </Directory>

    <FilesMatch \.php$>
        SetHandler 'proxy:unix:/run/php/php7.4-fpm.sock|fcgi://localhost/'
    </FilesMatch>

    SetEnvIf Authorization .+ HTTP_AUTHORIZATION=$0

    ErrorLog ${APACHE_LOG_DIR}/akeneo-pim_error.log
    LogLevel warn
    CustomLog ${APACHE_LOG_DIR}/akeneo-pim_access.log combined
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

# enable virtual host
sudo apache2ctl configtest
sudo a2ensite 000-default
sudo service apache2 reload
# sudo echo "127.0.0.1    000-default" >> /etc/hosts

# install node
sudo apt-get install curl
sudo curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt-get install -y nodejs

# install yarn
sudo curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
sudo apt update && apt-get install yarn

# pull project
sudo rm -r /var/www/html/
sudo git clone git@bitbucket.org:g2secom/g2s-akeneo-3.0.git /var/www/html

# composer install
cd /var/www/html
sudo git switch feature/upgrade-5.0
sudo composer install -q 

# akeneo install
sudo apt install make
sudo echo "APP_ENV=dev
APP_DATABASE_HOST=localhost
APP_DATABASE_PORT=3306
APP_DATABASE_NAME=pim_dev_db
APP_DATABASE_USER=admin
APP_DATABASE_PASSWORD=akeneo_pim
APP_INDEX_HOSTS='localhost:9200'" > .env.local
sudo NO_DOCKER=true make dev
sudo chown -R www-data:www-data .