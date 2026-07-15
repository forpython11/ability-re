package com.abilityre.contact;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;

/** 联系消息的数据库实体。表仍保留，用于兼容已有迁移，但公开写入接口已停用。 */
@Entity
@Table(name = "contact_messages")
public class ContactMessage {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String email;

    private String company;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String message;

    @Column(nullable = false)
    private String status = "NEW";

    @Column(name = "created_at", nullable = false, insertable = false, updatable = false)
    private OffsetDateTime createdAt;

    /** JPA 通过反射创建实体时需要无参构造器，业务代码不应直接调用。 */
    protected ContactMessage() {
    }

    public ContactMessage(String name, String email, String company, String message) {
        this.name = name;
        this.email = email;
        this.company = company;
        this.message = message;
    }

    public Long getId() {
        return id;
    }

    public String getStatus() {
        return status;
    }
}
