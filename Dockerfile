FROM openresty/openresty:xenial

RUN apt-get update && apt-get install -y \
    git \
    libssl-dev \
    libpcre3-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN /usr/local/openresty/luajit/bin/luarocks install lrexlib-pcre
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http 
#RUN /usr/local/openresty/luajit/bin/luarocks install telegram-bot-lua 
RUN /usr/local/openresty/luajit/bin/luarocks install lua-cjson

COPY ./data/nginx /etc/nginx/lua
COPY ./nginx/lualib /usr/local/openresty/lualib/v8/
COPY ./conf.d/crserver-filter.conf /etc/nginx/conf.d/crserver-filter.conf

LABEL maintainer="Ivanov Egor"
