package com.abilityre.site;

import java.time.LocalDate;
import java.util.List;

/** 一篇学习记录的完整接口数据，blocks 按顺序组成文章正文。 */
public record LearningRecordResponse(
        String slug,
        String title,
        String summary,
        String category,
        String environment,
        LocalDate publishedAt,
        List<Block> blocks) {
    /** 正文块可以是普通段落、步骤、问题、结果或代码示例。 */
    public record Block(String type, String heading, String body, String codeSample) {
    }
}
