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

# Nginx site configuration
SITE_DOMAIN="example.com"
SITE_EXTRA_SERVER_NAMES="www.example.com"
SITE_UPSTREAM_PORT=3000
SITE_ROOT="/var/www/example.com/public"
NGINX_CLIENT_MAX_BODY_SIZE="50m"

# SSL / Certbot
SSL_EMAIL="admin@example.com"

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
