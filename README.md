# 能力重构

一个个人技术记录网站，用来整理现代前端、Java 后端、数据库和部署相关的学习实践。

## 技术栈

- 前端：SvelteKit SSR + Svelte 5 + TypeScript + Vite
- 前端运行时：Node.js 22 + Nginx 反向代理
- 后端：Java 21 + Spring Boot 3 + Spring Web + Spring Data JPA
- 数据库：MySQL 8.4
- 数据库迁移：Flyway
- 测试：Vitest / JUnit 5 + MockMvc

## 架构文档

- [前端架构图](docs/architecture/frontend.md)
- [后端架构图](docs/architecture/backend.md)

## 目录结构

```text
ability-re/
├── frontend/                 # SvelteKit 个人技术站前端
├── backend/                  # Spring Boot API 后端
├── docker-compose.yml        # MySQL 本地数据库
├── README.md
└── .hermes_continuation.md
```

## 数据库方案

优先使用 MySQL，方便你用本地 Navicat 连接查看表和数据。

### 方式一：使用你本机已有 MySQL

在 Navicat 或 MySQL 客户端中创建数据库和用户：

```sql
CREATE DATABASE ability_re DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'ability_re'@'localhost' IDENTIFIED BY '<strong-password>';
GRANT ALL PRIVILEGES ON ability_re.* TO 'ability_re'@'%';
FLUSH PRIVILEGES;
```

Navicat 连接信息：

```text
Host: localhost
Port: 3306
User: ability_re
Password: <strong-password>
Database: ability_re
```

### 方式二：使用 Docker 启动 MySQL

先创建本地环境文件并将两个占位值替换为不同的随机密码：

```bash
cp .env.example .env
chmod 600 .env
```

然后执行：

```bash
docker compose up -d mysql
```

## 启动后端

需要 Java 21 和 Maven：

```bash
cd backend
export DB_PASSWORD='<strong-password>'
mvn spring-boot:run
```

后端启动时 Flyway 会自动执行数据库迁移：

```text
backend/src/main/resources/db/migration/V1__init_schema.sql
backend/src/main/resources/db/migration/V2__personal_site_content.sql
```

并创建：

```text
site_sections
site_features
contact_messages
```

后端接口：

```text
GET  http://localhost:18080/api/health
GET  http://localhost:18080/api/site/home
```

## 启动前端

需要 Node.js 和 pnpm：

```bash
cd frontend
pnpm install
pnpm dev
```

访问：

```text
http://localhost:5173
```

## 测试与构建

```bash
# 后端
cd backend
mvn test

# 前端
cd frontend
pnpm test
pnpm build
```

## 手动部署

Woodpecker 中的前端和后端使用两条独立工作流，推送代码不会自动部署。

在仓库的 Woodpecker 页面点击 `Run pipeline`，选择 `main` 分支，并填写一个变量：

```text
# 只构建并部署后端
COMPONENT=backend

# 只构建并部署前端
COMPONENT=frontend
```

每次只填写其中一个值。后端工作流会运行 Maven 测试并更新后端容器；前端工作流会运行检查、测试和构建，然后更新前端容器。

## 当前功能

- 个人技术记录首页 Hero 区域
- 学习方向卡片展示
- 从后端 API 读取 MySQL 中的官网内容
- 无注册、评论、支付和在线交易功能
- Flyway 初始化数据库表并迁移个人站内容
- 前后端基础测试
