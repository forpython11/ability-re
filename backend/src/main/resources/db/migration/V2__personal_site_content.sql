UPDATE site_sections
SET title = '能力重构个人技术记录',
    subtitle = '这里记录个人在 SvelteKit、Spring Boot、MySQL 和服务器部署中的学习过程与项目实践。',
    sort_order = 1
WHERE section_key = 'hero';

UPDATE site_sections
SET title = '一个面向个人学习沉淀的网站',
    subtitle = '本站由个人维护，用来整理前端框架、Java 后端、数据库和部署相关的学习过程。',
    sort_order = 2
WHERE section_key = 'about';

UPDATE site_features
SET title = '前端学习笔记',
    description = '整理 SvelteKit、TypeScript、页面结构和交互体验相关的学习记录。',
    icon = 'layers',
    sort_order = 1
WHERE sort_order = 1;

UPDATE site_features
SET title = '后端工程实践',
    description = '记录 Spring Boot、接口设计、参数校验和自动化测试的实践过程。',
    icon = 'database',
    sort_order = 2
WHERE sort_order = 2;

UPDATE site_features
SET title = '部署与数据库记录',
    description = '沉淀 Linux、Docker、MySQL、Flyway 和日常部署排查经验。',
    icon = 'sparkles',
    sort_order = 3
WHERE sort_order = 3;
