package com.abilityre.site;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;

/** 学习记录的文章主表实体；正文内容拆分保存在 SiteLearningRecordBlock 中。 */
@Entity
@Table(name = "site_learning_records")
public class SiteLearningRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String slug;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String summary;

    @Column(nullable = false)
    private String category;

    @Column(nullable = false)
    private String environment;

    @Column(name = "published_at", nullable = false)
    private LocalDate publishedAt;

    /** 仅供 JPA 使用。 */
    protected SiteLearningRecord() {
    }

    public Long getId() {
        return id;
    }

    public String getSlug() {
        return slug;
    }

    public String getTitle() {
        return title;
    }

    public String getSummary() {
        return summary;
    }

    public String getCategory() {
        return category;
    }

    public String getEnvironment() {
        return environment;
    }

    public LocalDate getPublishedAt() {
        return publishedAt;
    }
}
