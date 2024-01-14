# Use Rocky Linux 8 image
FROM rockylinux/rockylinux:8

# Install necessary packages
RUN dnf makecache && \
    dnf install -y epel-release && \
    dnf install -y nginx php php-fpm php-json php-opcache php-mbstring php-pdo unzip --setopt=tsflags=nodocs --setopt=install_weak_deps=false --nogpgcheck && \
    dnf clean all

# Copy the Nginx configuration file to the correct location
COPY /apps/.bf-config/nginx/nginx.conf /etc/nginx/nginx.conf

# Copy the PHP-FPM configuration file
COPY /apps/.bf-config/php/conf.d/php-fpm.conf /etc/php-fpm.d/www.conf

# Copy the php.ini configuration file
COPY /apps/.bf-config/php/php.ini /etc/php.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create the working directory
WORKDIR /home/vcap/app

# Copy the composer folder and copy dependencies using Composer
COPY /apps/composer.json .

# create the source code folder
RUN mkdir -p /home/vcap/app/y/share/manpower/phpmailer && \
    mkdir -p /home/vcap/app/y/share/htdocs/ && \
    mkdir -p /home/vcap/app/y/share/controller/ && \
    mkdir -p /home/vcap/app/y/share/manpower/ && \
    mkdir -p /home/vcap/app/y/share/manpower/phpmailer && \
    mkdir -p /var/run/php-fpm/ && \
    chmod -R 755 /var/run/php-fpm/

# Copy the application source code to the working directory
COPY web /home/vcap/app/y/share/htdocs/
COPY src /home/vcap/app/y/share/controller
COPY common /home/vcap/app/y/share/manpower

# Install dependencies and copy data at once
RUN composer install --ignore-platform-reqs --no-interaction --no-plugins --no-scripts --verbose \
    && cp -r /home/vcap/app/vendor/phpmailer /home/vcap/app/y/share/manpower/phpmailer

# create folder container php-fpm.sock
RUN mkdir -p /var/run/php-fpm/ && \
    chmod -R 755 /var/run/php-fpm/

# Expose port 80 to access Nginx
EXPOSE 80

# Start Nginx and PHP-FPM when the container is launched
CMD php-fpm && nginx -g "daemon off;"
