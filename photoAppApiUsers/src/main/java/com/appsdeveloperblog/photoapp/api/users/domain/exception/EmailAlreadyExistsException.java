package com.appsdeveloperblog.photoapp.api.users.domain.exception;

public class EmailAlreadyExistsException extends RuntimeException {
    public EmailAlreadyExistsException(String email) {
        super("User email already exist : " + email);
    }
}
