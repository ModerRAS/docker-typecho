FROM  abiosoft/caddy:php 

ENV CADDYPATH=/srv/caddycerts

WORKDIR /opt

RUN wget https://github.com/typecho/typecho/archive/master.zip && \
    unzip master.zip && \
    rm master.zip
    
WORKDIR /srv/html

COPY entrypoint.sh /bin/entrypoint.sh

EXPOSE 80 443 2015
VOLUME /srv

ENTRYPOINT ["/bin/entrypoint.sh"]
