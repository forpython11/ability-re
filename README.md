# Ability Re

一个前后端分离官网项目，用来学习现代前端与主流 Java 后端工程。

## 技术栈

- 前端：SvelteKit + Svelte 5 + TypeScript + Vite
- 后端：Java 21 + Spring Boot 3 + Spring Web + Spring Data JPA
- 数据库：MySQL 8.4
- 数据库迁移：Flyway
- 测试：Vitest / JUnit 5 + MockMvc

## 目录结构

```text
ability-re/
├── frontend/                 # SvelteKit 官网前端
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
CREATE USER 'ability_re'@'%' IDENTIFIED BY 'CHANGE_ME';
GRANT ALL PRIVILEGES ON ability_re.* TO 'ability_re'@'%';
FLUSH PRIVILEGES;
```

Navicat 连接信息：

```text
Host: localhost
Port: 3306
User: ability_re
Password: CHANGE_ME
Database: ability_re
```

### 方式二：使用 Docker 启动 MySQL

如果后续安装 Docker，可以执行：

```bash
docker compose up -d mysql
```

## 启动后端

需要 Java 21 和 Maven：

```bash
cd backend
mvn spring-boot:run
```

后端启动时 Flyway 会自动执行：

```text
backend/src/main/resources/db/migration/V1__init_schema.sql
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
POST http://localhost:18080/api/contact
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

## 当前功能

- 官网首页 Hero 区域
- 能力卡片展示
- 从后端 API 读取 MySQL 中的官网内容
- 联系表单提交到后端并保存进 MySQL
- 后端参数校验
- Flyway 初始化数据库表和种子内容
- 前后端基础测试
