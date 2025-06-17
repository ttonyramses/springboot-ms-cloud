package com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.out.persistence.jpa.repository;

import com.appsdeveloperblog.photoapp.api.album.application.port.out.AlbumRepository;
import com.appsdeveloperblog.photoapp.api.album.domain.model.Album;
import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.out.persistence.jpa.entity.AlbumEntity;
import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.out.persistence.jpa.mapper.AlbumEntityMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class JpaAlbumRepositoryAdapter implements AlbumRepository {

    private final JpaAlbumRepository jpaAlbumRepository;
    private final AlbumEntityMapper albumEntityMapper;

    public JpaAlbumRepositoryAdapter(JpaAlbumRepository jpaAlbumRepository, AlbumEntityMapper albumEntityMapper) {
        this.jpaAlbumRepository = jpaAlbumRepository;
        this.albumEntityMapper = albumEntityMapper;
    }

    @Override
    public Album save(Album album) {
        AlbumEntity albumEntity = albumEntityMapper.toEntity(album);
        var entity = jpaAlbumRepository.save(albumEntity);
        return albumEntityMapper.toDto(entity);
    }

    @Override
    public Optional<Album> findById(long id) {
        return jpaAlbumRepository.findById(id).map(albumEntityMapper::toDto);
    }

    @Override
    public List<Album> findAllByUserId(long userId) {
        return jpaAlbumRepository.findByUserId(userId).stream().map(albumEntityMapper::toDto).toList();
    }

    @Override
    public List<Album> findAll() {
        return jpaAlbumRepository.findAll().stream().map(albumEntityMapper::toDto).toList();
    }

    @Override
    public void deleteAlbum(long id) {
        jpaAlbumRepository.deleteById(id);

    }
}
