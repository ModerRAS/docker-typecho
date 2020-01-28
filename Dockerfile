FROM  abiosoft/caddy:php 

WORKDIR /opt

RUN wget https://github.com/typecho/typecho/archive/master.zip && \
    unzip master.zip && \
    rm master.zip
    
WORKDIR /srv

COPY entrypoint.sh /bin/entrypoint.sh

EXPOSE 80 443 2015
VOLUME /root/.caddy /srv

ENTRYPOINT ["/bin/entrypoint.sh"]
