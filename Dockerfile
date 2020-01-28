FROM  abiosoft/caddy:php 

ENV CADDYPATH=/srv/caddycerts

WORKDIR /opt

COPY entrypoint.sh /bin/entrypoint.sh

RUN chmod +x /bin/entrypoint.sh && \
    wget https://github.com/typecho/typecho/archive/master.zip && \
    unzip master.zip && \
    rm master.zip
    
WORKDIR /srv/html

EXPOSE 80 443 2015
VOLUME /srv

ENTRYPOINT ["/bin/entrypoint.sh"]
