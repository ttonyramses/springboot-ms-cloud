package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.out.persistence.jpa.repository;

import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.out.persistence.jpa.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface JpaUserRepository extends JpaRepository<UserEntity, Long> {
    Optional<UserEntity> findByEmail(String email);
}
