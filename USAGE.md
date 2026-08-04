# Usage Guide

This repository provides a small VPS setup toolkit. The general flow is:

1. Bootstrap the server once.
2. Deploy one website.
3. Repeat the site deploy step for every new website on the same VPS.
4. Run backups or Serilog setup only when those features are needed.

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

For website deployment, set these values in `config.sh`:

- `SITE_DOMAIN`
- `SITE_UPSTREAM_PORT`
- `SITE_EXTRA_SERVER_NAMES` if you want aliases like `www`
- `SSL_EMAIL` if SSL is enabled

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

## Recommended workflow

For one VPS with multiple sites:

1. Bootstrap once.
2. Deploy the first site.
3. Deploy each new site with `deploy-site.sh`.
4. Keep your database backup job separate.
5. Add Serilog only in the app that needs it.

## Notes

- The scripts are currently tuned for Debian and Ubuntu.
- Nginx configuration assumes your app is listening on a local port such as `3000` or `4000`.
- The scripts are configurable, but they are intentionally simple and file-based.