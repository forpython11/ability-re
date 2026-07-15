package com.abilityre.contact;

import org.springframework.data.jpa.repository.JpaRepository;

/** 联系消息的数据访问入口；基础增删改查由 Spring Data 自动生成。 */
public interface ContactMessageRepository extends JpaRepository<ContactMessage, Long> {
}
