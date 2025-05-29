package com.appsdeveloperblog.photoapp.api.users.application.service;

import com.appsdeveloperblog.photoapp.api.users.application.port.in.UserUseCase;
import com.appsdeveloperblog.photoapp.api.users.application.port.out.UserRepository;
import com.appsdeveloperblog.photoapp.api.users.domain.exception.EmailAlreadyExistsException;
import com.appsdeveloperblog.photoapp.api.users.domain.exception.UserNotFoundException;
import com.appsdeveloperblog.photoapp.api.users.domain.model.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Service
public class UserApplicationService implements UserUseCase {

    private final UserRepository userRepository;

    public UserApplicationService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public User createUser(User user) {
        if (userRepository.findByEmail(user.email()).isPresent()) {
            throw new EmailAlreadyExistsException(user.email());
        }
        return userRepository.save(user);
    }

    @Override
    public Optional<User> findUserById(long id) {
        return Optional.ofNullable(userRepository.findById(id)
                .orElseThrow(() -> new UserNotFoundException(" for id : " + id)));
    }

    @Override
    public Optional<User> findUserByEmail(String email) {
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Email cannot be null or empty");
        }

        return Optional.ofNullable(userRepository.findByEmail(email)
                .orElseThrow(() -> new UserNotFoundException("for email : " + email)));
    }

    @Override
    public List<User> findAllUser() {
        return userRepository.findAll();
    }

    @Override
    public void deleteUserById(long id) {
        userRepository.deleteUser(id);
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = findUserByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found with email: " + email));

        return new org.springframework.security.core.userdetails.User(
                user.email(),                       // username
                user.encryptedPassword(),           // password
                true,                               // enabled
                true,                               // accountNonExpired
                true,                               // credentialsNonExpired
                true,                               // accountNonLocked
                Collections.emptyList()             // authorities (empty for now)
        );
    }
}
