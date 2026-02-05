# 🚀 COGNITIO PRO LMS - Production Deployment Guide

## Overview
This guide provides step-by-step instructions to deploy the Cognitio Pro Learning Management System to a production server with enterprise-grade security.

---

## 📋 Prerequisites

### Server Requirements
- **OS**: Ubuntu 20.04+ or Debian 11+
- **RAM**: Minimum 2GB (4GB+ recommended)
- **Storage**: 20GB+ available disk space
- **CPU**: 2+ cores recommended
- **Network**: Static IP address, ports 80/443 accessible

### Required Accounts & Access
- [ ] Root/sudo access to server
- [ ] Domain name registered
- [ ] DNS management access
- [ ] Cloudflare account (free tier) - optional but recommended

### Local Requirements
- SSH client (OpenSSH, PuTTY, etc.)
- SFTP/SCP client for file transfer (FileZilla, WinSCP, rsync)

---

## 🎯 Deployment Options

### Option 1: Automated Deployment (Recommended)
**Time Required**: ~30-45 minutes
**Difficulty**: Easy

Use the provided `deploy.sh` script for fully automated deployment.

### Option 2: Manual Deployment
**Time Required**: ~2-3 hours
**Difficulty**: Intermediate to Advanced

Follow the step-by-step manual instructions for complete control.

---

## 🤖 OPTION 1: Automated Deployment

### Step 1: Prepare Your Server

1. **Connect to your server via SSH**:
   ```bash
   ssh root@YOUR_SERVER_IP
   ```

2. **Update system packages**:
   ```bash
   apt update && apt upgrade -y
   ```

3. **Install Git** (if not already installed):
   ```bash
   apt install git -y
   ```

### Step 2: Upload Application Files

**Option A: Using Git** (if repository is available):
```bash
cd /opt
git clone YOUR_REPOSITORY_URL cognitiopro
cd cognitiopro
```

**Option B: Using SCP/SFTP**:

On your local machine (Windows PowerShell):
```powershell
# Navigate to project directory
cd d:\project1\project

# Upload to server
scp -r * root@YOUR_SERVER_IP:/opt/cognitiopro/
```

Or use FileZilla/WinSCP to upload all files to `/opt/cognitiopro/`

### Step 3: Run Deployment Script

1. **Navigate to application directory**:
   ```bash
   cd /opt/cognitiopro
   ```

2. **Make script executable**:
   ```bash
   chmod +x deploy.sh
   ```

3. **Run deployment script**:
   ```bash
   sudo bash deploy.sh
   ```

4. **Provide required information when prompted**:
   - Domain name (e.g., `cognitiopro.com`)
   - Application username (e.g., `cognitiopro`)
   - MySQL root password
   - New MySQL user password
   - Application directory (default: `/var/www/cognitiopro`)

5. **Wait for completion** (~20-30 minutes)

### Step 4: Configure DNS

1. Log in to your domain registrar or DNS provider
2. Add/Update A records:
   - `@` (root domain) → YOUR_SERVER_IP
   - `www` → YOUR_SERVER_IP
3. Wait for DNS propagation (5-30 minutes)

### Step 5: Obtain SSL Certificate

If you skipped SSL during deployment:
```bash
certbot --nginx -d cognitiopro.com -d www.cognitiopro.com
```

### Step 6: Verify Deployment

1. **Check services are running**:
   ```bash
   supervisorctl status cognitiopro
   systemctl status nginx
   systemctl status mysql
   systemctl status redis-server
   ```

2. **Test application**:
   - Open browser: `https://YOUR_DOMAIN`
   - You should see the login/homepage

3. **Check logs**:
   ```bash
   tail -f /var/log/cognitiopro/gunicorn.out.log
   ```

---

## 🔧 OPTION 2: Manual Deployment

### Phase 1: System Preparation (10 minutes)

1. **Connect to server**:
   ```bash
   ssh root@YOUR_SERVER_IP
   ```

2. **Update system**:
   ```bash
   apt update && apt upgrade -y
   ```

3. **Install dependencies**:
   ```bash
   apt install -y python3 python3-pip python3-venv python3-dev build-essential \
       nginx mysql-server redis-server ufw fail2ban certbot \
       python3-certbot-nginx git curl wget supervisor \
       libmysqlclient-dev pkg-config
   ```

### Phase 2: Create Application User (5 minutes)

```bash
# Create non-root user
useradd -m -s /bin/bash cognitiopro

# Create application directory
mkdir -p /var/www/cognitiopro
mkdir -p /var/log/cognitiopro
```

### Phase 3: Upload & Setup Application (15 minutes)

1. **Upload files** (use SCP/SFTP to upload to `/var/www/cognitiopro/`)

2. **Create directory structure**:
   ```bash
   cd /var/www/cognitiopro
   mkdir -p logs uploads/{media,question_papers,student_responses,temp_questions}
   ```

3. **Set permissions**:
   ```bash
   chown -R cognitiopro:cognitiopro /var/www/cognitiopro
   chown -R cognitiopro:cognitiopro /var/log/cognitiopro
   chmod -R 755 /var/www/cognitiopro
   chmod -R 770 /var/www/cognitiopro/uploads
   ```

### Phase 4: Python Environment (10 minutes)

```bash
cd /var/www/cognitiopro

# Create virtual environment
sudo -u cognitiopro python3 -m venv venv

# Install dependencies
sudo -u cognitiopro bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"
```

### Phase 5: MySQL Database (15 minutes)

1. **Start MySQL**:
   ```bash
   systemctl start mysql
   systemctl enable mysql
   ```

2. **Secure MySQL** (if first time):
   ```bash
   mysql_secure_installation
   ```

3. **Create database and user**:
   ```bash
   mysql -u root -p
   ```
   
   Then run:
   ```sql
   CREATE DATABASE lms_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   CREATE USER 'lms_user'@'localhost' IDENTIFIED BY 'STRONG_PASSWORD_HERE';
   GRANT SELECT, INSERT, UPDATE, DELETE ON lms_system.* TO 'lms_user'@'localhost';
   FLUSH PRIVILEGES;
   EXIT;
   ```

4. **Import schema**:
   ```bash
   mysql -u root -p lms_system < /var/www/cognitiopro/database_schema.sql
   ```

5. **Secure MySQL configuration**:
   ```bash
   cat > /etc/mysql/mysql.conf.d/security.cnf <<EOF
   [mysqld]
   bind-address = 127.0.0.1
   local-infile=0
   max_connections = 150
   EOF
   
   systemctl restart mysql
   ```

### Phase 6: Redis Configuration (5 minutes)

```bash
# Start Redis
systemctl start redis-server
systemctl enable redis-server

# Secure Redis
echo "bind 127.0.0.1" >> /etc/redis/redis.conf
echo "protected-mode yes" >> /etc/redis/redis.conf
systemctl restart redis-server
```

### Phase 7: Environment Configuration (5 minutes)

1. **Generate secret key**:
   ```bash
   python3 -c "import secrets; print(secrets.token_hex(32))"
   ```

2. **Edit .env file**:
   ```bash
   nano /var/www/cognitiopro/.env
   ```

3. **Update these values**:
   ```
   SECRET_KEY=<your_generated_key>
   DB_PASSWORD=<your_mysql_password>
   ```

4. **Secure the file**:
   ```bash
   chown cognitiopro:cognitiopro /var/www/cognitiopro/.env
   chmod 600 /var/www/cognitiopro/.env
   ```

### Phase 8: Gunicorn & Supervisor (10 minutes)

1. **Create supervisor configuration**:
   ```bash
   nano /etc/supervisor/conf.d/cognitiopro.conf
   ```

2. **Add this content**:
   ```ini
   [program:cognitiopro]
   command=/var/www/cognitiopro/venv/bin/gunicorn --worker-class eventlet -w 4 --bind unix:/var/www/cognitiopro/cognitiopro.sock --timeout 120 app:app
   directory=/var/www/cognitiopro
   user=cognitiopro
   autostart=true
   autorestart=true
   stopasgroup=true
   killasgroup=true
   stderr_logfile=/var/log/cognitiopro/gunicorn.err.log
   stdout_logfile=/var/log/cognitiopro/gunicorn.out.log
   environment=PATH="/var/www/cognitiopro/venv/bin"
   ```

3. **Start application**:
   ```bash
   supervisorctl reread
   supervisorctl update
   supervisorctl start cognitiopro
   supervisorctl status
   ```

### Phase 9: Nginx Configuration (15 minutes)

1. **Create Nginx site configuration**:
   ```bash
   nano /etc/nginx/sites-available/cognitiopro
   ```

2. **Add configuration** (see deploy.sh for full config, or use existing nginx config)

3. **Create proxy params**:
   ```bash
   cat > /etc/nginx/proxy_params <<EOF
   proxy_set_header Host \$http_host;
   proxy_set_header X-Real-IP \$remote_addr;
   proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
   proxy_set_header X-Forwarded-Proto \$scheme;
   proxy_redirect off;
   proxy_buffering off;
   EOF
   ```

4. **Enable site**:
   ```bash
   ln -s /etc/nginx/sites-available/cognitiopro /etc/nginx/sites-enabled/
   rm -f /etc/nginx/sites-enabled/default
   nginx -t
   systemctl restart nginx
   systemctl enable nginx
   ```

### Phase 10: Firewall (5 minutes)

```bash
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw limit 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
ufw status
```

### Phase 11: SSL Certificate (10 minutes)

1. **Ensure DNS is configured** (A records pointing to server)

2. **Obtain certificate**:
   ```bash
   certbot --nginx -d cognitiopro.com -d www.cognitiopro.com
   ```

3. **Test auto-renewal**:
   ```bash
   certbot renew --dry-run
   ```

### Phase 12: Fail2Ban (5 minutes)

```bash
# Install and configure
apt install fail2ban -y

cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
EOF

systemctl restart fail2ban
systemctl enable fail2ban
```

---

## 🔒 Post-Deployment Security

### 1. Cloudflare Configuration (Recommended)

1. **Add site to Cloudflare**:
   - Sign up at cloudflare.com
   - Add your domain
   - Update nameservers at domain registrar

2. **Configure SSL/TLS**:
   - Go to SSL/TLS → Overview
   - Set to "Full (strict)"

3. **Enable Security Features**:
   - Go to Security → WAF
   - Enable Managed Rules
   - Add custom rules from `CLOUDFLARE_CONFIG.txt`

4. **Configure Firewall Rules**:
   - Follow rules in `CLOUDFLARE_CONFIG.txt`

### 2. Update Firewall Rules

If using Cloudflare, restrict port 443 to Cloudflare IPs:
```bash
# See Cloudflare documentation for current IP ranges
```

### 3. Regular Updates

```bash
# Create cron job for automatic updates
crontab -e

# Add:
0 2 * * 0 apt update && apt upgrade -y
0 3 * * * certbot renew --quiet
```

---

## 📊 Monitoring & Maintenance

### View Logs

```bash
# Application logs
tail -f /var/log/cognitiopro/gunicorn.out.log
tail -f /var/log/cognitiopro/gunicorn.err.log

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# MySQL logs
tail -f /var/log/mysql/error.log
```

### Restart Services

```bash
# Restart application
supervisorctl restart cognitiopro

# Restart Nginx
systemctl restart nginx

# Restart MySQL
systemctl restart mysql

# Restart all
systemctl restart supervisor nginx mysql redis-server
```

### Database Backup

```bash
# Create backup script
cat > /var/www/cognitiopro/backup.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/cognitiopro"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR
mysqldump -u lms_user -p lms_system > $BACKUP_DIR/lms_system_$DATE.sql
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
EOF

chmod +x /var/www/cognitiopro/backup.sh

# Add to cron
crontab -e
# Add: 0 2 * * * /var/www/cognitiopro/backup.sh
```

---

## 🔍 Troubleshooting

### Application Won't Start

```bash
# Check supervisor status
supervisorctl status cognitiopro

# View error logs
tail -50 /var/log/cognitiopro/gunicorn.err.log

# Restart
supervisorctl restart cognitiopro
```

### Database Connection Issues

```bash
# Test MySQL connection
mysql -u lms_user -p lms_system

# Check MySQL is running
systemctl status mysql

# Review MySQL logs
tail -50 /var/log/mysql/error.log
```

### SSL Certificate Issues

```bash
# Check certificate
certbot certificates

# Renew manually
certbot renew --force-renewal

# Check Nginx config
nginx -t
```

### Permission Issues

```bash
# Reset permissions
cd /var/www/cognitiopro
chown -R cognitiopro:cognitiopro .
chmod -R 755 .
chmod -R 770 uploads logs
chmod 600 .env
```

---

## ✅ Deployment Verification Checklist

- [ ] Server accessible via SSH
- [ ] All services running (nginx, mysql, redis, supervisor)
- [ ] Application accessible via HTTPS
- [ ] No SSL/TLS warnings in browser
- [ ] Login page loads correctly
- [ ] Can create admin account
- [ ] Database connections working
- [ ] File uploads working
- [ ] Firewall configured and active
- [ ] Fail2Ban active
- [ ] Backup script configured
- [ ] Cloudflare configured (if using)
- [ ] DNS properly configured
- [ ] Logs accessible and readable

---

## 📞 Support & Additional Resources

- **Documentation**: See all .md files in project directory
- **Security Guide**: `ENTERPRISE_SECURITY_GUIDE.md`
- **Cloudflare Setup**: `CLOUDFLARE_CONFIG.txt`
- **Deployment Checklist**: `DEPLOYMENT_CHECKLIST.md`

---

## 🎓 Quick Reference Commands

```bash
# Application Management
supervisorctl status                    # Check app status
supervisorctl restart cognitiopro       # Restart app
tail -f /var/log/cognitiopro/*.log     # View logs

# Service Management
systemctl status nginx                  # Nginx status
systemctl restart nginx                 # Restart Nginx
systemctl status mysql                  # MySQL status

# Security
ufw status                             # Firewall status
fail2ban-client status                 # Fail2Ban status
certbot certificates                   # SSL cert info

# Database
mysql -u lms_user -p lms_system        # Connect to DB
mysqldump -u lms_user -p lms_system > backup.sql  # Backup

# Monitoring
htop                                   # System resources
df -h                                  # Disk usage
free -h                                # Memory usage
```

---

**Deployment Guide Version**: 1.0  
**Last Updated**: February 2026  
**Project**: Cognitio Pro LMS
