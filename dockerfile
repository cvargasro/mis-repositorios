# Usar una imagen base de Debian
FROM debian:latest

# instalar dependencias
RUN apt-get update && apt-get install -y \
    autoconf \
    gcc \
    libc6 \
    make \
    wget \
    unzip \
    apache2 \
    apache2-utils \
    php \
    libgd-dev \
    libmcrypt-dev \
    bsd-mailx \
    build-essential \
    libssl-dev \
    libperl-dev \
    libpng-dev \
    libjpeg-dev \
    gettext \
    gawk \
    libnet-snmp-perl \
    snmp \
    vim \
    && apt-get clean

# Crear usuario nagios
RUN useradd nagios

# Descargar y extraer Nagios
RUN wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.5.2.tar.gz \
    && tar -zxvf nagios-4.5.2.tar.gz

# Configurar Nagios Core
WORKDIR nagios-4.5.2
RUN ./configure --with-httpd-conf=/etc/apache2/sites-enabled || { cat config.log; exit 1; }

# Compilar Nagios Core
RUN make all

# Instalar Nagios 
RUN make install-groups-users \
    && usermod -a -G nagios www-data \
    && make install \
    && make install-daemoninit \
    && make install-commandmode \
    && make install-config \
    && make install-webconf \
    && a2enmod rewrite \
    && a2enmod cgi

# crear usuario
RUN htpasswd -b -c /usr/local/nagios/etc/htpasswd.users nagiosadmin nagiosadmin

# hacemos un rm
RUN rm -rf /var/lib/apt/lists/* nagios-4.5.2 nagios-4.5.2.tar.gz

# Puerto 80 modo voyerista
EXPOSE 80

# Copiar archivo de configuración de Apache
COPY nagios.conf /etc/apache2/sites-enabled/

# Incluir el script de entrada directamente en el Dockerfile
CMD service apache2 start && service nagios start && tail -f /var/log/apache2/error.log
