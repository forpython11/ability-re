package com.abilityre.contact;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ContactRequest(
        @NotBlank @Size(max = 80) String name,
        @NotBlank @Email @Size(max = 160) String email,
        @Size(max = 160) String company,
        @NotBlank @Size(min = 10, max = 2000) String message
) {
}
