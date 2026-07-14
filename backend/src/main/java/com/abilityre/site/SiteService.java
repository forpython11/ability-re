package com.abilityre.site;

import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SiteService {
    private final SiteSectionRepository sectionRepository;
    private final SiteFeatureRepository featureRepository;
    private final SiteLearningRecordRepository learningRecordRepository;
    private final SiteLearningRecordBlockRepository learningRecordBlockRepository;

    public SiteService(
            SiteSectionRepository sectionRepository,
            SiteFeatureRepository featureRepository,
            SiteLearningRecordRepository learningRecordRepository,
            SiteLearningRecordBlockRepository learningRecordBlockRepository) {
        this.sectionRepository = sectionRepository;
        this.featureRepository = featureRepository;
        this.learningRecordRepository = learningRecordRepository;
        this.learningRecordBlockRepository = learningRecordBlockRepository;
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
        List<HomePageResponse.LearningRecordSummary> learningRecords = learningRecordRepository.findAllByOrderByPublishedAtDesc()
                .stream()
                .map(record -> new HomePageResponse.LearningRecordSummary(
                        record.getSlug(),
                        record.getTitle(),
                        record.getSummary(),
                        record.getCategory()))
                .toList();

        return new HomePageResponse(
                new HomePageResponse.Hero(hero.getTitle(), hero.getSubtitle()),
                features,
                learningRecords);
    }

    @Transactional(readOnly = true)
    public LearningRecordResponse getLearningRecord(String slug) {
        SiteLearningRecord record = learningRecordRepository.findBySlug(slug)
                .orElseThrow(() -> new IllegalArgumentException("Learning record is missing: " + slug));
        List<LearningRecordResponse.Block> blocks = learningRecordBlockRepository.findAllByRecordOrderBySortOrderAsc(record)
                .stream()
                .map(block -> new LearningRecordResponse.Block(
                        block.getBlockType(),
                        block.getHeading(),
                        block.getBody(),
                        block.getCodeSample()))
                .toList();

        return new LearningRecordResponse(
                record.getSlug(),
                record.getTitle(),
                record.getSummary(),
                record.getCategory(),
                record.getEnvironment(),
                record.getPublishedAt(),
                blocks);
    }
}
