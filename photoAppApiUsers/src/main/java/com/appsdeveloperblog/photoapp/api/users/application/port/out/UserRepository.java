package com.appsdeveloperblog.photoapp.api.users.application.port.out;

import com.appsdeveloperblog.photoapp.api.users.domain.model.User;

import java.util.List;
import java.util.Optional;

public interface UserRepository {
    User save(User user);
    Optional<User> findById(long id);
    Optional<User> findByEmail(String email);
    List<User> findAll();
    void deleteUser(long id);
}
