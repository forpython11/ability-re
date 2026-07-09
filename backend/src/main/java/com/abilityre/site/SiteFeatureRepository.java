package com.abilityre.site;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SiteFeatureRepository extends JpaRepository<SiteFeature, Long> {
    List<SiteFeature> findAllByOrderBySortOrderAsc();
}
