package com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.out.persistence.jpa.repository;

import com.appsdeveloperblog.photoapp.api.users.application.port.out.UserRepository;
import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.out.persistence.jpa.entity.UserEntity;
import com.appsdeveloperblog.photoapp.api.users.infrastructure.adaptater.out.persistence.jpa.mapper.UserEntityMapper;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Repository
public class JpaUserRepositoryAdapter implements UserRepository {

    private final JpaUserRepository jpaRepository;
    private final UserEntityMapper userEntityMapper;


    public JpaUserRepositoryAdapter(JpaUserRepository jpaRepository, UserEntityMapper userEntityMapper) {
        this.jpaRepository = jpaRepository;
        this.userEntityMapper = userEntityMapper;
    }

    @Override
    public User save(User user) {
        UserEntity entity = userEntityMapper.toEntity(user);
        entity = jpaRepository.save(entity);
        return userEntityMapper.toDto(entity);
    }

    @Override
    public Optional<User> findById(long id) {
        return jpaRepository.findById(id).map(userEntityMapper::toDto);
    }

    @Override
    public Optional<User> findByEmail(String email) {
        return jpaRepository.findByEmail(email).map(userEntityMapper::toDto);
    }

    @Override
    public List<User> findAll() {
        return jpaRepository.findAll().stream()
                .map(userEntityMapper::toDto)
                .collect(Collectors.toList());
    }

    @Override
    public void deleteUser(long id) {
        jpaRepository.deleteById(id);
    }
}