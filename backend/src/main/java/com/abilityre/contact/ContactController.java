package com.abilityre.contact;

import com.abilityre.common.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/contact")
public class ContactController {
    private final ContactMessageRepository repository;

    public ContactController(ContactMessageRepository repository) {
        this.repository = repository;
    }

    @PostMapping
    public ApiResponse<ContactResponse> create(@Valid @RequestBody ContactRequest request) {
        ContactMessage saved = repository.save(new ContactMessage(
                request.name(),
                request.email(),
                request.company(),
                request.message()));
        return ApiResponse.success(new ContactResponse(saved.getId(), saved.getStatus()));
    }
}
