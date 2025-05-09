#!/bin/bash

# 客服聊天系统在线一键安装脚本
# 版本: 1.0.0
# 用法: curl -fsSL https://raw.githubusercontent.com/Gaoce8888/rust-customer-service-chat/main/install-package/online-install.sh | sudo bash

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
    log_error "请使用root权限运行此脚本 (sudo bash)"
    exit 1
fi

# 检查系统依赖
check_dependency() {
    command -v "$1" >/dev/null 2>&1 || {
        log_info "正在安装 $1..."
        apt-get update
        apt-get install -y "$1"
    }
}

# 显示欢迎信息
echo "=================================================="
echo "      客服聊天系统 - 一键安装脚本"
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
    read -p "是否开始安装? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
fi

# 安装基本工具
log_info "安装基本工具..."
check_dependency curl
check_dependency wget
check_dependency tar
check_dependency lsof

# 创建临时目录
TMP_DIR=$(mktemp -d)
log_info "创建临时目录: $TMP_DIR"

# 下载安装包
log_info "正在下载安装包..."

# 设置下载URL，这里使用假设的服务器地址
DOWNLOAD_SERVER="https://dl.ylqkf.com/releases"
INSTALL_PACKAGE="customer-service-chat-installer-v2.1.tar.gz"

cd "$TMP_DIR"
if ! wget -q "${DOWNLOAD_SERVER}/${INSTALL_PACKAGE}"; then
    log_error "无法下载安装包，请检查网络连接"
    exit 1
fi

log_success "安装包下载成功"

# 解压安装包
log_info "正在解压安装包..."
tar -xzf "$INSTALL_PACKAGE"

# 检查解压结果
if [ ! -f "one-click-install.sh" ]; then
    log_error "解压失败或安装包结构不正确"
    exit 1
fi

# 添加执行权限
chmod +x one-click-install.sh

# 设置环境变量来跳过确认
export CONFIRM_INSTALL=yes

# 运行安装脚本
log_info "开始安装系统..."
./one-click-install.sh

# 清理临时文件
log_info "清理临时文件..."
cd - > /dev/null
rm -rf "$TMP_DIR"

log_success "====================================================="
log_success "      客服聊天系统安装成功!"
log_success "====================================================="
log_success "请查看上方输出以获取访问地址和管理员账户信息"
log_success "如果需要帮助，请访问: https://ylqkf.com/docs"
log_success "====================================================="

exit 0