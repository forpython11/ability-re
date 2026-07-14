package com.abilityre.site;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SiteLearningRecordRepository extends JpaRepository<SiteLearningRecord, Long> {
    Optional<SiteLearningRecord> findBySlug(String slug);

    List<SiteLearningRecord> findAllByOrderByPublishedAtDesc();
}
