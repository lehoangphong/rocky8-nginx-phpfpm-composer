# Sử dụng hình ảnh Rocky Linux 8
FROM rockylinux/rockylinux:8

# Cài đặt các gói cần thiết
RUN dnf makecache && \
    dnf install -y epel-release && \
    dnf install -y nginx php php-fpm php-json php-opcache php-mbstring php-pdo unzip --setopt=tsflags=nodocs --setopt=install_weak_deps=false --nogpgcheck && \
    dnf clean all

# Sao chép tệp cấu hình Nginx vào đúng vị trí
COPY /apps/.bf-config/nginx/nginx.conf /etc/nginx/nginx.conf

# Sao chép tệp cấu hình PHP-FPM
COPY /apps/.bf-config/php/conf.d/php-fpm.conf /etc/php-fpm.d/www.conf

# Sao chép tệp cấu hình php.ini
COPY /apps/.bf-config/php/php.ini /etc/php.ini

# Cài đặt Composer bằng PHP
# RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
#     php composer-setup.php --install-dir=/usr/bin --filename=composer && \
#     php -r "unlink('composer-setup.php')"
# RUN php -r "copy('https://getcomposer.org/download/', 'composer-setup.php');" && \
#     php composer-setup.php --install-dir=/usr/bin --filename=composer --quiet && \
#     php -r "unlink('composer-setup.php')"
# Cài đặt Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Tạo thư mục làm việc
WORKDIR /home/vcap/app

# Sao chép thư mục composer và sao chép dependencies bằng Composer
COPY /apps/composer.json .

RUN mkdir -p /home/vcap/app/y/share/manpower/phpmailer && \
    mkdir -p /home/vcap/app/y/share/htdocs/ && \
    mkdir -p /home/vcap/app/y/share/controller/ && \
    mkdir -p /home/vcap/app/y/share/manpower/ && \
    mkdir -p /home/vcap/app/y/share/manpower/phpmailer

# Sao chép mã nguồn ứng dụng vào thư mục làm việc
COPY web /home/vcap/app/y/share/htdocs/
COPY src /home/vcap/app/y/share/controller
COPY common /home/vcap/app/y/share/manpower

# Cài đặt dependencies và sao chép dữ liệu cùng một lần
RUN composer install --ignore-platform-reqs --no-interaction --no-plugins --no-scripts --verbose \
    && ls -la \
    # && cp -r web/* /y/share/htdocs/ \
    # && cp -r src /y/share/controller \
    # && cp -r common /y/share/manpower \
    && cp -r /home/vcap/app/vendor/phpmailer /home/vcap/app/y/share/manpower/phpmailer

# # # Cài đặt dependencies bằng Composer
# RUN composer install --ignore-platform-reqs --no-interaction --no-plugins --no-scripts --verbose

# # # Sao chép thư mục phpmailer từ thư mục vendor vào /y/share/manpower/phpmailer
# COPY  /home/vcap/app/vendor/phpmailer /y/share/manpower/phpmailer

# Cài đặt dependencies bằng Composer
# COPY composer.json /y/share/manpower/composer.json
# COPY composer.lock /y/share/manpower/composer.lock
# RUN cd /y/share/manpower && composer install --no-plugins --no-scripts --no-interaction

# create folder container php-fpm.sock
RUN mkdir -p /var/run/php-fpm/ && \
    chmod -R 755 /var/run/php-fpm/

# Expose cổng 80 để truy cập Nginx
EXPOSE 80

# Khởi động Nginx và PHP-FPM khi container được chạy
CMD php-fpm && nginx -g "daemon off;"
