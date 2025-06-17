package com.appsdeveloperblog.photoapp.api.album.domain.exception;

public class AlbumNotFoundException extends RuntimeException {
    public AlbumNotFoundException(String message) {
        super("Album not found: " + message);
    }
}