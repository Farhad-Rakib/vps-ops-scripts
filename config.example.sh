#!/usr/bin/env bash

# Base feature flags
ENABLE_NGINX=1
ENABLE_SSL=0
ENABLE_DOCKER=0
ENABLE_POSTGRES=0
ENABLE_MYSQL=0
ENABLE_MSSQL=0
ENABLE_MONGO=0
ENABLE_SERILOG=0
ENABLE_VSCODE=0
ENABLE_FIREWALL=1

# Firewall configuration (ufw)
# Only the ports required by the enabled features above are opened.
# SSH is always allowed so you don't get locked out.
FIREWALL_SSH_PORT=22
# Database ports stay closed even when the database is enabled, since apps
# are expected to reach them over localhost. Flip these to 1 only if a
# database must accept remote connections.
FIREWALL_ALLOW_POSTGRES=0
FIREWALL_ALLOW_MYSQL=0
FIREWALL_ALLOW_MSSQL=0
FIREWALL_ALLOW_MONGO=0
# Space-separated list of any additional ports to allow, e.g. "8080/tcp 51820/udp"
FIREWALL_EXTRA_PORTS=""

# Nginx site configuration
SITE_DOMAIN="example.com"
SITE_EXTRA_SERVER_NAMES="www.example.com"
SITE_UPSTREAM_PORT=3000
SITE_ROOT="/var/www/example.com/public"
NGINX_CLIENT_MAX_BODY_SIZE="50m"

# SSL / Certbot
SSL_EMAIL="admin@example.com"

# Nginx rate limiting (per site, per client IP)
ENABLE_RATE_LIMIT=0
RATE_LIMIT_RPS=10
RATE_LIMIT_BURST=20
RATE_LIMIT_ZONE_SIZE="10m"
# nodelay rejects requests over the burst immediately instead of queueing them
RATE_LIMIT_NODELAY=1

# Backup configuration
BACKUP_TYPE="postgres"
BACKUP_NAME="appdb"
BACKUP_HOST="127.0.0.1"
BACKUP_PORT="5432"
BACKUP_USER="postgres"
BACKUP_PASSWORD=""
BACKUP_OUTPUT_DIR="/var/backups/db"
BACKUP_KEEP_DAYS=7
BACKUP_CRON_MINUTE=0
BACKUP_CRON_HOUR=2
BACKUP_CRON_DAY_OF_MONTH="*"
BACKUP_CRON_MONTH="*"
BACKUP_CRON_DAY_OF_WEEK="*"
BACKUP_CRON_LOG_FILE="/var/log/db-backup.log"

# Database ports (used for firewall rules; only opened if the matching
# FIREWALL_ALLOW_* flag above is set to 1)
POSTGRES_PORT=5432
MYSQL_PORT=3306
MSSQL_PORT=1433

# MSSQL configuration
MSSQL_SA_PASSWORD="ChangeMe_StrongPassword!123"
MSSQL_EDITION="Developer"

# Mongo configuration
MONGO_HOST="127.0.0.1"
MONGO_PORT="27017"
MONGO_USER=""
MONGO_PASSWORD=""
MONGO_AUTH_DB="admin"

# Serilog configuration
DOTNET_PROJECT_DIR="/opt/myapp"
SERILOG_PACKAGES=(
  "Serilog.AspNetCore"
  "Serilog.Settings.Configuration"
  "Serilog.Sinks.Console"
)
