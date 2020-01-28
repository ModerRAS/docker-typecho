#!/bin/sh

test -e /srv/index.php || cp -a /opt/typecho-master/* /srv

/bin/parent caddy --conf /etc/Caddyfile --log stdout --agree=$ACME_AGREE -quic
