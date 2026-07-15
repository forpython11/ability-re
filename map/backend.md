# 后端文件导览

后端使用 Java 21、Spring Boot、Spring Data JPA、Flyway 和 MySQL。建议先看[后端架构图](../docs/architecture/backend.md)，再从 Controller 沿 Service、Repository 读到数据库。

## 后端 CI 与发布

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `.woodpecker/backend.yml` | 手动执行 Maven 测试、JAR 打包、上传和部署 | 后端构建命令、发布包或 Secret 变化时 |
| `.woodpecker/deploy-backend.sh` | 在服务器校验发布包、原子替换 JAR、重建容器并等待健康检查 | 后端服务器部署步骤变化时 |
| `.woodpecker/maven-settings.xml` | 让 CI 通过阿里云 Maven 镜像下载 Central 依赖 | Maven 镜像或仓库策略变化时 |

公共 SSH 指纹、Compose 和 Nginx 说明见[项目公共文件导览](README.md)。

## 构建与环境配置

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `backend/.env.example` | 后端本地环境变量模板，包含数据库连接、端口和 CORS 来源 | 新增 Spring 环境变量时 |
| `backend/pom.xml` | Maven 配置，声明 Java 21、Spring Boot、JPA、Flyway、MySQL 和测试依赖 | 增删依赖或构建插件时 |
| `backend/src/main/resources/application.yml` | 数据库、JPA、Flyway、端口、健康探针和 CORS 主配置 | 调整运行参数时 |
| `backend/src/test/resources/application-test.yml` | 使用 H2 MySQL 兼容模式的测试配置 | 修改测试数据库或测试专用参数时 |

## 启动与公共模块

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `backend/src/main/java/com/abilityre/AbilityReApplication.java` | Spring Boot 主入口，启动组件扫描和自动配置 | 通常不需要修改 |
| `backend/src/main/java/com/abilityre/common/ApiResponse.java` | 所有业务接口共用的 `{ code, message, data }` 外层结构 | 修改全局 API 协议时 |
| `backend/src/main/java/com/abilityre/common/GlobalExceptionHandler.java` | 把参数校验异常转换成字段错误响应 | 增加新的全局异常映射时 |
| `backend/src/main/java/com/abilityre/config/CorsConfig.java` | 为 `/api/**` 配置允许的浏览器跨域来源和方法 | 前端域名或 API 方法变化时 |

## 站点内容接口与业务层

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `backend/src/main/java/com/abilityre/site/SiteController.java` | 提供首页和学习记录详情 HTTP API | 新增内容接口时 |
| `backend/src/main/java/com/abilityre/site/SiteService.java` | 查询多张表，把实体组装成前端需要的 DTO | 页面业务规则或组合方式变化时 |
| `backend/src/main/java/com/abilityre/site/HomePageResponse.java` | 定义首页 Hero、能力卡片和文章摘要响应 | 首页 API 字段变化时 |
| `backend/src/main/java/com/abilityre/site/LearningRecordResponse.java` | 定义文章元信息和正文块响应 | 文章 API 字段变化时 |

## 站点内容实体与 Repository

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `backend/src/main/java/com/abilityre/site/SiteSection.java` | 映射 `site_sections`，保存 Hero/About 等首页区块 | 区块表字段变化时 |
| `backend/src/main/java/com/abilityre/site/SiteSectionRepository.java` | 根据 `sectionKey` 查询首页区块 | 增加区块查询方式时 |
| `backend/src/main/java/com/abilityre/site/SiteFeature.java` | 映射 `site_features`，保存首页能力卡片 | 卡片表字段变化时 |
| `backend/src/main/java/com/abilityre/site/SiteFeatureRepository.java` | 按 `sortOrder` 查询能力卡片 | 卡片排序或过滤变化时 |
| `backend/src/main/java/com/abilityre/site/SiteLearningRecord.java` | 映射文章主表，保存 slug、标题、摘要、分类、环境和日期 | 文章元信息字段变化时 |
| `backend/src/main/java/com/abilityre/site/SiteLearningRecordRepository.java` | 按 slug 查询文章，并按发布日期查询列表 | 文章检索规则变化时 |
| `backend/src/main/java/com/abilityre/site/SiteLearningRecordBlock.java` | 映射正文块表，保存类型、标题、正文、代码和顺序 | 正文块结构变化时 |
| `backend/src/main/java/com/abilityre/site/SiteLearningRecordBlockRepository.java` | 按顺序查询某篇文章的全部正文块 | 正文查询方式变化时 |

## 健康检查与停用的联系模块

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `backend/src/main/java/com/abilityre/health/HealthController.java` | 执行 `SELECT 1` 检查数据库并返回业务健康状态 | 健康标准变化时 |
| `backend/src/main/java/com/abilityre/contact/ContactController.java` | 当前固定返回 HTTP 410，表示联系功能已停用 | 重新开放或彻底移除联系功能时 |
| `backend/src/main/java/com/abilityre/contact/ContactMessage.java` | 映射历史联系消息表 | 联系消息表字段变化时 |
| `backend/src/main/java/com/abilityre/contact/ContactMessageRepository.java` | 联系消息的 Spring Data 数据入口 | 重新启用消息查询或保存时 |
| `backend/src/main/java/com/abilityre/contact/ContactRequest.java` | 联系表单原请求结构和校验规则 | 重新启用表单或调整输入时 |
| `backend/src/main/java/com/abilityre/contact/ContactResponse.java` | 联系消息原成功响应结构 | 重新启用表单且响应变化时 |

## 数据库迁移

Flyway 会记录已执行脚本的 checksum。已上线迁移不要直接修改，即使只加注释也可能导致启动失败；数据库变化应新增下一个版本文件。

| 文件 | 作用 | 修改规则 |
| --- | --- | --- |
| `backend/src/main/resources/db/migration/V1__init_schema.sql` | 创建首页区块、能力卡片、联系消息表和初始数据 | 已执行后不再修改 |
| `backend/src/main/resources/db/migration/V2__personal_site_content.sql` | 把示例官网文字更新为个人技术记录 | 已执行后不再修改 |
| `backend/src/main/resources/db/migration/V3__learning_records.sql` | 创建文章主表和正文块表，写入首篇文章 | 已执行后不再修改 |
| `backend/src/main/resources/db/migration/V4__update_learning_record_deployment_entry.sql` | 扩充首篇文章的域名、Nginx、备案和 HTTPS 内容 | 已执行后不再修改 |

## 后端测试

| 文件 | 作用 | 通常什么时候修改 |
| --- | --- | --- |
| `backend/src/test/java/com/abilityre/site/SiteControllerTest.java` | 验证首页/文章 API、迁移数据和 CORS 预检 | 内容 API 或初始数据变化时 |
| `backend/src/test/java/com/abilityre/health/HealthControllerTest.java` | 验证业务健康接口、Actuator 和数据库故障分支 | 健康检查逻辑变化时 |
| `backend/src/test/java/com/abilityre/contact/ContactControllerTest.java` | 验证联系接口对任何输入都保持停用 | 联系接口行为变化时 |

## 一次首页 API 的阅读路线

1. `SiteController.home()` 接收 `/api/site/home`。
2. `SiteService.getHomePage()` 组织查询和 DTO 映射。
3. `SiteSectionRepository`、`SiteFeatureRepository` 和 `SiteLearningRecordRepository` 查询数据库。
4. 对应 JPA Entity 描述 Java 字段与 MySQL 表的关系。
5. `HomePageResponse` 定义返回给前端的字段。
6. `ApiResponse.success()` 增加统一响应外层。

## 常见后端任务

| 想做的事情 | 先修改 | 通常还会修改 |
| --- | --- | --- |
| 新增 API | 对应 `*Controller.java` | Service、Response、测试 |
| 增加业务规则 | `SiteService.java` | Repository 和测试 |
| 增加数据库字段 | 新 Flyway migration | Entity、DTO、前端类型、测试 |
| 修改首页数据 | 新 Flyway migration | Service 或 Response |
| 修改健康判断 | `HealthController.java` | 测试和部署脚本 |
| 修改后端部署 | `.woodpecker/backend.yml` | `deploy-backend.sh`、Compose |

## 推荐阅读顺序

`AbilityReApplication.java` -> `SiteController.java` -> `SiteService.java` -> `HomePageResponse.java` -> Repository -> Entity -> Flyway SQL -> Controller 测试
