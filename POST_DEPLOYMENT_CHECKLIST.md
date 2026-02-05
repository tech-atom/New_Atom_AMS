# ✅ POST-DEPLOYMENT VERIFICATION CHECKLIST
**Cognitio Pro LMS - Production Deployment**

Use this checklist to verify your deployment is complete and secure.

---

## 🔐 PHASE 1: SYSTEM ACCESS (5 minutes)

### SSH & Server Access
- [ ] Can connect to server via SSH
- [ ] Non-root user created and accessible
- [ ] Root access disabled or restricted (recommended)
- [ ] SSH keys configured (password login disabled recommended)
- [ ] Server time zone configured correctly: `timedatectl`

### File System
- [ ] Application directory exists: `/var/www/cognitiopro` (or your path)
- [ ] All application files present
- [ ] Upload directories created and writable
- [ ] Log directories created and writable
- [ ] Correct ownership: `ls -la /var/www/cognitiopro`
- [ ] Correct permissions on .env file (600)

**Verification Commands:**
```bash
# Check user
id cognitiopro

# Check files
ls -la /var/www/cognitiopro

# Check permissions
ls -l /var/www/cognitiopro/.env
ls -ld /var/www/cognitiopro/uploads
```

---

## 🗄️ PHASE 2: DATABASE (10 minutes)

### MySQL Service
- [ ] MySQL service running: `systemctl status mysql`
- [ ] MySQL starts on boot: `systemctl is-enabled mysql`
- [ ] MySQL listening on localhost only
- [ ] No external database access configured

### Database & User
- [ ] Database `lms_system` created
- [ ] Database user `lms_user` created with limited privileges
- [ ] Can connect with application credentials
- [ ] Schema tables created and empty (or with test data)
- [ ] Database character set is utf8mb4

**Verification Commands:**
```bash
# Test connection
mysql -u lms_user -p lms_system

# In MySQL shell, run:
SHOW TABLES;
SELECT COUNT(*) FROM exam;
SHOW VARIABLES LIKE 'character_set_database';
EXIT;
```

### Database Security
- [ ] Root password set and secure
- [ ] Anonymous users removed
- [ ] Test database removed
- [ ] Remote root login disabled
- [ ] bind-address set to 127.0.0.1
- [ ] Max connections configured

**Verification Commands:**
```bash
# Check MySQL config
cat /etc/mysql/mysql.conf.d/security.cnf

# Check listening address
netstat -tlnp | grep 3306
# Should show: 127.0.0.1:3306
```

---

## 💾 PHASE 3: REDIS (5 minutes)

### Redis Service
- [ ] Redis service running: `systemctl status redis-server`
- [ ] Redis starts on boot: `systemctl is-enabled redis-server`
- [ ] Redis listening on localhost only
- [ ] Redis protected mode enabled

**Verification Commands:**
```bash
# Test Redis
redis-cli ping
# Should return: PONG

# Check binding
redis-cli CONFIG GET bind
# Should show: 127.0.0.1

# Check protected mode
redis-cli CONFIG GET protected-mode
# Should show: yes
```

---

## 🐍 PHASE 4: PYTHON ENVIRONMENT (10 minutes)

### Virtual Environment
- [ ] Virtual environment created at `venv/`
- [ ] Virtual environment owned by application user
- [ ] Can activate virtual environment
- [ ] Python version 3.9 or higher

### Dependencies
- [ ] All packages from requirements.txt installed
- [ ] Flask installed and accessible
- [ ] Gunicorn installed
- [ ] Security packages installed (flask-talisman, flask-limiter, etc.)
- [ ] Database connector installed
- [ ] SocketIO installed

**Verification Commands:**
```bash
# Activate environment
cd /var/www/cognitiopro
sudo -u cognitiopro bash -c "source venv/bin/activate && python --version"

# Check installed packages
sudo -u cognitiopro bash -c "source venv/bin/activate && pip list"

# Verify key packages
sudo -u cognitiopro bash -c "source venv/bin/activate && pip list | grep -E 'Flask|gunicorn|mysql-connector|talisman|limiter'"
```

---

## 🚀 PHASE 5: APPLICATION SERVER (10 minutes)

### Gunicorn & Supervisor
- [ ] Supervisor service running: `systemctl status supervisor`
- [ ] Cognitiopro application configured in Supervisor
- [ ] Application process running: `supervisorctl status cognitiopro`
- [ ] Unix socket created: `/var/www/cognitiopro/cognitiopro.sock`
- [ ] Application logs being written
- [ ] No errors in application logs

**Verification Commands:**
```bash
# Check Supervisor
systemctl status supervisor
supervisorctl status

# Check application status
supervisorctl status cognitiopro
# Should show: RUNNING

# Check socket
ls -l /var/www/cognitiopro/cognitiopro.sock

# View recent logs
tail -30 /var/log/cognitiopro/gunicorn.out.log
tail -30 /var/log/cognitiopro/gunicorn.err.log
```

### Configuration Files
- [ ] .env file exists and configured
- [ ] SECRET_KEY is unique and secure (not default)
- [ ] Database credentials correct in .env
- [ ] Production mode enabled (FLASK_ENV=production, FLASK_DEBUG=False)
- [ ] File upload limits configured

**Verification Commands:**
```bash
# Check .env exists
ls -l /var/www/cognitiopro/.env

# Verify production settings (don't expose secrets)
sudo -u cognitiopro grep -E "FLASK_ENV|FLASK_DEBUG" /var/www/cognitiopro/.env
```

---

## 🌐 PHASE 6: NGINX WEB SERVER (15 minutes)

### Nginx Service
- [ ] Nginx service running: `systemctl status nginx`
- [ ] Nginx starts on boot: `systemctl is-enabled nginx`
- [ ] Configuration test passes: `nginx -t`
- [ ] Site configuration enabled
- [ ] Default site disabled

**Verification Commands:**
```bash
# Check Nginx
systemctl status nginx
nginx -t

# Check enabled sites
ls -l /etc/nginx/sites-enabled/
```

### Nginx Configuration
- [ ] Server listens on port 80 (HTTP)
- [ ] Server listens on port 443 (HTTPS)
- [ ] HTTP redirects to HTTPS
- [ ] Proxy configuration correct
- [ ] Static files served directly
- [ ] Upload size limit configured (50MB)
- [ ] Rate limiting configured
- [ ] Security headers configured

**Verification Commands:**
```bash
# Check configuration
cat /etc/nginx/sites-available/cognitiopro | grep -E "listen|server_name|limit_req"

# Test HTTP redirect (from another machine or curl)
curl -I http://YOUR_DOMAIN.com
# Should show: 301 redirect to https
```

### Request Testing
- [ ] HTTP request redirects to HTTPS
- [ ] HTTPS loads without errors
- [ ] Static files accessible (CSS, JS)
- [ ] WebSocket connections work (Socket.IO)
- [ ] Large file uploads work (up to 50MB)

---

## 🔒 PHASE 7: SSL/TLS CERTIFICATE (10 minutes)

### Certificate Status
- [ ] SSL certificate obtained
- [ ] Certificate valid and not expired
- [ ] Certificate matches domain
- [ ] Certificate chain complete
- [ ] Auto-renewal configured
- [ ] Certbot cron job exists

**Verification Commands:**
```bash
# Check certificates
certbot certificates

# Test renewal
certbot renew --dry-run

# Check certificate expiry
echo | openssl s_client -servername YOUR_DOMAIN -connect YOUR_DOMAIN:443 2>/dev/null | openssl x509 -noout -dates
```

### SSL/TLS Security
- [ ] TLS 1.2 minimum (TLS 1.3 preferred)
- [ ] Strong cipher suites configured
- [ ] HSTS header present
- [ ] No SSL vulnerabilities (test with SSL Labs)

**Verification Commands:**
```bash
# Check SSL from remote
curl -I https://YOUR_DOMAIN | grep -i strict-transport

# Full SSL test at: https://www.ssllabs.com/ssltest/
```

---

## 🔥 PHASE 8: FIREWALL & SECURITY (10 minutes)

### UFW Firewall
- [ ] UFW installed and enabled
- [ ] Default deny incoming configured
- [ ] SSH (22) allowed with rate limiting
- [ ] HTTP (80) allowed
- [ ] HTTPS (443) allowed
- [ ] All other ports blocked
- [ ] Firewall rules active

**Verification Commands:**
```bash
# Check UFW status
ufw status verbose

# Should show:
# Status: active
# 22/tcp LIMIT
# 80/tcp ALLOW
# 443/tcp ALLOW
```

### Fail2Ban
- [ ] Fail2Ban installed: `fail2ban-client version`
- [ ] Fail2Ban service running: `systemctl status fail2ban`
- [ ] SSH jail enabled
- [ ] Nginx jails enabled
- [ ] Ban actions configured
- [ ] Email notifications configured (optional)

**Verification Commands:**
```bash
# Check Fail2Ban
systemctl status fail2ban
fail2ban-client status

# Check active jails
fail2ban-client status sshd
fail2ban-client status nginx-http-auth
```

### Security Headers
- [ ] HSTS header present
- [ ] X-Frame-Options present
- [ ] X-Content-Type-Options present
- [ ] X-XSS-Protection present
- [ ] Referrer-Policy present
- [ ] Content-Security-Policy configured

**Verification Commands:**
```bash
# Check security headers
curl -I https://YOUR_DOMAIN | grep -i "x-\|strict\|content-security"
```

---

## 🌐 PHASE 9: DNS & DOMAIN (5 minutes)

### DNS Configuration
- [ ] A record for @ points to server IP
- [ ] A record for www points to server IP
- [ ] DNS propagation complete (check multiple locations)
- [ ] Domain accessible without www
- [ ] Domain accessible with www
- [ ] Both redirect to HTTPS

**Verification Commands:**
```bash
# Check DNS resolution
dig YOUR_DOMAIN +short
dig www.YOUR_DOMAIN +short

# Check from multiple locations at: https://dnschecker.org/
```

---

## ☁️ PHASE 10: CLOUDFLARE (OPTIONAL) (15 minutes)

If using Cloudflare:

### Cloudflare Setup
- [ ] Domain added to Cloudflare
- [ ] Nameservers updated at registrar
- [ ] Nameservers active (propagated)
- [ ] SSL/TLS mode set to "Full (strict)"
- [ ] Always Use HTTPS enabled
- [ ] Automatic HTTPS Rewrites enabled

### Cloudflare Security
- [ ] WAF enabled
- [ ] Managed Rules enabled
- [ ] Custom rules created (from CLOUDFLARE_CONFIG.txt)
- [ ] Rate limiting configured
- [ ] Bot Fight Mode enabled
- [ ] Under Attack mode tested (optional)

### Cloudflare Performance
- [ ] Auto Minify enabled (HTML, CSS, JS)
- [ ] Brotli compression enabled
- [ ] Early Hints enabled
- [ ] Caching configured appropriately

**Verification:**
- Test at: https://www.cloudflare.com/ssl/encrypted-sni/
- Check WAF logs in Cloudflare dashboard

---

## 🧪 PHASE 11: APPLICATION FUNCTIONALITY (20 minutes)

### Basic Functionality
- [ ] Home page loads
- [ ] Login page accessible
- [ ] Registration page accessible (if applicable)
- [ ] Can create admin account
- [ ] Can log in with admin credentials
- [ ] Session persistence works
- [ ] Logout works

### Admin Functions
- [ ] Admin dashboard accessible
- [ ] Can create students
- [ ] Can create exams
- [ ] Can upload questions
- [ ] Can view reports
- [ ] File uploads work
- [ ] Image uploads work

### Student Functions
- [ ] Student can log in
- [ ] Student dashboard loads
- [ ] Can view available exams
- [ ] Can attempt exam
- [ ] Timer works correctly
- [ ] Can submit answers
- [ ] Can view results (if enabled)

### Exam Features
- [ ] Question shuffling works
- [ ] Camera access works (proctoring)
- [ ] Video recording works
- [ ] Answer auto-save works
- [ ] Violation detection works
- [ ] Exam completion/submission works
- [ ] Score calculation accurate

### WebSocket/Real-time Features
- [ ] Socket.IO connection established
- [ ] Real-time updates working
- [ ] No connection timeouts
- [ ] Reconnection works after disconnect

---

## 📊 PHASE 12: MONITORING & LOGS (10 minutes)

### Log Files
- [ ] Application logs exist and updating
- [ ] Nginx access logs exist and updating
- [ ] Nginx error logs exist (empty is good)
- [ ] MySQL error logs exist (empty is good)
- [ ] No critical errors in any logs
- [ ] Log rotation configured

**Verification Commands:**
```bash
# Check all log files
ls -lh /var/log/cognitiopro/
ls -lh /var/log/nginx/
ls -lh /var/log/mysql/

# View recent entries
tail -20 /var/log/cognitiopro/gunicorn.out.log
tail -20 /var/log/nginx/access.log
tail -20 /var/log/nginx/error.log
```

### System Resources
- [ ] CPU usage normal (<50% average)
- [ ] Memory usage acceptable (<80%)
- [ ] Disk space sufficient (>20% free)
- [ ] No swap thrashing
- [ ] Database performance acceptable

**Verification Commands:**
```bash
# System resources
htop  # Interactive view
top   # Alternative

# Disk space
df -h

# Memory
free -h

# Database connections
mysql -u root -p -e "SHOW PROCESSLIST;"
```

---

## 🔄 PHASE 13: BACKUP & RECOVERY (10 minutes)

### Backup System
- [ ] Database backup script created
- [ ] Backup cron job configured
- [ ] Backup directory exists
- [ ] Test backup created successfully
- [ ] Can restore from backup
- [ ] Old backups automatically cleaned

**Verification Commands:**
```bash
# Run backup manually
/var/www/cognitiopro/backup.sh

# Check backup files
ls -lh /var/backups/cognitiopro/

# Test restore (use test database)
mysql -u root -p test_restore < /var/backups/cognitiopro/latest_backup.sql
```

### Backup Locations
- [ ] Database backups stored
- [ ] Application files backed up (optional)
- [ ] Upload files backed up (optional)
- [ ] Configuration files backed up
- [ ] Off-site backup configured (recommended)

---

## 🔐 PHASE 14: SECURITY AUDIT (15 minutes)

### Security Best Practices
- [ ] No default passwords used
- [ ] Strong passwords enforced
- [ ] .env file secured (600 permissions)
- [ ] No sensitive data in logs
- [ ] Debug mode disabled
- [ ] SQL injection protection active
- [ ] XSS protection active
- [ ] CSRF protection active
- [ ] Rate limiting active
- [ ] Input validation active

### Security Testing
- [ ] Test SQL injection on login (should fail)
- [ ] Test XSS in forms (should be sanitized)
- [ ] Test excessive login attempts (should be blocked)
- [ ] Test large file upload (should respect 50MB limit)
- [ ] Test access without authentication (should redirect)
- [ ] Test privilege escalation (student accessing admin)

### External Security Scan
- [ ] SSL Labs test: A or higher grade
- [ ] Security Headers test: A grade
- [ ] Port scan shows only 22, 80, 443 open
- [ ] No known vulnerabilities detected

**External Tools:**
- SSL Test: https://www.ssllabs.com/ssltest/
- Security Headers: https://securityheaders.com/
- Port Scan: `nmap YOUR_SERVER_IP`

---

## 📈 PHASE 15: PERFORMANCE (10 minutes)

### Load Testing
- [ ] Application handles concurrent users
- [ ] Response time acceptable (<2s for pages)
- [ ] Database queries optimized
- [ ] No memory leaks during load test
- [ ] WebSocket connections stable under load

### Optimization
- [ ] Static files served with caching headers
- [ ] Gzip/Brotli compression enabled
- [ ] Database indexes created
- [ ] Image optimization enabled
- [ ] CDN configured (if using)

**Testing Commands:**
```bash
# Simple load test
ab -n 1000 -c 10 https://YOUR_DOMAIN/

# Monitor during test
htop
```

---

## ✅ FINAL CHECKLIST

### Critical Items (Must Have)
- [ ] Application accessible via HTTPS
- [ ] No SSL warnings
- [ ] Login system works
- [ ] Database connected and working
- [ ] All services start on boot
- [ ] Firewall active and configured
- [ ] Backups configured
- [ ] Logs accessible

### Recommended Items (Should Have)
- [ ] Cloudflare configured
- [ ] Monitoring system active
- [ ] Error alerting configured
- [ ] Documentation updated
- [ ] Admin users created
- [ ] Test data imported
- [ ] Performance optimized

### Optional Items (Nice to Have)
- [ ] Uptime monitoring (UptimeRobot, etc.)
- [ ] Log aggregation (ELK stack, etc.)
- [ ] Application Performance Monitoring (APM)
- [ ] Content Delivery Network (CDN)
- [ ] Load balancer (if multiple servers)

---

## 🚨 COMMON ISSUES & SOLUTIONS

### Application Won't Start
```bash
# Check logs
tail -50 /var/log/cognitiopro/gunicorn.err.log

# Check permissions
ls -la /var/www/cognitiopro

# Restart
supervisorctl restart cognitiopro
```

### Database Connection Failed
```bash
# Test connection
mysql -u lms_user -p lms_system

# Check credentials in .env
sudo -u cognitiopro cat /var/www/cognitiopro/.env | grep DB_

# Check MySQL is running
systemctl status mysql
```

### 502 Bad Gateway
```bash
# Check if app is running
supervisorctl status cognitiopro

# Check socket
ls -l /var/www/cognitiopro/cognitiopro.sock

# Check Nginx error log
tail -50 /var/log/nginx/error.log
```

### SSL Certificate Issues
```bash
# Renew certificate
certbot renew --force-renewal

# Check certificate
certbot certificates

# Restart Nginx
systemctl restart nginx
```

---

## 📞 DEPLOYMENT COMPLETED

If all items are checked, congratulations! Your Cognitio Pro LMS is successfully deployed and secured.

### Final Steps:
1. Document any custom configurations
2. Share access credentials securely with admin team
3. Schedule regular maintenance windows
4. Set up monitoring and alerting
5. Create runbooks for common operations

### Maintenance Schedule:
- **Daily**: Check logs, monitor resources
- **Weekly**: Review security logs, check backups
- **Monthly**: Update system packages, review access logs
- **Quarterly**: Security audit, performance review

---

**Checklist Version**: 1.0  
**Last Updated**: February 2026  
**Deployment Date**: _____________  
**Verified By**: _____________  
**Server IP**: _____________  
**Domain**: _____________
