package com.appsdeveloperblog.photoapp.api.album.domain.model;

import java.io.Serializable;

public record Album(
        Long id,
        Long userId,
        String name,
        String description
) implements Serializable {
}
