package com.abilityre.site;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SiteLearningRecordBlockRepository extends JpaRepository<SiteLearningRecordBlock, Long> {
    List<SiteLearningRecordBlock> findAllByRecordOrderBySortOrderAsc(SiteLearningRecord record);
}
