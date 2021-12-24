# Upgrade
apt-get update && apt-get upgrade -y

# install sudo
apt-get install -y sudo

# set timezone
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata

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
echo "<VirtualHost *:80>
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

    <Directory /var/www/html//public/bundles>
        RewriteEngine Off
    </Directory>

    <FilesMatch \.php$>
        SetHandler 'proxy:unix:/run/php/php7.4-fpm.sock|fcgi://localhost/'
    </FilesMatch>

    SetEnvIf Authorization .+ HTTP_AUTHORIZATION=$0

    ErrorLog ${APACHE_LOG_DIR}/akeneo-pim_error.log
    LogLevel warn
    CustomLog ${APACHE_LOG_DIR}/akeneo-pim_access.log combined
</VirtualHost>" > /etc/apache2/sites-available/akeneo-pim.local.conf

# enable virtual host
sudo apache2ctl configtest
sudo a2ensite akeneo-pim.local
sudo service apache2 reload
echo "127.0.0.1    akeneo-pim.local" >> /etc/hosts

# install node
sudo apt-get install curl
curl -sL https://deb.nodesource.com/setup_12.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt-get install -y nodejs

# install yarn
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
sudo apt update && apt-get install yarn