package com.appsdeveloperblog.photoapp.api.album.application.service;

import com.appsdeveloperblog.photoapp.api.album.application.port.in.AlbumUseCase;
import com.appsdeveloperblog.photoapp.api.album.application.port.out.AlbumRepository;
import com.appsdeveloperblog.photoapp.api.album.domain.exception.AlbumNotFoundException;
import com.appsdeveloperblog.photoapp.api.album.domain.model.Album;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class AlbumApplicationService implements AlbumUseCase {

    private final AlbumRepository albumRepository;

    public AlbumApplicationService(AlbumRepository albumRepository) {
        this.albumRepository = albumRepository;
    }

    @Override
    public Album createAlbum(Album album) {

        return albumRepository.save(album);
    }

    @Override
    public Optional<Album> findAlbumById(long id) {
        return Optional.ofNullable(albumRepository.findById(id).orElseThrow(() -> new AlbumNotFoundException(" for id :" + id)));
    }

    @Override
    public List<Album> findAllAlbumByUserId(long userId) {
        return albumRepository.findAllByUserId(userId);
    }

    @Override
    public List<Album> findAllAlbum() {
        return albumRepository.findAll();
    }

    @Override
    public void deleteAlbumById(long id) {
        albumRepository.deleteAlbum(id);
    }
}
