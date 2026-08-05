# VPS Shell Scripts

Opinionated shell scripts for bootstrapping a new VPS and deploying apps with configurable features.

See [USAGE.md](/Users/farhadrakib/Personal%20Projects/shell-scripts/USAGE.md) for the step-by-step guide.

## Files

- `config.example.sh` - toggle features with `0` or `1`
- `scripts/bootstrap-vps.sh` - install the base server packages
- `scripts/deploy-site.sh` - deploy another website on the same VPS
- `scripts/configure-nginx-site.sh` - create an Nginx site for a domain
- `scripts/db-backup.sh` - back up PostgreSQL, MySQL, MSSQL, or MongoDB
- `scripts/install-backup-cron.sh` - install the scheduled backup cron entry
- `scripts/setup-serilog.sh` - add Serilog packages to a .NET project
- `scripts/configure-firewall.sh` - configure ufw to only open necessary ports

## Quick start

1. Copy `config.example.sh` to `config.sh`.
2. Set the flags you want to `1`.
3. Run the bootstrap script as root:

```bash
sudo bash scripts/bootstrap-vps.sh config.sh
```

4. Create an Nginx site:

```bash
sudo bash scripts/configure-nginx-site.sh config.sh
```

For a second website on the same VPS, reuse the bootstrap and run:

```bash
sudo bash scripts/deploy-site.sh config.sh newdomain.com 4000
```

That creates a new Nginx site file for the new domain and leaves the first site untouched.

5. Run backups manually or from cron:

```bash
bash scripts/db-backup.sh config.sh
```

6. Add Serilog packages to a .NET project:

```bash
bash scripts/setup-serilog.sh config.sh
```

## Flags

Set any feature flag to `1` to enable it. Leave it at `0` to skip it.

- `ENABLE_NGINX`
- `ENABLE_SSL`
- `ENABLE_DOCKER`
- `ENABLE_POSTGRES`
- `ENABLE_MYSQL`
- `ENABLE_MSSQL`
- `ENABLE_MONGO`
- `ENABLE_SERILOG`
- `ENABLE_VSCODE`
- `ENABLE_FIREWALL`
- `ENABLE_RATE_LIMIT`

## Notes

- The scripts are tuned for Debian and Ubuntu VPS images.
- MSSQL and MongoDB install steps use the official vendor repositories.
- `setup-serilog.sh` adds packages only; it does not rewrite your application code.
- `deploy-site.sh` is the repeatable entry point for additional websites on the same server.
- `configure-firewall.sh` uses `ufw` and only opens SSH plus whatever `ENABLE_*`/`FIREWALL_ALLOW_*` flags call for; database ports stay closed by default.
- `ENABLE_VSCODE` installs the `code` CLI/editor package from Microsoft's apt repo; on a headless VPS this is mainly useful for `code tunnel` remote access.
- `ENABLE_RATE_LIMIT` adds an nginx `limit_req_zone`/`limit_req` per site, keyed by client IP, using `RATE_LIMIT_RPS`/`RATE_LIMIT_BURST`.