package com.abilityre.contact;

import com.abilityre.common.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/contact")
public class ContactController {
    @PostMapping
    public ResponseEntity<ApiResponse<Void>> create() {
        return ResponseEntity
                .status(HttpStatus.GONE)
                .body(new ApiResponse<>(410, "contact form disabled", null));
    }
}
