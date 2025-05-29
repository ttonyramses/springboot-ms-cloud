package com.appsdeveloperblog.photoapp.api.users.domain.model;

import java.io.Serializable;

public record User(
        Long id,
        String firstname,
        String lastname,
        String email,
        String encryptedPassword
) implements Serializable {
}

