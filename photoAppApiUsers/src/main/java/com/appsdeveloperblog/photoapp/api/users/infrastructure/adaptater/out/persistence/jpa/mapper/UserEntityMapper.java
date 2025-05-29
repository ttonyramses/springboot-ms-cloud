package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.out.persistence.jpa.mapper;

import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.out.persistence.jpa.entity.UserEntity;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface UserEntityMapper {
    UserEntity toEntity(User user);
    User toDto(UserEntity entity);

}
