package com.abilityre.site;

import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 从多张内容表读取数据，并组装成前端页面需要的响应对象。 */
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
        // Hero 是首页必要内容；缺失时直接报错，避免悄悄渲染一个不完整首页。
        SiteSection hero = sectionRepository.findBySectionKey("hero")
                .orElseThrow(() -> new IllegalStateException("Hero section is missing"));

        // 数据库实体不直接暴露给前端，先映射成稳定的接口 DTO。
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

        // 主表保存文章元信息，正文块按 sortOrder 单独读取后再拼装。
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
