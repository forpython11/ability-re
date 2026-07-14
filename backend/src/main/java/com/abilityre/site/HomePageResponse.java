package com.abilityre.site;

import java.util.List;

public record HomePageResponse(Hero hero, List<Feature> features, List<LearningRecordSummary> learningRecords) {
    public record Hero(String title, String subtitle) {
    }

    public record Feature(String title, String description, String icon) {
    }

    public record LearningRecordSummary(String slug, String title, String summary, String category) {
    }
}
