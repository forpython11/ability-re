package com.abilityre.site;

import java.time.LocalDate;
import java.util.List;

public record LearningRecordResponse(
        String slug,
        String title,
        String summary,
        String category,
        String environment,
        LocalDate publishedAt,
        List<Block> blocks) {
    public record Block(String type, String heading, String body, String codeSample) {
    }
}
