package com.abilityre.site;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** 首页大区块的数据库实体，例如 hero 和 about。 */
@Entity
@Table(name = "site_sections")
public class SiteSection {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "section_key", nullable = false, unique = true)
    private String sectionKey;

    @Column(nullable = false)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String subtitle;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    /** 仅供 JPA 使用。 */
    protected SiteSection() {
    }

    public Long getId() {
        return id;
    }

    public String getSectionKey() {
        return sectionKey;
    }

    public String getTitle() {
        return title;
    }

    public String getSubtitle() {
        return subtitle;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }
}
