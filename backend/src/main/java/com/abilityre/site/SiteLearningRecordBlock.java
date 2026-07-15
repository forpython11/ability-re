package com.abilityre.site;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

/** 学习记录的一个正文块；多条记录按 sortOrder 拼成完整文章。 */
@Entity
@Table(name = "site_learning_record_blocks")
public class SiteLearningRecordBlock {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "record_id", nullable = false)
    // 多个正文块属于同一篇学习记录，数据库外键保证文章删除时关系仍一致。
    private SiteLearningRecord record;

    @Column(name = "block_type", nullable = false)
    private String blockType;

    @Column(nullable = false)
    private String heading;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    @Column(name = "code_sample", columnDefinition = "TEXT")
    private String codeSample;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    /** 仅供 JPA 使用。 */
    protected SiteLearningRecordBlock() {
    }

    public String getBlockType() {
        return blockType;
    }

    public String getHeading() {
        return heading;
    }

    public String getBody() {
        return body;
    }

    public String getCodeSample() {
        return codeSample;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }
}
