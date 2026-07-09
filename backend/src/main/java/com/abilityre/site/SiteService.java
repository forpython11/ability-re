package com.abilityre.site;

import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SiteService {
    private final SiteSectionRepository sectionRepository;
    private final SiteFeatureRepository featureRepository;

    public SiteService(SiteSectionRepository sectionRepository, SiteFeatureRepository featureRepository) {
        this.sectionRepository = sectionRepository;
        this.featureRepository = featureRepository;
    }

    @Transactional(readOnly = true)
    public HomePageResponse getHomePage() {
        SiteSection hero = sectionRepository.findBySectionKey("hero")
                .orElseThrow(() -> new IllegalStateException("Hero section is missing"));
        List<HomePageResponse.Feature> features = featureRepository.findAllByOrderBySortOrderAsc().stream()
                .map(feature -> new HomePageResponse.Feature(
                        feature.getTitle(),
                        feature.getDescription(),
                        feature.getIcon()))
                .toList();

        return new HomePageResponse(
                new HomePageResponse.Hero(hero.getTitle(), hero.getSubtitle()),
                features);
    }
}
