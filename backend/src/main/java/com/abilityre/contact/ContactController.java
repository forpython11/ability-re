package com.abilityre.contact;

import com.abilityre.common.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** 联系表单入口；当前站点不收集访客信息，因此接口明确返回 410。 */
@RestController
@RequestMapping("/api/contact")
public class ContactController {
    @PostMapping
    public ResponseEntity<ApiResponse<Void>> create() {
        // 保留固定入口可让旧前端或缓存明确知道功能已永久停用。
        return ResponseEntity
                .status(HttpStatus.GONE)
                .body(new ApiResponse<>(410, "contact form disabled", null));
    }
}
