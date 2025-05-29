package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.mapper;


import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.UserRequest;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.in.web.dto.UserResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;


@Mapper(componentModel = "spring")
public interface UserWebMapper {


    @Mapping(target = "encryptedPassword", source = "password", qualifiedByName = "encryptPassword")
    User toDomain(UserRequest request);

    UserResponse fromDomain(User user);

    @Named("encryptPassword")
    default String encryptPassword(String password) {
        return new BCryptPasswordEncoder().encode(password);
    }

}