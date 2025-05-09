#!/bin/bash

# 客服聊天系统在线一键安装脚本
# 版本: 1.0.3
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

# 在管道中运行时自动确认安装
if [ -t 0 ]; then
    # 如果是交互式终端，询问确认
    read -p "是否开始安装? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
else
    # 如果是通过管道运行，自动确认
    log_info "通过管道运行，自动确认安装"
    CONFIRM_INSTALL=yes
fi

# 安装基本工具
log_info "安装基本工具..."
check_dependency curl
check_dependency wget
check_dependency tar
check_dependency git
check_dependency lsof

# 创建临时目录
TMP_DIR=$(mktemp -d)
log_info "创建临时目录: $TMP_DIR"

# 下载安装包
log_info "正在下载项目..."

# 设置GitHub仓库参数
GITHUB_REPO="https://github.com/Gaoce8888/rust-customer-service-chat.git"
RELEASE_VERSION="v2.1"

cd "$TMP_DIR"

# 使用git克隆项目，确保获取完整代码
log_info "从GitHub克隆项目: $GITHUB_REPO"
git clone --depth=1 "$GITHUB_REPO" repo

if [ ! -d "repo" ]; then
    log_error "克隆GitHub仓库失败，请检查网络连接或仓库地址"
    exit 1
fi

log_success "项目克隆成功"

# 进入项目目录
cd repo

# 检查目录是否包含安装包
if [ ! -f "install-package/one-click-install.sh" ]; then
    log_error "找不到安装脚本，目录结构可能已变更"
    exit 1
fi

# 将安装目录复制到系统路径
log_info "准备安装文件..."
INSTALL_SRC="install-package"

# 添加执行权限
chmod +x "$INSTALL_SRC/one-click-install.sh"

# 进入安装目录
cd "$INSTALL_SRC"

# 设置环境变量来跳过确认
export CONFIRM_INSTALL=yes

# 运行安装脚本
log_info "开始执行安装脚本..."
./one-click-install.sh

# 清理临时文件
log_info "清理临时文件..."
cd - > /dev/null
rm -rf "$TMP_DIR"

log_success "====================================================="
log_success "      客服聊天系统安装成功!"
log_success "====================================================="
log_success "请查看上方输出以获取访问地址和管理员账户信息"
log_success "如果需要帮助，请访问: https://github.com/Gaoce8888/rust-customer-service-chat"
log_success "====================================================="

exit 0