# Zellij Web Service

This setup runs Zellij Web as a user-level systemd service and exposes it through
the existing Traefik reverse proxy.

## Architecture

```text
Browser
  -> https://console.ristw.dev
  -> Traefik manages the public ristw.dev TLS certificate
  -> https://192.168.88.187:8084
  -> Zellij Web uses a local self-signed backend certificate
```

Zellij does not read the Let's Encrypt private key directly. The public TLS
certificate remains managed by Traefik.

## Files

- Service template in this repo:
  - `systemd/zellij-web.service`
- Installed user service:
  - `/home/www10177/.config/systemd/user/zellij-web.service`
- Zellij backend certificate:
  - `/home/www10177/.config/zellij/certs/zellij-web.crt`
  - `/home/www10177/.config/zellij/certs/zellij-web.key`
- Traefik dynamic config:
  - `/srv/ristw-nexus/core/traefik/dynamic/external-services.yml`
- Traefik backup created before adding the console route:
  - `/srv/ristw-nexus/core/traefik/dynamic/external-services.yml.bak-console`

## Traefik Route

The only public entrypoint is:

```text
console.ristw.dev
```

The Traefik file provider route is:

```yaml
console-dev:
  rule: "Host(`console.ristw.dev`)"
  service: console-svc
  tls: {}

console-svc:
  loadBalancer:
    servers:
      - url: "https://192.168.88.187:8084"
```

Traefik already has `serversTransport.insecureSkipVerify: true`, so it accepts
the Zellij backend self-signed certificate while still serving the real public
certificate to browsers.

## Deploy

Install or update the user service:

```bash
install -m 0644 systemd/zellij-web.service ~/.config/systemd/user/zellij-web.service
systemctl --user daemon-reload
systemctl --user enable --now zellij-web.service
loginctl enable-linger "$USER"
```

Create or rotate the backend certificate:

```bash
mkdir -p ~/.config/zellij/certs
openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
  -keyout ~/.config/zellij/certs/zellij-web.key \
  -out ~/.config/zellij/certs/zellij-web.crt \
  -subj "/CN=console.ristw.dev" \
  -addext "subjectAltName=DNS:console.ristw.dev,IP:192.168.88.187"
chmod 600 ~/.config/zellij/certs/zellij-web.key ~/.config/zellij/certs/zellij-web.crt
systemctl --user restart zellij-web.service
```

## Manage

```bash
systemctl --user status zellij-web.service
systemctl --user restart zellij-web.service
journalctl --user -u zellij-web.service -f
```

Verify from the host:

```bash
curl -k -I https://192.168.88.187:8084
curl -I https://console.ristw.dev
```

## Rollback

Stop the Zellij user service:

```bash
systemctl --user disable --now zellij-web.service
```

Restore Traefik dynamic config if needed:

```bash
cp /srv/ristw-nexus/core/traefik/dynamic/external-services.yml.bak-console \
  /srv/ristw-nexus/core/traefik/dynamic/external-services.yml
```
