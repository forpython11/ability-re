package com.abilityre.site;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

/** 查询指定文章的全部正文块，并按页面展示顺序返回。 */
public interface SiteLearningRecordBlockRepository extends JpaRepository<SiteLearningRecordBlock, Long> {
    List<SiteLearningRecordBlock> findAllByRecordOrderBySortOrderAsc(SiteLearningRecord record);
}
