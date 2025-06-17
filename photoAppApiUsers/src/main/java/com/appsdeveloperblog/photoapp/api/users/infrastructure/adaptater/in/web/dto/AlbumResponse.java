package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto;

import java.io.Serializable;

public record AlbumResponse(
        Long id,
        Long userId,
        String name,
        String description
) implements Serializable {
}
