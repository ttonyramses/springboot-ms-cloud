package com.appsdeveloperblog.photoapp.api.album.application.port.in;

import com.appsdeveloperblog.photoapp.api.album.domain.model.Album;

import java.util.List;
import java.util.Optional;

public interface AlbumUseCase {
    Album createAlbum(Album album);

    Optional<Album> findAlbumById(long id);

    List<Album> findAllAlbumByUserId(long userId);

    List<Album> findAllAlbum();

    void deleteAlbumById(long id);
}