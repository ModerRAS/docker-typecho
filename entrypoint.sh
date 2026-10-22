#!/bin/sh
set -eu

HTML="${APACHE_DOCUMENT_ROOT:-/srv/html}"
SEED_SRC="/opt/typecho"

mkdir -p "$HTML"

if [ ! -f "$HTML/index.php" ]; then
    cp -a "${SEED_SRC}/." "$HTML/"
fi

# Writable paths for SQLite uploads, themes, plugins
chown -R www-data:www-data "$HTML" 2>/dev/null || true
find "$HTML" -type d -exec chmod 775 {} \; 2>/dev/null || true
find "$HTML" -type f -exec chmod 664 {} \; 2>/dev/null || true

# mod_remoteip trusted proxies (comma or space separated CIDRs)
TRUSTED="${REMOTEIP_TRUSTED_PROXIES:-10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,127.0.0.0/8,::1/128}"
CONF="/etc/apache2/conf-available/remoteip-trusted.conf"
{
    echo "# Generated at container start from REMOTEIP_TRUSTED_PROXIES"
    # shellcheck disable=SC2086
    for cidr in $(echo "$TRUSTED" | tr ',' ' '); do
        [ -n "$cidr" ] && echo "RemoteIPTrustedProxy $cidr"
    done
} > "$CONF"
if command -v a2enconf >/dev/null 2>&1; then
    a2enconf remoteip-trusted >/dev/null 2>&1 || ln -sf ../conf-available/remoteip-trusted.conf /etc/apache2/conf-enabled/remoteip-trusted.conf
fi

exec "$@"
