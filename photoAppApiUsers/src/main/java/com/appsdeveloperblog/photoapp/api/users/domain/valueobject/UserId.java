package com.appsdeveloperblog.photoapp.api.users.domain.valueobject;

import java.util.UUID;

public record UserId(String value) {
    public static UserId random() {
        return new UserId(UUID.randomUUID().toString());
    }
}
