#!/bin/bash

# 客服聊天系统一键安装脚本
# 版本: 1.0.1
# 此脚本自动安装所有必需的依赖项并配置系统

set -e

# 颜色代码
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 显示彩色消息
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查root权限
if [ "$(id -u)" -ne 0 ]; then
    log_error "请使用root权限运行此脚本 (sudo ./one-click-install.sh)"
    exit 1
fi

# 显示欢迎信息
echo "=================================================="
echo "      客服聊天系统 - 一键自动安装脚本"
echo "=================================================="
echo ""
echo "此脚本将自动执行以下操作:"
echo " - 安装必要的系统依赖"
echo " - 配置Nginx及SSL证书"
echo " - 安装和配置PostgreSQL和Redis"
echo " - 部署客服聊天系统"
echo " - 设置系统服务和自启动"
echo ""
echo "=================================================="

# 确认安装
if [ -z "$CONFIRM_INSTALL" ]; then
    # 检查是否为交互式终端
    if [ -t 0 ]; then
        read -p "是否开始安装? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "安装已取消"
            exit 0
        fi
    else
        # 管道模式，自动确认
        log_info "通过管道运行，自动确认安装"
    fi
fi

# 安装系统依赖
install_dependencies() {
    log_info "正在更新系统软件包列表..."
    apt-get update

    log_info "正在安装系统依赖..."
    apt-get install -y curl wget git build-essential nginx certbot python3-certbot-nginx \
                       postgresql postgresql-contrib redis-server ssl-cert

    if [ $? -ne 0 ]; then
        log_error "安装系统依赖失败"
        exit 1
    fi
    
    log_success "系统依赖安装完成"
}

# 安装SSL证书
setup_ssl() {
    log_info "设置SSL证书..."
    
    # 获取当前主机名作为默认域名
    default_domain=$(hostname -f)
    
    # 询问域名
    if [ -z "$CONFIRM_INSTALL" ]; then
        read -p "请输入您的域名 (默认: $default_domain): " domain
        domain=${domain:-$default_domain}
    else
        # 自动模式下使用默认域名
        domain=$default_domain
        log_info "使用默认域名: $domain"
    fi
    
    log_info "为域名 $domain 设置SSL证书"
    
    # 检查是否为公网环境
    if ping -c 1 google.com &> /dev/null || ping -c 1 baidu.com &> /dev/null; then
        log_info "检测到公网环境，尝试使用Let's Encrypt获取证书..."
        
        # 备份原有Nginx配置
        cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
        
        # 使用certbot获取证书
        certbot --nginx -n --agree-tos --email admin@$domain --domains "$domain" --redirect
        
        if [ $? -eq 0 ]; then
            log_success "SSL证书安装成功"
        else
            log_warning "SSL证书安装失败，使用自签名证书..."
            # 创建自签名证书
            mkdir -p /etc/nginx/ssl
            openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout /etc/nginx/ssl/$domain.key \
                -out /etc/nginx/ssl/$domain.crt \
                -subj "/CN=$domain"
            
            log_success "自签名SSL证书创建成功"
        fi
    else
        log_info "未检测到公网环境，使用自签名证书..."
        # 创建自签名证书
        mkdir -p /etc/nginx/ssl
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/nginx/ssl/$domain.key \
            -out /etc/nginx/ssl/$domain.crt \
            -subj "/CN=$domain"
        
        log_success "自签名SSL证书创建成功"
    fi
}

# 配置PostgreSQL
setup_database() {
    log_info "配置PostgreSQL数据库..."
    
    # 确保PostgreSQL服务正在运行
    systemctl start postgresql
    systemctl enable postgresql
    
    # 创建数据库用户和数据库
    su - postgres -c "createuser --createdb customer_service" || true
    su - postgres -c "createdb -O customer_service customer_service_db" || true
    
    # 设置随机密码
    PGPASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)
    su - postgres -c "psql -c \"ALTER USER customer_service WITH PASSWORD '$PGPASSWORD';\""
    
    log_success "数据库配置完成"
    log_info "数据库连接信息:"
    log_info "  - 数据库: customer_service_db"
    log_info "  - 用户: customer_service"
    log_info "  - 密码: $PGPASSWORD"
    
    # 保存数据库信息到配置文件
    db_connection_string="postgres://customer_service:$PGPASSWORD@localhost/customer_service_db"
}

# 配置Redis
setup_redis() {
    log_info "配置Redis服务..."
    
    # 确保Redis服务正在运行
    systemctl start redis-server
    systemctl enable redis-server
    
    # 简单配置 - 保持默认配置
    log_success "Redis配置完成"
}

# 下载和安装客服聊天系统
install_chat_system() {
    # 安装目标目录
    INSTALL_DIR="/opt/customer-service-chat"
    CONFIG_DIR="$INSTALL_DIR/config"
    
    log_info "创建安装目录..."
    mkdir -p $INSTALL_DIR
    mkdir -p $CONFIG_DIR
    
    log_info "下载客服聊天系统..."
    
    # 从GitHub下载最新版本
    TMP_DIR=$(mktemp -d)
    cd $TMP_DIR
    
    wget -q https://github.com/Gaoce8888/rust-customer-service-chat/archive/main.tar.gz -O chat-system.tar.gz
    tar -xzf chat-system.tar.gz
    cp -r rust-customer-service-chat-main/* $INSTALL_DIR/
    
    # 配置系统
    log_info "配置系统..."
    
    # 生成JWT密钥
    JWT_SECRET=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 32)
    
    # 创建配置文件
    cat > $CONFIG_DIR/config.json <<EOF
{
    "api_domain": "api.$domain",
    "admin_domain": "admin.$domain",
    "client_domain": "$domain",
    "db_connection": "$db_connection_string",
    "redis_host": "localhost",
    "redis_port": 6379,
    "server_port": 3000,
    "jwt_secret": "$JWT_SECRET",
    "admin_username": "admin",
    "admin_password": "admin123"
}
EOF
    
    # 设置权限
    chown -R www-data:www-data $INSTALL_DIR
    chmod -R 755 $INSTALL_DIR
    chmod +x $INSTALL_DIR/scripts/*.sh
    
    log_success "客服聊天系统安装完成"
}

# 配置Nginx
setup_nginx() {
    log_info "配置Nginx..."
    
    # 创建Nginx配置
    cat > /etc/nginx/sites-available/$domain.conf <<EOF
# 客户端网站配置
server {
    listen 80;
    listen [::]:80;
    server_name $domain www.$domain;
    
    # SSL配置
    listen 443 ssl;
    ssl_certificate /etc/nginx/ssl/$domain.crt;
    ssl_certificate_key /etc/nginx/ssl/$domain.key;
    
    # SSL参数
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
    ssl_session_cache shared:SSL:10m;
    
    # HTTP重定向至HTTPS
    if (\$scheme = http) {
        return 301 https://\$host\$request_uri;
    }
    
    # 网站根目录
    root /opt/customer-service-chat/public;
    index index.html;
    
    # API代理
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Swagger UI
    location /swagger-ui {
        alias /opt/customer-service-chat/public/swagger-ui;
        try_files \$uri \$uri/ =404;
    }
    
    # 静态文件
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}

# API域名配置
server {
    listen 80;
    listen [::]:80;
    server_name api.$domain;
    
    # SSL配置
    listen 443 ssl;
    ssl_certificate /etc/nginx/ssl/$domain.crt;
    ssl_certificate_key /etc/nginx/ssl/$domain.key;
    
    # SSL参数
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
    ssl_session_cache shared:SSL:10m;
    
    # HTTP重定向至HTTPS
    if (\$scheme = http) {
        return 301 https://\$host\$request_uri;
    }
    
    # API代理
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# 管理员域名配置
server {
    listen 80;
    listen [::]:80;
    server_name admin.$domain;
    
    # SSL配置
    listen 443 ssl;
    ssl_certificate /etc/nginx/ssl/$domain.crt;
    ssl_certificate_key /etc/nginx/ssl/$domain.key;
    
    # SSL参数
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
    ssl_session_cache shared:SSL:10m;
    
    # HTTP重定向至HTTPS
    if (\$scheme = http) {
        return 301 https://\$host\$request_uri;
    }
    
    # 管理面板根目录
    root /opt/customer-service-chat/admin;
    index index.html;
    
    # API代理
    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # 静态文件
    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
    
    # 启用站点配置
    ln -sf /etc/nginx/sites-available/$domain.conf /etc/nginx/sites-enabled/
    
    # 移除默认站点
    rm -f /etc/nginx/sites-enabled/default
    
    # 测试Nginx配置
    nginx -t
    
    # 重启Nginx
    systemctl restart nginx
    
    log_success "Nginx配置完成"
}

# 创建系统服务
create_service() {
    log_info "创建系统服务..."
    
    cat > /etc/systemd/system/customer-service-chat.service <<EOF
[Unit]
Description=Customer Service Chat System
After=network.target postgresql.service redis-server.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/customer-service-chat
ExecStart=/opt/customer-service-chat/bin/customer-service-chat
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd配置
    systemctl daemon-reload
    
    # 启用并启动服务
    systemctl enable customer-service-chat
    systemctl start customer-service-chat
    
    log_success "系统服务配置完成并已启动"
}

# 执行安装流程
log_info "开始安装客服聊天系统..."

# 执行各个安装步骤
install_dependencies
setup_ssl
setup_database
setup_redis
install_chat_system
setup_nginx
create_service

log_success "====================================================="
log_success "      客服聊天系统安装成功!"
log_success "====================================================="
log_success "您可以通过以下URL访问系统:"
log_success "  - 客户端: https://$domain"
log_success "  - 管理端: https://admin.$domain"
log_success "  - API接口: https://api.$domain"
log_success ""
log_success "管理员账户:"
log_success "  - 用户名: admin"
log_success "  - 密码: admin123"
log_success ""
log_success "请确保尽快更改默认管理员密码!"
log_success "====================================================="

exit 0