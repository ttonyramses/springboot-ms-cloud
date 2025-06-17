package com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.out.persistence.jpa.repository;

import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.out.persistence.jpa.entity.AlbumEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface JpaAlbumRepository extends JpaRepository<AlbumEntity, Long> {
    List<AlbumEntity> findByUserId(Long userId);
}
