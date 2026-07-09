package com.abilityre.site;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SiteSectionRepository extends JpaRepository<SiteSection, Long> {
    Optional<SiteSection> findBySectionKey(String sectionKey);
}
