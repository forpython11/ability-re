CREATE TABLE site_sections (
    id BIGINT NOT NULL AUTO_INCREMENT,
    section_key VARCHAR(80) NOT NULL,
    title VARCHAR(160) NOT NULL,
    subtitle TEXT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uk_site_sections_section_key (section_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE site_features (
    id BIGINT NOT NULL AUTO_INCREMENT,
    title VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(80) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE contact_messages (
    id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(80) NOT NULL,
    email VARCHAR(160) NOT NULL,
    company VARCHAR(160),
    message TEXT NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'NEW',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO site_sections (section_key, title, subtitle, sort_order) VALUES
('hero', '用新技术重构你的数字能力', 'Ability Re 是一个前后端分离官网示例，使用 SvelteKit、Spring Boot 和 MySQL 打造现代化展示与线索收集体验。', 1),
('about', '从官网开始，建立可持续演进的数字入口', '项目保留清晰的前后端边界、数据库迁移和自动化测试，为后续扩展后台管理、内容管理和权限系统打基础。', 2);

INSERT INTO site_features (title, description, icon, sort_order) VALUES
('前后端分离', 'SvelteKit 负责页面体验，Spring Boot 负责业务 API，边界清晰，方便团队协作。', 'layers', 1),
('数据库驱动', 'MySQL 保存官网内容与联系线索，Flyway 管理表结构版本，Navicat 可直接连接查看数据。', 'database', 2),
('工程化基础', 'TypeScript、Java 21、测试、配置隔离和数据库脚本作为项目起点。', 'sparkles', 3);
