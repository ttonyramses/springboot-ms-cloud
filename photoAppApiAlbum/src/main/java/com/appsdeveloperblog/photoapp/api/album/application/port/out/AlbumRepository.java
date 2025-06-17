package com.appsdeveloperblog.photoapp.api.album.application.port.out;

import com.appsdeveloperblog.photoapp.api.album.domain.model.Album;

import java.util.List;
import java.util.Optional;

public interface AlbumRepository {
    Album save(Album album);
    Optional<Album> findById(long id);
    List<Album>findAllByUserId(long userId);
    List<Album> findAll();
    void deleteAlbum(long id);
}