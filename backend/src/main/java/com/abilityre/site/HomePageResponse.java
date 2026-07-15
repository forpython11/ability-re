package com.abilityre.site;

import java.util.List;

/** 首页接口的数据结构；内部 record 分别对应 Hero、能力卡片和文章入口。 */
public record HomePageResponse(Hero hero, List<Feature> features, List<LearningRecordSummary> learningRecords) {
    public record Hero(String title, String subtitle) {
    }

    public record Feature(String title, String description, String icon) {
    }

    public record LearningRecordSummary(String slug, String title, String summary, String category) {
    }
}
