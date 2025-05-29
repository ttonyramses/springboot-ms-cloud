package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto;

import java.io.Serializable;

public record UserResponse(long id, String email, String firstname, String lastname) implements Serializable {}