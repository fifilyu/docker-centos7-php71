FROM fifilyu/centos7:latest

ENV TZ Asia/Shanghai
ENV LANG en_US.UTF-8

##############################################
# buildx有缓存，注意判断目录或文件是否已经存在
##############################################

####################
# 安装PHP71
####################
RUN ulimit -n 1024 && yum install -y centos-release-scl
RUN ulimit -n 1024 && yum install -y rh-php71 \
    rh-php71-php  \
    rh-php71-php-bcmath \
    rh-php71-php-fpm \
    rh-php71-php-gd \
    rh-php71-php-intl \
    rh-php71-php-mbstring \
    rh-php71-php-mysqlnd \
    rh-php71-php-opcache \
    rh-php71-php-pdo \
    rh-php71-php-pecl-apcu \
    rh-php71-php-xmlrpc \
    rh-php71-php-devel

COPY file/etc/opt/rh/rh-php71/php.ini /etc/opt/rh/rh-php71/php.ini
COPY file/etc/opt/rh/rh-php71/php-fpm.d/www.conf /etc/opt/rh/rh-php71/php-fpm.d/www.conf
RUN echo 'export PATH=/opt/rh/rh-php71/root/usr/bin:${PATH}' > /etc/profile.d/php71.sh

####################
# 安装Composer
####################
RUN /opt/rh/rh-php71/root/usr/bin/php -v
RUN /opt/rh/rh-php71/root/usr/bin/php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN /opt/rh/rh-php71/root/usr/bin/php -r "if (hash_file('sha384', 'composer-setup.php') === 'e21205b207c3ff031906575712edab6f13eb0b361f2085f1f1237b7126d785e826a450292b6cfd1d64d92e6563bbde02') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN /opt/rh/rh-php71/root/usr/bin/php composer-setup.php --install-dir=/opt/rh/rh-php71/root/usr/bin --filename=composer.phar
RUN /opt/rh/rh-php71/root/usr/bin/php -r "unlink('composer-setup.php');"

RUN chmod -x /opt/rh/rh-php71/root/usr/bin/composer.phar

RUN echo '#!/bin/sh' > /opt/rh/rh-php71/root/usr/bin/composer
RUN echo 'args="$@"' >> /opt/rh/rh-php71/root/usr/bin/composer
RUN echo 'abs_path="$(cd "$(dirname "$0")" && pwd)"' >> /opt/rh/rh-php71/root/usr/bin/composer
RUN echo '${abs_path}/php -c /etc/opt/rh/rh-php71/php.ini ${abs_path}/composer.phar ${args}' >> /opt/rh/rh-php71/root/usr/bin/composer
RUN chmod 755 /opt/rh/rh-php71/root/usr/bin/composer

RUN grep COMPOSER_ALLOW_SUPERUSER /root/.bash_profile || echo 'export COMPOSER_ALLOW_SUPERUSER=1' >> /etc/profile.d/php71.sh

RUN /opt/rh/rh-php71/root/usr/bin/composer list

####################
# 安装Nginx
####################
COPY file/etc/yum.repos.d/nginx.repo /etc/yum.repos.d/nginx.repo
RUN ulimit -n 1024 && rpm --import https://nginx.org/keys/nginx_signing.key
RUN ulimit -n 1024 && yum install -y nginx

COPY file/etc/nginx/nginx.conf /etc/nginx/nginx.conf
COPY file/etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
RUN nginx -t && (test -s /var/run/nginx.pid || rm -f /var/run/nginx.pid)
RUN mkdir -p /data/web
RUN useradd --shell /sbin/nologin --create-home --no-user-group --home-dir /data/web/default -G nginx php
COPY file/data/web/default/index.php /data/web/default/index.php
RUN chmod -R 755 /data/web/default/
RUN chown -R php:nginx /data/web/default/

####################
# 清理
####################
RUN ulimit -n 1024 && yum clean all

####################
# 设置开机启动
####################
COPY file/usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

WORKDIR /root

EXPOSE 22 80