package com.appsdeveloperblog.photoapp.api.users.application.port.in;

import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import org.springframework.security.core.userdetails.UserDetailsService;

import java.util.List;
import java.util.Optional;

public interface UserUseCase extends UserDetailsService {
    User createUser(User user);
    Optional<User> findUserById(long id);
    Optional<User> findUserByEmail(String email);
    List<User> findAllUser();
    void deleteUserById(long id);

}
