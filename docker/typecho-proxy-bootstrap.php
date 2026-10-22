<?php

declare(strict_types=1);

/**
 * Optional proxy settings for Typecho behind Traefik / reverse proxies.
 *
 * TYPECHO_SECURE=1 forces https:// in generated URLs (maps to __TYPECHO_SECURE__).
 * When unset, Typecho still honors X-Forwarded-Proto from the proxy.
 */
$secure = getenv('TYPECHO_SECURE');
if ($secure !== false && $secure !== '' && $secure !== '0' && strtolower($secure) !== 'false') {
    if (!defined('__TYPECHO_SECURE__')) {
        define('__TYPECHO_SECURE__', true);
    }
}
