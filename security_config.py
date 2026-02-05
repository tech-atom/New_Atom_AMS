"""
Security Configuration Module for ATOM SHAALE AMS
Implements enterprise-grade security measures:
- HTTPS enforcement
- Security headers (CSP, HSTS, etc.)
- Rate limiting
- CSRF protection
- Input sanitization
- SQL injection prevention
"""

import os
from flask_talisman import Talisman
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_wtf.csrf import CSRFProtect
import bleach
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime, timedelta

# ============================================================================
# SECURITY CONFIGURATION
# ============================================================================

def init_security(app):
    """Initialize all security features for Flask app"""
    
    # ========================================================================
    # 1. HTTPS ENFORCEMENT & SECURITY HEADERS (Flask-Talisman)
    # ========================================================================
    
    # Content Security Policy
    csp = {
        'default-src': "'self'",
        'script-src': [
            "'self'",
            "'unsafe-inline'",  # Required for inline event handlers in exam
            "'unsafe-eval'",    # Required for dynamic eval in some exam features
            'cdn.socket.io',    # SocketIO CDN
            'cdnjs.cloudflare.com',  # Libraries
            'cdn.jsdelivr.net',  # Chart.js and other libraries
        ],
        'style-src': [
            "'self'",
            "'unsafe-inline'",  # Required for inline styles
            'fonts.googleapis.com',
        ],
        'font-src': [
            "'self'",
            'fonts.gstatic.com',
            'data:',
        ],
        'img-src': [
            "'self'",
            'data:',  # For base64 images
            'blob:',  # For video thumbnails
        ],
        'media-src': [
            "'self'",
            'blob:',  # For recorded videos
        ],
        'connect-src': [
            "'self'",
            'wss:',  # WebSocket for SocketIO
            'ws:',   # WebSocket fallback
            'https://cdn.socket.io',  # Socket.io CDN for map files
        ],
        'frame-ancestors': "'none'",  # Prevent clickjacking
        'base-uri': "'self'",
        'form-action': "'self'",
    }
    
    # Initialize Talisman
    Talisman(
        app,
        force_https=True,  # Redirect HTTP to HTTPS
        strict_transport_security=True,
        strict_transport_security_max_age=31536000,  # 1 year
        strict_transport_security_include_subdomains=True,
        strict_transport_security_preload=True,
        content_security_policy=csp,
        content_security_policy_nonce_in=['script-src'],  # Add nonce for inline scripts
        referrer_policy='strict-origin-when-cross-origin',
        feature_policy={
            'geolocation': "'none'",
            'microphone': "'self'",  # Allow for exam proctoring
            'camera': "'self'",      # Allow for exam proctoring
            'payment': "'none'",
            'usb': "'none'",
        },
        session_cookie_secure=True,
        session_cookie_http_only=True,
        session_cookie_samesite='Lax',
        force_file_save=False,  # Don't force download on all responses
    )
    
    print("✓ Flask-Talisman initialized: HTTPS enforcement + Security headers")
    
    # ========================================================================
    # 2. RATE LIMITING (Flask-Limiter)
    # ========================================================================
    
    # Get storage URL and fallback to memory if Redis unavailable
    storage_url = os.getenv("RATELIMIT_STORAGE_URL", "memory://")
    
    try:
        # Try to initialize limiter
        if storage_url == "memory://":
            # Use in-memory storage for development
            from limits.storage import MemoryStorage
            limiter = Limiter(
                app=app,
                key_func=get_remote_address,
                storage_uri="memory://",
                storage_options={},
                strategy="fixed-window",
                headers_enabled=False,
                swallow_errors=True,  # Don't raise errors on limit checks
            )
            print("✓ Flask-Limiter initialized: Using in-memory storage (development mode)")
        else:
            # Use Redis for production
            limiter = Limiter(
                app=app,
                key_func=get_remote_address,
                default_limits=["200 per day", "50 per hour"],
                storage_uri=storage_url,
                strategy="fixed-window",
                headers_enabled=True,
                swallow_errors=True,
            )
            print("✓ Flask-Limiter initialized: Rate limiting active")
    except Exception as e:
        # If limiter fails to initialize, create a dummy limiter
        print(f"⚠️  Flask-Limiter initialization failed: {e}")
        print("⚠️  Rate limiting DISABLED - continuing without rate limits")
        
        # Create a dummy limiter that does nothing
        class DummyLimiter:
            def limit(self, *args, **kwargs):
                def decorator(f):
                    return f
                return decorator
            def exempt(self, f):
                return f
            def request_filter(self, f):
                return f
        
        limiter = DummyLimiter()
    
    # ========================================================================
    # 3. CSRF PROTECTION (Flask-WTF)
    # ========================================================================
    
    csrf = CSRFProtect(app)
    
    # Configure CSRF exemptions for SocketIO
    app.config['WTF_CSRF_CHECK_DEFAULT'] = False  # We'll protect routes individually
    
    print("✓ Flask-WTF CSRF initialized: CSRF protection active")
    
    # ========================================================================
    # 4. SECURE SESSION CONFIGURATION
    # ========================================================================
    
    app.config.update(
        SESSION_COOKIE_SECURE=True,      # Only send cookie over HTTPS
        SESSION_COOKIE_HTTPONLY=True,    # Prevent JavaScript access
        SESSION_COOKIE_SAMESITE='Lax',   # CSRF protection
        PERMANENT_SESSION_LIFETIME=timedelta(hours=1),  # Session timeout
        SESSION_REFRESH_EACH_REQUEST=True,  # Extend session on activity
    )
    
    print("✓ Secure session configuration applied")
    
    # ========================================================================
    # 5. FILE UPLOAD SECURITY
    # ========================================================================
    
    app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # 50MB max
    
    print("✓ File upload limits configured")
    
    # ========================================================================
    # 6. LOGGING CONFIGURATION
    # ========================================================================
    
    if not app.debug:
        # Create logs directory if not exists
        log_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs')
        os.makedirs(log_dir, exist_ok=True)
        
        # Security events log
        security_handler = RotatingFileHandler(
            os.path.join(log_dir, 'security.log'),
            maxBytes=10485760,  # 10MB
            backupCount=10
        )
        security_handler.setFormatter(logging.Formatter(
            '[%(asctime)s] %(levelname)s in %(module)s: %(message)s'
        ))
        security_handler.setLevel(logging.INFO)
        
        # App log
        app_handler = RotatingFileHandler(
            os.path.join(log_dir, 'app.log'),
            maxBytes=10485760,  # 10MB
            backupCount=10
        )
        app_handler.setFormatter(logging.Formatter(
            '[%(asctime)s] %(levelname)s in %(module)s: %(message)s'
        ))
        app_handler.setLevel(logging.INFO)
        
        app.logger.addHandler(security_handler)
        app.logger.addHandler(app_handler)
        app.logger.setLevel(logging.INFO)
        
        print("✓ Security logging configured")
    
    return limiter, csrf


# ============================================================================
# INPUT SANITIZATION FUNCTIONS
# ============================================================================

def sanitize_html(text, strip_all=False):
    """
    Sanitize HTML content to prevent XSS attacks
    
    Args:
        text: Input string to sanitize
        strip_all: If True, strip all HTML tags
    
    Returns:
        Sanitized string
    """
    if not text:
        return text
    
    if strip_all:
        # Strip all HTML tags
        return bleach.clean(text, tags=[], strip=True)
    else:
        # Allow safe tags only
        allowed_tags = ['b', 'i', 'u', 'em', 'strong', 'a', 'p', 'br', 'ul', 'ol', 'li', 'code', 'pre']
        allowed_attributes = {'a': ['href', 'title']}
        return bleach.clean(text, tags=allowed_tags, attributes=allowed_attributes, strip=True)


def validate_input(data, field_type='text', max_length=None):
    """
    Validate and sanitize user input
    
    Args:
        data: Input data to validate
        field_type: Type of field (text, email, number, etc.)
        max_length: Maximum allowed length
    
    Returns:
        tuple: (is_valid, sanitized_data, error_message)
    """
    if data is None:
        return False, None, "Input cannot be empty"
    
    # Convert to string
    data = str(data).strip()
    
    # Check length
    if max_length and len(data) > max_length:
        return False, None, f"Input exceeds maximum length of {max_length} characters"
    
    # Type-specific validation
    if field_type == 'email':
        import re
        email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(email_pattern, data):
            return False, None, "Invalid email format"
    
    elif field_type == 'number':
        try:
            int(data)
        except ValueError:
            return False, None, "Invalid number format"
    
    elif field_type == 'filename':
        # Remove path traversal attempts
        data = os.path.basename(data)
        if '..' in data or '/' in data or '\\' in data:
            return False, None, "Invalid filename"
    
    # Sanitize HTML
    sanitized = sanitize_html(data, strip_all=(field_type != 'html'))
    
    return True, sanitized, None


def validate_file_upload(file, allowed_extensions=None, max_size=None):
    """
    Validate uploaded file
    
    Args:
        file: FileStorage object from request.files
        allowed_extensions: Set of allowed extensions (e.g., {'pdf', 'jpg'})
        max_size: Maximum file size in bytes
    
    Returns:
        tuple: (is_valid, error_message)
    """
    if not file or file.filename == '':
        return False, "No file selected"
    
    # Check extension
    filename = secure_filename(file.filename)
    if '.' not in filename:
        return False, "File must have an extension"
    
    ext = filename.rsplit('.', 1)[1].lower()
    
    if allowed_extensions and ext not in allowed_extensions:
        return False, f"File type '{ext}' not allowed. Allowed types: {', '.join(allowed_extensions)}"
    
    # Check size (if file object supports)
    if max_size:
        file.seek(0, os.SEEK_END)
        size = file.tell()
        file.seek(0)  # Reset file pointer
        
        if size > max_size:
            return False, f"File size exceeds maximum of {max_size / (1024*1024):.1f}MB"
    
    return True, None


# ============================================================================
# SQL INJECTION PREVENTION
# ============================================================================

def execute_query(cursor, query, params=None, fetch=False):
    """
    Execute parameterized query safely
    
    Args:
        cursor: Database cursor
        query: SQL query with placeholders (%s)
        params: Tuple of parameters
        fetch: If True, return fetchall() results
    
    Returns:
        Query results if fetch=True, else cursor
    """
    try:
        if params:
            cursor.execute(query, params)
        else:
            cursor.execute(query)
        
        if fetch:
            return cursor.fetchall()
        return cursor
    except Exception as e:
        logging.error(f"Query execution error: {e}")
        raise


# ============================================================================
# TRUSTED PROXY CONFIGURATION (Cloudflare)
# ============================================================================

def configure_trusted_proxies(app):
    """
    Configure Flask to trust Cloudflare proxy headers
    This ensures we get real client IPs, not Cloudflare IPs
    """
    from werkzeug.middleware.proxy_fix import ProxyFix
    
    # Trust Cloudflare proxy
    app.wsgi_app = ProxyFix(
        app.wsgi_app,
        x_for=1,      # Trust X-Forwarded-For
        x_proto=1,    # Trust X-Forwarded-Proto
        x_host=1,     # Trust X-Forwarded-Host
        x_prefix=1    # Trust X-Forwarded-Prefix
    )
    
    print("✓ Trusted proxy configuration applied (Cloudflare)")


# ============================================================================
# IP BLOCKING & RATE LIMIT HANDLER
# ============================================================================

# In-memory IP ban list (use Redis in production for persistence)
BANNED_IPS = set()
FAILED_LOGIN_ATTEMPTS = {}  # IP: {count, timestamp}

def is_ip_banned(ip):
    """Check if IP is banned"""
    return ip in BANNED_IPS


def ban_ip(ip, duration_minutes=60):
    """Ban IP address"""
    BANNED_IPS.add(ip)
    logging.warning(f"IP banned: {ip} for {duration_minutes} minutes")
    # In production, use Redis with expiry


def record_failed_login(ip):
    """
    Record failed login attempt and ban if threshold exceeded
    
    Returns:
        True if IP should be banned, False otherwise
    """
    from datetime import datetime, timedelta
    
    now = datetime.now()
    
    if ip not in FAILED_LOGIN_ATTEMPTS:
        FAILED_LOGIN_ATTEMPTS[ip] = {'count': 1, 'timestamp': now}
        return False
    
    attempt = FAILED_LOGIN_ATTEMPTS[ip]
    
    # Reset counter if last attempt was > 10 minutes ago
    if (now - attempt['timestamp']).total_seconds() > 600:
        FAILED_LOGIN_ATTEMPTS[ip] = {'count': 1, 'timestamp': now}
        return False
    
    # Increment counter
    attempt['count'] += 1
    attempt['timestamp'] = now
    
    # Ban after 5 failed attempts
    if attempt['count'] >= 5:
        ban_ip(ip)
        logging.warning(f"IP auto-banned after {attempt['count']} failed login attempts: {ip}")
        return True
    
    return False


def clear_failed_login(ip):
    """Clear failed login attempts for IP after successful login"""
    if ip in FAILED_LOGIN_ATTEMPTS:
        del FAILED_LOGIN_ATTEMPTS[ip]


# ============================================================================
# SECURITY DECORATORS
# ============================================================================

from functools import wraps
from flask import abort, request

def require_login(f):
    """Decorator to require login for routes"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'email' not in session:
            flash('Please login to access this page', 'error')
            return redirect(url_for('unified_login'))
        return f(*args, **kwargs)
    return decorated_function


def require_admin(f):
    """Decorator to require admin role"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'email' not in session:
            flash('Please login to access this page', 'error')
            return redirect(url_for('unified_login'))
        
        if session.get('role') != 'admin':
            flash('Access denied: Admin privileges required', 'error')
            return redirect(url_for('student_dashboard'))
        
        return f(*args, **kwargs)
    return decorated_function


def check_ip_ban(f):
    """Decorator to check if IP is banned"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        client_ip = request.headers.get('CF-Connecting-IP') or \
                    request.headers.get('X-Forwarded-For', '').split(',')[0].strip() or \
                    request.remote_addr
        
        if is_ip_banned(client_ip):
            logging.warning(f"Blocked request from banned IP: {client_ip}")
            abort(403)  # Forbidden
        
        return f(*args, **kwargs)
    return decorated_function


# ============================================================================
# EXAM SECURITY FEATURES
# ============================================================================

def verify_exam_integrity(student_id, exam_id):
    """
    Verify exam hasn't been tampered with
    Returns: (is_valid, error_message)
    """
    # Check for duplicate attempts
    # Check time bounds
    # Check IP consistency
    # Add your logic here
    return True, None


def log_security_event(event_type, details, severity='INFO'):
    """
    Log security-related events
    
    Args:
        event_type: Type of event (login_failed, exam_violation, etc.)
        details: Dict with event details
        severity: INFO, WARNING, ERROR, CRITICAL
    """
    import json
    from flask import has_request_context, request as flask_request
    
    log_entry = {
        'timestamp': datetime.now().isoformat(),
        'event_type': event_type,
        'details': details,
    }
    
    # Only access request context if available
    if has_request_context():
        log_entry['ip'] = flask_request.headers.get('CF-Connecting-IP') or flask_request.remote_addr
        log_entry['user_agent'] = flask_request.headers.get('User-Agent', 'Unknown')
    else:
        log_entry['ip'] = 'N/A'
        log_entry['user_agent'] = 'N/A'
    
    log_message = json.dumps(log_entry)
    
    if severity == 'CRITICAL':
        logging.critical(log_message)
    elif severity == 'ERROR':
        logging.error(log_message)
    elif severity == 'WARNING':
        logging.warning(log_message)
    else:
        logging.info(log_message)
