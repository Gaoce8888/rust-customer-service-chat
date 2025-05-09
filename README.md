# 客服聊天系统 (Rust)

一个高性能、可扩展的客服聊天系统，采用Rust语言开发，支持多客服协作、会话转接和智能路由。

## 系统特点

- 🚀 **高性能**：基于Rust和WebSocket开发，支持高并发连接
- 🔐 **安全可靠**：JWT认证和HTTPS加密
- 🌐 **多域名支持**：API端点、管理端和客户端可配置不同域名
- 📱 **移动端适配**：响应式设计，支持各种设备访问
- 🔌 **易于集成**：提供RESTful API和WebSocket连接
- 🧩 **可扩展**：模块化架构，支持自定义插件

## 快速开始

### 安装方法

#### 方法1：一键安装（推荐）

```bash
wget https://dl.ylqkf.com/releases/customer-service-chat-installer-v2.1.tar.gz
tar -xzf customer-service-chat-installer-v2.1.tar.gz
sudo ./one-click-install.sh
```

#### 方法2：在线安装

```bash
curl -fsSL https://raw.githubusercontent.com/Gaoce8888/rust-customer-service-chat/main/install-package/online-install.sh | sudo bash
```

#### 方法3：手动安装

1. 克隆本仓库
   ```bash
   git clone https://github.com/Gaoce8888/rust-customer-service-chat.git
   cd rust-customer-service-chat
   ```

2. 编译项目
   ```bash
   cargo build --release
   ```

3. 配置环境
   ```bash
   cp config.toml.example config.toml
   # 编辑config.toml进行自定义配置
   ```

4. 运行服务
   ```bash
   ./target/release/customer-service-chat
   ```

## API文档

系统集成了Swagger UI，安装后可通过以下地址访问API文档：

```
https://api.您的域名/swagger.html
```

或者在本地开发环境中：

```
http://localhost:8080/swagger.html
```

### Swagger UI修复说明

如果您发现Swagger UI无法正常加载API文档，通常是由于路径配置问题。系统已经自动添加了固定路径`/fixed-openapi.json`来解决这个问题。主要的修复点在：

1. `src/api/api_docs.rs`中添加了专用路由
   ```rust
   .route("/fixed-openapi.json", get(serve_openapi_json))
   ```

2. `public/swagger.html`中引用了固定路径
   ```javascript
   url: "/fixed-openapi.json"
   ```

## 系统架构

### 前端部分

- 客户端：HTML5 + CSS3 + JavaScript（可选React或Vue）
- 管理端：基于React开发的单页应用，支持权限控制

### 后端部分

- 语言：Rust
- Web框架：Axum
- 数据库：PostgreSQL
- 缓存：Redis
- WebSocket：处理实时通讯

### 主要模块

- 用户认证模块
- 消息处理模块
- 会话管理模块
- 客服分配模块
- 统计报表模块

## Nginx配置

系统提供了完整的Nginx配置工具，可以通过以下命令进行配置：

```bash
# 检查并修复Nginx配置
sudo /opt/customer-service-chat/scripts/nginx-utils.sh check

# 添加SSL证书
sudo /opt/customer-service-chat/scripts/nginx-utils.sh install-ssl yourdomain.com

# 添加反向代理
sudo /opt/customer-service-chat/scripts/nginx-utils.sh add-proxy yourdomain.com /api http://localhost:8080
```

## 开发指南

### 目录结构

```
/
├── src/                # 源代码目录
│   ├── api/            # API定义和处理
│   ├── db/             # 数据库模型和操作
│   ├── middleware/     # 中间件（认证、日志等）
│   ├── models/         # 数据模型定义
│   ├── services/       # 业务逻辑服务
│   ├── bin/            # 可执行文件
│   └── lib.rs          # 库入口
├── public/             # 静态资源目录
│   └── swagger-ui/     # Swagger UI文件
├── install-package/    # 安装包和脚本
├── config.toml         # 配置文件
└── Cargo.toml          # Rust包管理配置
```

### API开发

1. 在`src/api/handlers.rs`中添加新的处理函数
2. 在`src/api/api_docs.rs`中的OpenAPI定义中注册API
3. 在`src/api/mod.rs`中添加路由

## 许可证

本项目采用MIT许可证。

## 贡献指南

欢迎提交Pull Request或Issue。

## 联系方式

如有问题，请通过以下方式联系我们：

- 邮箱：support@ylqkf.com
- GitHub Issues: https://github.com/Gaoce8888/rust-customer-service-chat/issues