package com.abilityre.site;

import com.abilityre.common.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/site")
public class SiteController {
    private final SiteService siteService;

    public SiteController(SiteService siteService) {
        this.siteService = siteService;
    }

    @GetMapping("/home")
    public ApiResponse<HomePageResponse> home() {
        return ApiResponse.success(siteService.getHomePage());
    }

    @GetMapping("/learning-records/{slug}")
    public ApiResponse<LearningRecordResponse> learningRecord(@PathVariable String slug) {
        return ApiResponse.success(siteService.getLearningRecord(slug));
    }
}
