package com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web;

import com.appsdeveloperblog.photoapp.api.album.application.port.in.AlbumUseCase;
import com.appsdeveloperblog.photoapp.api.album.domain.model.Album;
import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.dto.AlbumRequest;
import com.appsdeveloperblog.photoapp.api.album.infrastructure.adaptater.in.web.mapper.AlbumWebMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users/{userId}/albums")
@Slf4j
public class AlbumController {

    private final AlbumUseCase albumUseCase;
    private final AlbumWebMapper albumWebMapper;

    public AlbumController(AlbumUseCase albumUseCase, AlbumWebMapper albumWebMapper) {
        this.albumUseCase = albumUseCase;
        this.albumWebMapper = albumWebMapper;
    }

    @GetMapping
    public ResponseEntity<List<Album>> findAllAlbumByUserId(@PathVariable("userId")  Long userId) {
        List<Album> allAlbumByUserId = albumUseCase.findAllAlbumByUserId(userId);
        return new ResponseEntity<>(allAlbumByUserId, HttpStatus.OK);
    }

    @PostMapping
    public ResponseEntity<Album> createAlbumById(@PathVariable("userId")  Long userId, @RequestBody AlbumRequest request) {
        var albumTemp = albumWebMapper.toDomain(request);
        var album = new Album(null, userId, albumTemp.name(), albumTemp.description());
        album = albumUseCase.createAlbum(album);
        return new ResponseEntity<>(album,  HttpStatus.CREATED);
    }
}
