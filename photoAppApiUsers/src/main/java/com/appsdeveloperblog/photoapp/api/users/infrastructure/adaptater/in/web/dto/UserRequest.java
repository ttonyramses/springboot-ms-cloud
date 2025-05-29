package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto;


import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record UserRequest(
        Long id,

        @NotNull(message="First name cannot be null")
        @Size(min=2, max=100, message="First name must be between 2 and 100 characters")
        String firstname,

        @NotNull(message="Last name cannot be null")
        @Size(min=2, max=100, message="Last name must be between 2 and 100 characters")
        String lastname,

        @NotNull(message="Password cannot be null")
        @Size(min=8, max=16, message="Password must be between 8 and 16 characters")
        String password,

        @NotNull(message="Email cannot be null")
        @Email(message="Email must be valid")
        @Size(min=5, max=150, message="Email must be between 5 and 150 characters")
        String email

) { }
