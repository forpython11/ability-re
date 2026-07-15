package com.abilityre.site;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** 学习记录主表的数据访问接口。 */
public interface SiteLearningRecordRepository extends JpaRepository<SiteLearningRecord, Long> {
    /** slug 是文章 URL 中稳定、唯一的标识。 */
    Optional<SiteLearningRecord> findBySlug(String slug);

    /** 首页总是优先展示发布日期较新的记录。 */
    List<SiteLearningRecord> findAllByOrderByPublishedAtDesc();
}
