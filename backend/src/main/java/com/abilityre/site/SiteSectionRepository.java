package com.abilityre.site;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

/** 根据稳定的 sectionKey 查询首页区块。 */
public interface SiteSectionRepository extends JpaRepository<SiteSection, Long> {
    Optional<SiteSection> findBySectionKey(String sectionKey);
}
