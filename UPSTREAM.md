# Upstream compatibility

Container layout, entrypoint (`init_typecho`), and install behavior are derived from the official Typecho Docker sources:

- Repository: https://github.com/typecho/Dockerfile  
- License: GNU GPL v2 (see upstream `LICENSE`)

Files under `scripts/` are copied from that repository with minimal changes (optional `REMOTEIP_TRUSTED_PROXIES` support in `init.sh`). This image uses a **patched** PHP base (`php:8.2.35-apache-bookworm`) and publishes to GHCR instead of Docker Hub.
