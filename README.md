# docker-typecho

基于官方 **PHP Apache** 镜像构建的 Typecho 容器，面向 Traefik 等反向代理（容器内仅 HTTP 80，由代理终结 TLS）。

- **Typecho**：v1.3.0（当前稳定版）
- **PHP**：`8.2.35`（已修复 [PHP2Shell](https://nvd.nist.gov/) / CVE-2026-109618、CVE-2026-109619；构建时校验版本，避免回落到未修补 PHP）
- **发布**：`ghcr.io/moderras/docker-typecho`

> **说明**：本仓库早期版本使用 `abiosoft/caddy:php`（Caddy + PHP-FPM），并从 GitHub `master` 拉取 Typecho。现已改为官方 `php:8.2.35-apache` + Typecho 1.3.0 固定版本。

## 快速开始

```bash
docker pull ghcr.io/moderras/docker-typecho:latest

docker run -d \
  --name typecho \
  --restart unless-stopped \
  -p 80:80 \
  -v /path/to/typecho-data:/srv \
  -e TYPECHO_SECURE=1 \
  ghcr.io/moderras/docker-typecho:latest
```

站点文件位于卷内 **`/srv/html`**（与旧版 Caddy 镜像挂载 `/srv` 的方式兼容）。首次启动会自动将 Typecho 文件复制到该目录。

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TYPECHO_SECURE` | （未设置） | 设为 `1` 时强制 Typecho 使用 `https://` 生成链接（`__TYPECHO_SECURE__`）。未设置时仍可通过代理发来的 `X-Forwarded-Proto: https` 识别 HTTPS。 |
| `REMOTEIP_TRUSTED_PROXIES` | `10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,127.0.0.0/8,::1/128` | `mod_remoteip` 信任的代理 CIDR，逗号或空格分隔。 |
| `APACHE_DOCUMENT_ROOT` | `/srv/html` | 文档根目录，一般无需修改。 |

以下旧版 Caddy 镜像变量 **已不再使用**（TLS 由 Traefik 处理）：`DOMAIN`、`EMAIL`、`ACME_AGREE`。

## Traefik 示例

容器只监听 **80**，请由 Traefik 提供 HTTPS 并转发 `X-Forwarded-Proto` / `X-Forwarded-For`：

```yaml
services:
  typecho:
    image: ghcr.io/moderras/docker-typecho:latest
    volumes:
      - ./data:/srv
    environment:
      TYPECHO_SECURE: "1"
      # 若 Traefik 与容器不在默认私网段，请补充其 IP/CIDR：
      # REMOTEIP_TRUSTED_PROXIES: "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,172.18.0.0/16"
    labels:
      - traefik.enable=true
      - traefik.http.routers.typecho.rule=Host(`blog.example.com`)
      - traefik.http.routers.typecho.entrypoints=websecure
      - traefik.http.routers.typecho.tls.certresolver=letsencrypt
      - traefik.http.services.typecho.loadbalancer.server.port=80
    networks:
      - web

networks:
  web:
    external: true
```

## PHP2Shell 与安全

2026-10-21 披露的 **PHP2Shell**（CVE-2026-109618 / CVE-2026-109619，CVSS 9.2）影响 PHP 5.4–8.5.11，**mod_php（Apache）风险最高**。本镜像固定使用已修补的 **PHP 8.2.35**，并在 Docker 构建阶段执行 `version_compare` 检查。

Typecho 1.3 要求 PHP ≥ 7.4；官方建议使用 PHP 8.2。选择 8.2.35 而非 8.4.x 是为了与 Typecho 官方推荐主线一致，同时满足安全修补要求。

## 本地构建

```bash
docker build -t docker-typecho:local .
docker run --rm -p 8080:80 docker-typecho:local
```

## CI

推送到默认分支、打 tag、手动触发或 **每周一** 定时任务会构建 `linux/amd64` 与 `linux/arm64` 镜像并推送到 GHCR。标签包括 `latest`（默认分支）、`php-8.2.35` 以及 git commit SHA。

## License

See [LICENSE](LICENSE).
