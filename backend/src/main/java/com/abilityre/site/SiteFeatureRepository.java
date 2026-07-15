package com.abilityre.site;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

/** 首页能力卡片的数据访问接口，方法名会被 Spring Data 解析成排序查询。 */
public interface SiteFeatureRepository extends JpaRepository<SiteFeature, Long> {
    List<SiteFeature> findAllByOrderBySortOrderAsc();
}
