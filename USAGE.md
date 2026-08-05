# Usage Guide

This repository provides a small VPS setup toolkit. The general flow is:

1. Bootstrap the server once.
2. Deploy one website.
3. Repeat the site deploy step for every new website on the same VPS.
4. Run backups or Serilog setup only when those features are needed.
5. Lock down the firewall and tune per-site rate limiting.

## 1. Prepare the config

Copy the example config to your active config file:

```bash
cp config.example.sh config.sh
```

Edit `config.sh` and set the feature flags you want to `1`.

Common flags:

- `ENABLE_NGINX=1` to install Nginx
- `ENABLE_SSL=1` to install Certbot support
- `ENABLE_DOCKER=1` to install Docker
- `ENABLE_POSTGRES=1` to install PostgreSQL
- `ENABLE_MYSQL=1` to install MySQL
- `ENABLE_MSSQL=1` to install MSSQL
- `ENABLE_MONGO=1` to install MongoDB
- `ENABLE_SERILOG=1` to allow Serilog package setup
- `ENABLE_VSCODE=1` to install VS Code (`code`) from Microsoft's apt repo
- `ENABLE_FIREWALL=1` to lock down ports with `ufw` (recommended, on by default)

For website deployment, set these values in `config.sh`:

- `SITE_DOMAIN`
- `SITE_UPSTREAM_PORT`
- `SITE_EXTRA_SERVER_NAMES` if you want aliases like `www`
- `SSL_EMAIL` if SSL is enabled
- `ENABLE_RATE_LIMIT=1` to cap requests per client IP, tuned with `RATE_LIMIT_RPS`, `RATE_LIMIT_BURST`, `RATE_LIMIT_ZONE_SIZE`, `RATE_LIMIT_NODELAY`

## 2. First-time VPS bootstrap

Run the bootstrap script once on a fresh server:

```bash
sudo bash scripts/bootstrap-vps.sh config.sh
```

This installs the base tools and any optional packages you enabled with flags.

## 3. Deploy the first website

If your `config.sh` already contains the domain and upstream port, deploy the site with:

```bash
sudo bash scripts/configure-nginx-site.sh config.sh
```

This creates an Nginx site file under `/etc/nginx/sites-available/` and enables it.

## 4. Deploy another website on the same VPS

For a second site, do not run the VPS bootstrap again. Keep the server as-is and deploy the new domain only:

```bash
sudo bash scripts/deploy-site.sh config.sh newdomain.com 4000
```

What this does:

- creates a new Nginx config for `newdomain.com`
- points it to port `4000`
- leaves your existing website untouched

If SSL is enabled, the script also tries to obtain a certificate with Certbot.

## 5. Back up a database

Set `BACKUP_TYPE` in `config.sh` to one of these values:

- `postgres`
- `mysql`
- `mssql`
- `mongo`

Then run:

```bash
bash scripts/db-backup.sh config.sh
```

To install the scheduled backup job automatically with the same config values, run:

```bash
sudo bash scripts/install-backup-cron.sh config.sh
```

The cron schedule comes from these config values:

- `BACKUP_CRON_MINUTE`
- `BACKUP_CRON_HOUR`
- `BACKUP_CRON_DAY_OF_MONTH`
- `BACKUP_CRON_MONTH`
- `BACKUP_CRON_DAY_OF_WEEK`
- `BACKUP_CRON_LOG_FILE`

The installed cron entry reuses the values from `config.sh`, including `BACKUP_TYPE`, `BACKUP_NAME`, `BACKUP_HOST`, `BACKUP_PORT`, and credentials.

## 6. Add Serilog packages

When `ENABLE_SERILOG=1`, you can add Serilog packages to a .NET project:

```bash
bash scripts/setup-serilog.sh config.sh
```

Set `DOTNET_PROJECT_DIR` to the folder containing the `.csproj` file.

## 7. Lock down the firewall

When `ENABLE_FIREWALL=1`, the bootstrap script configures `ufw` to deny all
incoming traffic by default and only allow what you've actually enabled:

- SSH is always allowed, on `FIREWALL_SSH_PORT` (default `22`)
- HTTP (`80`) is allowed only if `ENABLE_NGINX=1`
- HTTPS (`443`) is allowed only if `ENABLE_SSL=1`
- Database ports stay closed even when the database is enabled, since the
  app is expected to reach it over `localhost`. Set the matching
  `FIREWALL_ALLOW_POSTGRES`, `FIREWALL_ALLOW_MYSQL`, `FIREWALL_ALLOW_MSSQL`,
  or `FIREWALL_ALLOW_MONGO` flag to `1` only if that database must accept
  remote connections
- Any other ports you need can be listed in `FIREWALL_EXTRA_PORTS`, e.g.
  `FIREWALL_EXTRA_PORTS="8080/tcp 51820/udp"`

You can also run it on its own, e.g. after changing flags on an existing server:

```bash
sudo bash scripts/configure-firewall.sh config.sh
```

## 8. Rate limit a site

When `ENABLE_RATE_LIMIT=1`, `configure-nginx-site.sh` (and `deploy-site.sh`)
add an Nginx `limit_req_zone`/`limit_req` for that site, keyed by client IP:

- `RATE_LIMIT_RPS` - sustained requests per second per IP (default `10`)
- `RATE_LIMIT_BURST` - extra requests allowed in a short spike (default `20`)
- `RATE_LIMIT_ZONE_SIZE` - memory reserved for tracking IPs, e.g. `10m` (~160k IPs)
- `RATE_LIMIT_NODELAY` - `1` rejects requests over the burst immediately instead of queueing them (default `1`)

Each site gets its own zone, so limits don't leak across domains on the same VPS.
Re-run the site's deploy command after changing these values:

```bash
sudo bash scripts/configure-nginx-site.sh config.sh
# or, for an additional site
sudo bash scripts/deploy-site.sh config.sh newdomain.com 4000
```

## Recommended workflow

For one VPS with multiple sites:

1. Bootstrap once, with `ENABLE_FIREWALL=1` so only necessary ports are open.
2. Deploy the first site, tuning `ENABLE_RATE_LIMIT` and its `RATE_LIMIT_*` values if needed.
3. Deploy each new site with `deploy-site.sh`.
4. Keep your database backup job separate.
5. Add Serilog only in the app that needs it.

## Notes

- The scripts are currently tuned for Debian and Ubuntu.
- Nginx configuration assumes your app is listening on a local port such as `3000` or `4000`.
- The scripts are configurable, but they are intentionally simple and file-based.
- `configure-firewall.sh` resets and re-applies all `ufw` rules each time it runs, so it always reflects your current config flags rather than accumulating stale rules.