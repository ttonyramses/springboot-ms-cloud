package com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.mapper;

import com.appsdeveloperblog.photoapp.api.album.domain.model.Album;
import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.dto.AlbumRequest;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface AlbumWebMapper {

    @Mapping(target = "id", ignore = true) // L'ID sera généré automatiquement
    @Mapping(target = "userId", ignore = true) // Sera défini dans le service
    Album toDomain (AlbumRequest request);


}
