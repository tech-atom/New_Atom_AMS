#!/bin/bash

###############################################################################
# Cognitio Pro LMS - Complete Production Deployment Script
# Purpose: Automated deployment to production server
# Run as: sudo bash deploy.sh
###############################################################################

set -e  # Exit on error
set -o pipefail  # Catch errors in pipelines

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "============================================================================"
echo "🚀 COGNITIO PRO LMS - PRODUCTION DEPLOYMENT"
echo "============================================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Please run as root: sudo bash deploy.sh${NC}"
    exit 1
fi

# Interactive configuration
echo -e "${BLUE}📝 DEPLOYMENT CONFIGURATION${NC}"
echo "Please provide the following information:"
echo ""

read -p "Domain name (e.g., cognitiopro.com): " DOMAIN
read -p "Application user (non-root, will be created): " APP_USER
read -p "MySQL root password: " -s MYSQL_ROOT_PASS
echo ""
read -p "New MySQL user password for LMS: " -s MYSQL_USER_PASS
echo ""
read -p "Application directory (e.g., /var/www/cognitiopro): " APP_DIR

# Generate random secret key
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")

echo ""
echo -e "${GREEN}✅ Configuration received${NC}"
echo ""

###############################################################################
# PHASE 1: System Update & Dependencies
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📦 PHASE 1: Installing System Dependencies${NC}"
echo -e "${BLUE}============================================================================${NC}"

apt update && apt upgrade -y

apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    nginx \
    mysql-server \
    redis-server \
    ufw \
    fail2ban \
    certbot \
    python3-certbot-nginx \
    git \
    curl \
    wget \
    supervisor \
    libmysqlclient-dev \
    pkg-config

echo -e "${GREEN}✅ System dependencies installed${NC}"

###############################################################################
# PHASE 2: Create Application User
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}👤 PHASE 2: Creating Application User${NC}"
echo -e "${BLUE}============================================================================${NC}"

if id "$APP_USER" &>/dev/null; then
    echo -e "${YELLOW}⚠️  User $APP_USER already exists${NC}"
else
    useradd -m -s /bin/bash "$APP_USER"
    echo -e "${GREEN}✅ User $APP_USER created${NC}"
fi

###############################################################################
# PHASE 3: Setup Application Directory
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}📁 PHASE 3: Setting Up Application Directory${NC}"
echo -e "${BLUE}============================================================================${NC}"

mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/logs"
mkdir -p "$APP_DIR/uploads/media"
mkdir -p "$APP_DIR/uploads/question_papers"
mkdir -p "$APP_DIR/uploads/student_responses"
mkdir -p "$APP_DIR/uploads/temp_questions"
mkdir -p /var/log/cognitiopro

# Copy application files (assumes script is run from project directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -r "$SCRIPT_DIR/"* "$APP_DIR/"

# Set permissions
chown -R "$APP_USER":"$APP_USER" "$APP_DIR"
chown -R "$APP_USER":"$APP_USER" /var/log/cognitiopro
chmod -R 755 "$APP_DIR"
chmod -R 770 "$APP_DIR/uploads"
chmod -R 770 "$APP_DIR/logs"

echo -e "${GREEN}✅ Application directory set up${NC}"

###############################################################################
# PHASE 4: Python Virtual Environment & Dependencies
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🐍 PHASE 4: Setting Up Python Environment${NC}"
echo -e "${BLUE}============================================================================${NC}"

cd "$APP_DIR"

# Create virtual environment
sudo -u "$APP_USER" python3 -m venv venv

# Activate and install dependencies
sudo -u "$APP_USER" bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

echo -e "${GREEN}✅ Python environment configured${NC}"

###############################################################################
# PHASE 5: MySQL Database Setup
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🗄️  PHASE 5: Configuring MySQL Database${NC}"
echo -e "${BLUE}============================================================================${NC}"

# Start MySQL
systemctl start mysql
systemctl enable mysql

# Create database and user
mysql -u root -p"$MYSQL_ROOT_PASS" <<EOF
CREATE DATABASE IF NOT EXISTS lms_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'lms_user'@'localhost' IDENTIFIED BY '$MYSQL_USER_PASS';
GRANT SELECT, INSERT, UPDATE, DELETE ON lms_system.* TO 'lms_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Import schema
if [ -f "$APP_DIR/database_schema.sql" ]; then
    mysql -u root -p"$MYSQL_ROOT_PASS" lms_system < "$APP_DIR/database_schema.sql"
    echo -e "${GREEN}✅ Database schema imported${NC}"
fi

# Secure MySQL
cat > /etc/mysql/mysql.conf.d/security.cnf <<EOF
[mysqld]
bind-address = 127.0.0.1
local-infile=0
max_connections = 150
max_connect_errors = 10
EOF

systemctl restart mysql

echo -e "${GREEN}✅ MySQL configured${NC}"

###############################################################################
# PHASE 6: Redis Setup
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}💾 PHASE 6: Configuring Redis${NC}"
echo -e "${BLUE}============================================================================${NC}"

systemctl start redis-server
systemctl enable redis-server

# Secure Redis
cat > /etc/redis/redis-security.conf <<EOF
bind 127.0.0.1
protected-mode yes
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF

systemctl restart redis-server

echo -e "${GREEN}✅ Redis configured${NC}"

###############################################################################
# PHASE 7: Environment Configuration
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}⚙️  PHASE 7: Creating Environment Configuration${NC}"
echo -e "${BLUE}============================================================================${NC}"

cat > "$APP_DIR/.env" <<EOF
# Production Environment Configuration
SECRET_KEY=$SECRET_KEY
FLASK_ENV=production
FLASK_DEBUG=False

# Database Configuration
DB_HOST=localhost
DB_USER=lms_user
DB_PASSWORD=$MYSQL_USER_PASS
DB_NAME=lms_system
DB_POOL_SIZE=32

# Security Configuration
SESSION_COOKIE_SECURE=True
SESSION_COOKIE_HTTPONLY=True
SESSION_COOKIE_SAMESITE=Lax
PERMANENT_SESSION_LIFETIME=3600

# Rate Limiting
RATELIMIT_STORAGE_URL=redis://localhost:6379/0
RATELIMIT_STRATEGY=fixed-window

# File Upload Configuration
MAX_CONTENT_LENGTH=52428800
ALLOWED_EXTENSIONS=txt,pdf,png,jpg,jpeg,gif,mp4,webm,csv,xlsx

# Cloudflare Configuration
CLOUDFLARE_IPS=True

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/cognitiopro/app.log
EOF

chown "$APP_USER":"$APP_USER" "$APP_DIR/.env"
chmod 600 "$APP_DIR/.env"

echo -e "${GREEN}✅ Environment configuration created${NC}"

###############################################################################
# PHASE 8: Gunicorn & Supervisor Setup
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔧 PHASE 8: Configuring Application Server${NC}"
echo -e "${BLUE}============================================================================${NC}"

cat > /etc/supervisor/conf.d/cognitiopro.conf <<EOF
[program:cognitiopro]
command=$APP_DIR/venv/bin/gunicorn --worker-class eventlet -w 4 --bind unix:$APP_DIR/cognitiopro.sock --timeout 120 app:app
directory=$APP_DIR
user=$APP_USER
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
stderr_logfile=/var/log/cognitiopro/gunicorn.err.log
stdout_logfile=/var/log/cognitiopro/gunicorn.out.log
environment=PATH="$APP_DIR/venv/bin"
EOF

systemctl restart supervisor
systemctl enable supervisor

echo -e "${GREEN}✅ Application server configured${NC}"

###############################################################################
# PHASE 9: Nginx Configuration
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🌐 PHASE 9: Configuring Nginx${NC}"
echo -e "${BLUE}============================================================================${NC}"

cat > /etc/nginx/sites-available/cognitiopro <<EOF
# Rate limiting zones
limit_req_zone \$binary_remote_addr zone=login:10m rate=5r/m;
limit_req_zone \$binary_remote_addr zone=api:10m rate=60r/m;
limit_req_zone \$binary_remote_addr zone=general:10m rate=100r/m;
limit_conn_zone \$binary_remote_addr zone=addr:10m;

upstream cognitiopro_app {
    server unix:$APP_DIR/cognitiopro.sock fail_timeout=0;
}

server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    client_max_body_size 50M;
    client_body_timeout 120s;
    
    # SSL Configuration (will be updated by certbot)
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Static files
    location /static {
        alias $APP_DIR/static;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    location /uploads {
        alias $APP_DIR/uploads;
        expires 7d;
    }
    
    # Login endpoint rate limiting
    location /login {
        limit_req zone=login burst=3 nodelay;
        proxy_pass http://cognitiopro_app;
        include /etc/nginx/proxy_params;
    }
    
    # API endpoints
    location ~* ^/(api|socket\.io) {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://cognitiopro_app;
        include /etc/nginx/proxy_params;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # All other requests
    location / {
        limit_req zone=general burst=30 nodelay;
        limit_conn addr 10;
        
        proxy_pass http://cognitiopro_app;
        include /etc/nginx/proxy_params;
    }
}
EOF

# Create proxy params if not exists
cat > /etc/nginx/proxy_params <<EOF
proxy_set_header Host \$http_host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
proxy_redirect off;
proxy_buffering off;
EOF

# Enable site
ln -sf /etc/nginx/sites-available/cognitiopro /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test configuration
nginx -t

echo -e "${GREEN}✅ Nginx configured${NC}"

###############################################################################
# PHASE 10: Firewall Configuration
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔥 PHASE 10: Configuring Firewall${NC}"
echo -e "${BLUE}============================================================================${NC}"

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw limit 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo -e "${GREEN}✅ Firewall configured${NC}"

###############################################################################
# PHASE 11: SSL Certificate (Let's Encrypt)
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🔒 PHASE 11: Obtaining SSL Certificate${NC}"
echo -e "${BLUE}============================================================================${NC}"

systemctl restart nginx

read -p "Obtain Let's Encrypt SSL certificate now? (requires DNS to be configured) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
    echo -e "${GREEN}✅ SSL certificate obtained${NC}"
else
    echo -e "${YELLOW}⚠️  Skipping SSL certificate. Run manually: certbot --nginx -d $DOMAIN -d www.$DOMAIN${NC}"
fi

###############################################################################
# PHASE 12: Fail2Ban Setup
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🛡️  PHASE 12: Configuring Fail2Ban${NC}"
echo -e "${BLUE}============================================================================${NC}"

cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
banaction = ufw

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF

systemctl restart fail2ban
systemctl enable fail2ban

echo -e "${GREEN}✅ Fail2Ban configured${NC}"

###############################################################################
# PHASE 13: Start Services
###############################################################################
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}🚀 PHASE 13: Starting All Services${NC}"
echo -e "${BLUE}============================================================================${NC}"

systemctl restart mysql
systemctl restart redis-server
systemctl restart supervisor
systemctl restart nginx
systemctl restart fail2ban

echo -e "${GREEN}✅ All services started${NC}"

###############################################################################
# DEPLOYMENT SUMMARY
###############################################################################
echo ""
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "${BLUE}📋 DEPLOYMENT SUMMARY${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Domain:              ${YELLOW}$DOMAIN${NC}"
echo -e "Application Dir:     ${YELLOW}$APP_DIR${NC}"
echo -e "Application User:    ${YELLOW}$APP_USER${NC}"
echo -e "Database:            ${YELLOW}lms_system${NC}"
echo -e "Database User:       ${YELLOW}lms_user${NC}"
echo -e "Secret Key:          ${YELLOW}(saved in .env)${NC}"
echo ""
echo -e "${BLUE}🔗 NEXT STEPS${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Configure DNS to point $DOMAIN to this server's IP"
echo "2. If SSL wasn't obtained, run: certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo "3. Configure Cloudflare WAF rules (see CLOUDFLARE_CONFIG.txt)"
echo "4. Test application: https://$DOMAIN"
echo "5. Create admin user through application interface"
echo "6. Review logs: /var/log/cognitiopro/"
echo ""
echo -e "${BLUE}📝 IMPORTANT FILES${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Environment Config:  $APP_DIR/.env"
echo "Application Logs:    /var/log/cognitiopro/"
echo "Nginx Config:        /etc/nginx/sites-available/cognitiopro"
echo "Supervisor Config:   /etc/supervisor/conf.d/cognitiopro.conf"
echo ""
echo -e "${BLUE}🔍 MONITORING COMMANDS${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "View application logs:   tail -f /var/log/cognitiopro/gunicorn.out.log"
echo "View error logs:         tail -f /var/log/cognitiopro/gunicorn.err.log"
echo "Restart application:     supervisorctl restart cognitiopro"
echo "Check application:       supervisorctl status cognitiopro"
echo "Nginx status:            systemctl status nginx"
echo "View Nginx access:       tail -f /var/log/nginx/access.log"
echo "View Nginx errors:       tail -f /var/log/nginx/error.log"
echo ""
echo -e "${GREEN}✅ Deployment script completed!${NC}"
echo ""
