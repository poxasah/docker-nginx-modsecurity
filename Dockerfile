FROM nginx:1.27.1

# Dependências compilação do ModSecurity
RUN apt-get update && \
    apt-get install -y \
    git g++ apt-utils autoconf automake build-essential \
    libcurl4-openssl-dev libgeoip-dev liblmdb-dev libpcre2-dev \
    libtool libxml2-dev libyajl-dev pkgconf zlib1g-dev wget vim

# Compilar o Modsecurity v3.0.12
RUN git clone --depth 1 -b v3/master https://github.com/owasp-modsecurity/ModSecurity /tmp/ModSecurity && \
    cd /tmp/ModSecurity/ && \
    git submodule init  && \
    git submodule update  && \
    sh build.sh  && \
    ./configure --with-pcre2  && \
    make  && \
    make install

# Download ModSecurity-nginx (conector entre nginx + modsec)
RUN git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx /tmp/ModSecurity-nginx && \
    cd /tmp/ && \
    wget http://nginx.org/download/nginx-1.27.1.tar.gz && \
    tar -xzvf nginx-1.27.1.tar.gz && \
    cd /tmp/nginx-1.27.1 && \
    ./configure --with-compat --add-dynamic-module=/tmp/ModSecurity-nginx  && \
    make modules  && \
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

# Clone OWASP ModSecurity Core Rule Set (CRS)
RUN git clone --depth 1 https://github.com/coreruleset/coreruleset /tmp/coreruleset && \
    mkdir /etc/nginx/modsec && \
    cd /etc/nginx/modsec && \
    mv /tmp/coreruleset/rules .

## Configurar arquivos para carregar o Modulo dinamico
COPY nginx.conf /etc/nginx/nginx.conf
COPY /modsec/* /etc/nginx/modsec/
RUN cp /tmp/ModSecurity/unicode.mapping /etc/nginx/modsec/ && \
    sed -i '/ctl:auditLogParts=+E/d'  /etc/nginx/modsec/rules/*.conf && \
    rm -rf /tmp/* /var/lib/apt/lists/* && \
    apt-get clean