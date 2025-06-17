package com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AlbumRequest(
        @NotNull(message="Name cannot be null")
        @Size(min=2, max=200, message="First name must be between 2 and 200 characters")
        String name,

        String description
) {
}
