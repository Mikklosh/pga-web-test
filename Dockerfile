FROM centos:6.8
MAINTAINER G5 <admins@g5e.com>

ENV nginxVersion="1.10.1"
ENV phpVersion="5.6.24"
ENV dbdmysqlVersion="4.033"
ENV pthreadsVersion="2.0.10"
ENV phpmyadminVersion="4.6.0"

VOLUME /storage

RUN yum -y update
RUN yum -y install wget nano mc mlocate tar sendmail mailx expect
RUN yum -y install epel-release
RUN yum -y install pigz
RUN yum -y groupinstall 'Development Tools'
RUN yum -y install pcre pcre-devel openssl openssl-devel GeoIP geoip-devel libxml2 libxml2-devel bzip2 bzip2-devel libcurl libcurl-devel libpng libpng-devel libmcrypt libmcrypt-devel aspell aspell-devel readline readline-devel recode recode-devel libxslt libxslt-devel tidy libtidy-devel

ADD ./sysctl/sysctl.conf /etc/sysctl.conf
RUN mkdir /src
RUN mkdir /TEMP

ADD ./webmin/webmin.repo /etc/yum.repos.d/webmin.repo
RUN wget -P /etc/yum.repos.d/ http://www.webmin.com/jcameron-key.asc && rpm --import /etc/yum.repos.d/jcameron-key.asc
RUN yum -y install webmin
RUN chkconfig webmin on

RUN wget -P /src/ http://nginx.org/download/nginx-$nginxVersion.tar.gz && tar xvzf /src/nginx-$nginxVersion.tar.gz -C /src/ && cd /src/nginx-$nginxVersion/ && ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_geoip_module --with-http_gzip_static_module --with-http_stub_status_module --with-pcre --with-http_ssl_module --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic' && make && make install && mkdir /var/cache/nginx/ && useradd -r nginx && chown nginx:nginx /var/cache/nginx/
ADD ./nginx/nginx /etc/init.d/nginx
RUN chmod +x /etc/init.d/nginx
RUN rm -f /etc/nginx/nginx.conf
ADD ./nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./nginx/ssl /storage/conf/nginx/ssl
ADD ./nginx/vhosts /storage/conf/nginx/vhosts
RUN ln -s /storage/conf/nginx/ssl /etc/nginx/ssl
RUN ln -s /storage/conf/nginx/vhosts /etc/nginx/vhosts
RUN chkconfig nginx on

RUN wget -P /src/ http://php.net/distributions/php-$phpVersion.tar.gz && wget -P /src/ https://pecl.php.net/get/pthreads-$pthreadsVersion.tgz && tar xvzf /src/php-$phpVersion.tar.gz -C /src/ && tar xvzf /src/pthreads-$pthreadsVersion.tgz -C /src/ && cp -R /src/pthreads-$pthreadsVersion /src/php-$phpVersion/ext/pthreads && cd /src/php-$phpVersion/ && ./buildconf --force && ./configure --enable-fpm --enable-maintainer-zts --enable-bcmath --with-bz2 --enable-calendar --with-curl --enable-exif --enable-ftp --with-gd --with-gettext --enable-mbstring --with-mcrypt --with-mhash --with-mysql --with-mysql-sock=/var/lib/mysql/mysql.sock --with-mysqli --with-openssl --enable-pcntl --with-pear --enable-opcache --with-pdo-mysql --with-pspell --with-readline --with-recode --with-tidy --with-xmlrpc --with-xsl --enable-zip  --with-zlib --enable-pthreads --build=x86_64-redhat-linux-gnu --host=x86_64-redhat-linux-gnu --target=x86_64-redhat-linux-gnu --program-prefix= --prefix=/usr --exec-prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc --datadir=/usr/share --includedir=/usr/include --libdir=/usr/lib64 --libexecdir=/usr/libexec --localstatedir=/var --sharedstatedir=/var/lib --mandir=/usr/share/man --infodir=/usr/share/info --cache-file=../config.cache --with-libdir=lib64 --with-config-file-path=/etc --with-config-file-scan-dir=/etc/php.d build_alias=x86_64-redhat-linux-gnu host_alias=x86_64-redhat-linux-gnu target_alias=x86_64-redhat-linux-gnu --disable-ipv6 && make && make install && cp /src/php-$phpVersion/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm && chmod +x /etc/init.d/php-fpm
RUN rm -f /etc/php-fpm.conf
ADD ./php/php-fpm.conf /etc/php-fpm.conf
RUN rm -f /etc/php.ini
ADD ./php/php.ini /etc/php.ini
RUN chkconfig php-fpm on

RUN yum -y install http://www.percona.com/downloads/percona-release/redhat/0.1-3/percona-release-0.1-3.noarch.rpm && yum -y install Percona-Server-server-56 Percona-Server-devel-56 Percona-Server-client-56 Percona-Server-shared-56
RUN yum -y install perl-DBI perl-devel
RUN cd /src/ && wget http://www.cpan.org/authors/id/C/CA/CAPTTOFU/DBD-mysql-$dbdmysqlVersion.tar.gz && tar xvzf DBD-mysql-$dbdmysqlVersion.tar.gz && cd /src/DBD-mysql-$dbdmysqlVersion && perl Makefile.PL && make && make install
RUN wget -P /src/ https://files.phpmyadmin.net/phpMyAdmin/$phpmyadminVersion/phpMyAdmin-$phpmyadminVersion-all-languages.tar.gz && tar xvzf /src/phpMyAdmin-$phpmyadminVersion-all-languages.tar.gz -C /usr/share && mv /usr/share/phpMyAdmin-$phpmyadminVersion-all-languages /usr/share/phpMyAdmin && ln -s /usr/share/phpMyAdmin /usr/share/phpmyadmin && rm -rf /usr/share/phpmyadmin/setup
ADD	./phpmyadmin/config.inc.php /usr/share/phpMyAdmin/config.inc.php
ADD ./mysql/my.cnf /storage/conf/mysql/my.cnf
ADD ./phpmyadmin/servers.txt /TEMP/servers.txt
RUN rm -f /etc/my.cnf
RUN mv /var/lib/mysql /var/lib/mysql.bak
RUN ln -s /storage/conf/mysql/my.cnf /etc/my.cnf
RUN ln -s /storage/mysql /var/lib/mysql
RUN chkconfig mysql on

RUN yum -y install ftp vsftpd
RUN rm -f /etc/vsftpd/vsftpd.conf
ADD ./vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf
RUN chkconfig vsftpd on

RUN yum install munin munin-node spawn-fcgi -y
RUN ln -s /usr/share/munin/plugins/mysql_bytes  /etc/munin/plugins/mysql_bytes && ln -s /usr/share/munin/plugins/mysql_queries  /etc/munin/plugins/mysql_queries &&ln -s /usr/share/munin/plugins/mysql_slowqueries  /etc/munin/plugins/mysql_slowqueries && ln -s /usr/share/munin/plugins/mysql_threads  /etc/munin/plugins/mysql_threads
ADD ./spawn-fcgi/fcgi-graph /etc/init.d/fcgi-graph
ADD ./spawn-fcgi/fcgi-html /etc/init.d/fcgi-html
RUN rm -f /etc/munin/munin.conf
RUN rm -f /etc/munin/plugin-conf.d/munin-node
RUN rm -f /etc/munin/munin-node.conf
ADD ./munin/munin.conf  /etc/munin/munin.conf
ADD ./munin/munin-node /etc/munin/plugin-conf.d/munin-node
ADD ./munin/munin-node.conf /etc/munin/munin-node.conf
RUN chmod -R 777 /var/www/cgi-bin/ && chmod 777 /var/run/munin/ && chmod +x /etc/init.d/fcgi-graph && chmod +x /etc/init.d/fcgi-html
RUN chkconfig fcgi-graph on
RUN chkconfig fcgi-html on
RUN chkconfig munin-node on

RUN	yum -y install monit
RUN rm -f /etc/monit.conf
ADD ./monit/monit.conf /etc/monit.conf
RUN chmod 700 /etc/monit.conf
ADD ./monit/hdd /etc/monit.d/hdd
ADD ./monit/fcgi-graph /etc/monit.d/fcgi-graph
ADD ./monit/fcgi-html /etc/monit.d/fcgi-html
RUN chkconfig monit on

ADD ./logrotate.d/nginx /etc/logrotate.d/nginx
ADD ./src/run.sh /src/run.sh
ADD ./src/scripts /src/scripts
RUN chmod +x /src/run.sh
RUN yum clean all
RUN updatedb

EXPOSE 22 80 443 2812 3306 10000

ENTRYPOINT /src/run.sh