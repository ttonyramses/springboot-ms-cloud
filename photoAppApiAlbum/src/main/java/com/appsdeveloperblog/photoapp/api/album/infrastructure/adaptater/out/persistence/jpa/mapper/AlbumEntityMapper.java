package com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.out.persistence.jpa.mapper;

import com.appsdeveloperblog.photoapp.api.album.domain.model.Album;
import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.out.persistence.jpa.entity.AlbumEntity;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface AlbumEntityMapper {

    AlbumEntity toEntity(Album album);

    Album toDto(AlbumEntity entity);
}
