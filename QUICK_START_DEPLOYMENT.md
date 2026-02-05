# 🚀 QUICK START - Cognitio Pro LMS Deployment

**Deploy your LMS in 30 minutes with this streamlined guide.**

---

## 📋 Prerequisites Quick Check

```bash
# Server: Ubuntu 20.04+ with 2GB+ RAM
# Access: Root SSH access
# Domain: DNS access to configure A records
# Local: Windows with PowerShell or Linux/Mac terminal
```

---

## ⚡ Fast Track Deployment (3 Steps)

### Step 1: Upload Files to Server (5 min)

**On your Windows machine:**
```powershell
# Option A: Using SCP (if OpenSSH installed)
cd d:\project1\project
scp -r * root@YOUR_SERVER_IP:/opt/cognitiopro/

# Option B: Use FileZilla/WinSCP
# Connect to: YOUR_SERVER_IP
# Username: root
# Upload all files to: /opt/cognitiopro/
```

### Step 2: Run Deployment Script (20 min)

**On your server via SSH:**
```bash
# Connect
ssh root@YOUR_SERVER_IP

# Run automated deployment
cd /opt/cognitiopro
chmod +x deploy.sh
sudo bash deploy.sh
```

**When prompted, provide:**
- Domain name: `yourdomain.com`
- App user: `cognitiopro`
- MySQL passwords (create strong ones!)
- App directory: `/var/www/cognitiopro`

### Step 3: Configure DNS (5 min)

**At your domain registrar:**
1. Create A record: `@` → `YOUR_SERVER_IP`
2. Create A record: `www` → `YOUR_SERVER_IP`
3. Wait 5-30 minutes for propagation

**Done!** Visit `https://yourdomain.com`

---

## 🔧 What the Script Does

✅ Installs: Python, Nginx, MySQL, Redis, Security tools  
✅ Creates: Database, application user, directories  
✅ Configures: Virtual environment, dependencies  
✅ Secures: Firewall, SSL, security headers, rate limiting  
✅ Deploys: Application server (Gunicorn), web server (Nginx)  
✅ Monitors: Supervisor for auto-restart, log rotation

---

## 📝 Post-Deployment Actions

### 1. Verify Deployment (2 min)
```bash
# Check all services
supervisorctl status cognitiopro    # Should show: RUNNING
systemctl status nginx               # Should show: active
systemctl status mysql               # Should show: active
ufw status                          # Should show: active
```

### 2. Test Application (3 min)
```bash
# Visit in browser
https://yourdomain.com

# Should see login/home page without SSL warnings
```

### 3. Create Admin Account (2 min)
- Access registration page
- Create first admin user
- Verify login works

### 4. Configure Cloudflare (Optional, 10 min)
See [CLOUDFLARE_CONFIG.txt](CLOUDFLARE_CONFIG.txt) for:
- WAF rules
- Rate limiting
- DDoS protection
- Bot management

---

## 🔍 Quick Troubleshooting

### Application Not Starting
```bash
tail -50 /var/log/cognitiopro/gunicorn.err.log
supervisorctl restart cognitiopro
```

### Database Connection Error
```bash
# Test connection
mysql -u lms_user -p lms_system

# Check credentials
cat /var/www/cognitiopro/.env | grep DB_
```

### 502 Bad Gateway
```bash
# Check socket exists
ls -l /var/www/cognitiopro/cognitiopro.sock

# Restart everything
supervisorctl restart cognitiopro
systemctl restart nginx
```

### SSL Not Working
```bash
# Obtain certificate (ensure DNS is configured first!)
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

---

## 📊 Monitoring Commands

```bash
# View live logs
tail -f /var/log/cognitiopro/gunicorn.out.log

# Check system resources
htop

# View recent access
tail -20 /var/log/nginx/access.log

# Restart app
supervisorctl restart cognitiopro
```

---

## 🔐 Security Quick Wins

**Already Configured by Script:**
- ✅ HTTPS with Let's Encrypt
- ✅ Firewall (only 22, 80, 443 open)
- ✅ Rate limiting on login/API
- ✅ SQL injection protection
- ✅ XSS protection
- ✅ CSRF protection
- ✅ Security headers
- ✅ Fail2Ban for brute force protection

**Recommended Next Steps:**
1. Set up Cloudflare (free tier) for DDoS protection
2. Configure backup cron job
3. Set up uptime monitoring
4. Review security logs weekly

---

## 📚 Full Documentation

| Document | Purpose |
|----------|---------|
| [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) | Complete step-by-step guide |
| [POST_DEPLOYMENT_CHECKLIST.md](POST_DEPLOYMENT_CHECKLIST.md) | Verification checklist |
| [CLOUDFLARE_CONFIG.txt](CLOUDFLARE_CONFIG.txt) | Cloudflare WAF rules |
| [ENTERPRISE_SECURITY_GUIDE.md](ENTERPRISE_SECURITY_GUIDE.md) | Security best practices |
| [SECURITY_DEPLOYMENT_CHECKLIST.md](SECURITY_DEPLOYMENT_CHECKLIST.md) | Security verification |

---

## 🆘 Need Help?

**Check logs first:**
```bash
# Application errors
tail -100 /var/log/cognitiopro/gunicorn.err.log

# Web server errors
tail -100 /var/log/nginx/error.log

# System messages
tail -100 /var/log/syslog
```

**Common fixes:**
```bash
# Restart everything
systemctl restart supervisor nginx mysql redis-server

# Reset permissions
cd /var/www/cognitiopro
chown -R cognitiopro:cognitiopro .
chmod 600 .env
chmod -R 770 uploads logs
```

---

## ✅ Success Checklist

- [ ] Files uploaded to server
- [ ] Deployment script completed
- [ ] DNS configured and propagated
- [ ] SSL certificate obtained
- [ ] Application accessible via HTTPS
- [ ] Can log in to application
- [ ] All services running
- [ ] Firewall active
- [ ] Backups configured

---

## 🎓 First-Time Server Deployment?

**No problem!** The automated script handles everything:

1. **System Setup**: Installs all required software
2. **Security**: Configures firewall, SSL, and security measures
3. **Database**: Creates and secures MySQL database
4. **Application**: Deploys and starts your LMS
5. **Web Server**: Configures Nginx with best practices

**Just run the script and answer the prompts!**

---

## 🔄 Updating Your Deployment

```bash
# Connect to server
ssh cognitiopro@YOUR_SERVER_IP

# Navigate to app
cd /var/www/cognitiopro

# Pull new changes (if using git)
git pull

# Or upload new files via SCP/SFTP

# Restart application
supervisorctl restart cognitiopro
```

---

## 💡 Pro Tips

1. **Save credentials securely**: Store your database passwords in a password manager
2. **Enable automatic updates**: Set up unattended-upgrades for security patches
3. **Monitor uptime**: Use UptimeRobot (free) to get alerts if site goes down
4. **Regular backups**: The script creates a backup system - test it monthly
5. **Cloudflare**: Free tier adds significant security and performance benefits

---

## 📞 Support Resources

- **Full Guide**: See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Security**: See [ENTERPRISE_SECURITY_GUIDE.md](ENTERPRISE_SECURITY_GUIDE.md)
- **Verification**: See [POST_DEPLOYMENT_CHECKLIST.md](POST_DEPLOYMENT_CHECKLIST.md)

---

**Ready to deploy?** Start with Step 1 above! 🚀

**Estimated Total Time**: 30-45 minutes  
**Difficulty**: Easy (script does the heavy lifting)  
**Cost**: $5-10/month for basic VPS + $12/year for domain
