package com.cw.rd.service;

import com.cw.rd.dto.user.*;
import com.cw.rd.entity.User;
import com.cw.rd.exception.ApiException;
import com.cw.rd.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public User getById(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> ApiException.notFound("Пользователь не найден"));
    }

    public UserResponse getProfile(Long userId) {
        User user = getById(userId);
        return toResponse(user);
    }

    @Transactional
    public UserResponse updateProfile(Long userId, UpdateProfileRequest request) {
        User user = getById(userId);

        if (request.getSurname() != null) user.setSurname(request.getSurname());
        if (request.getName() != null) user.setName(request.getName());
        if (request.getPatronymic() != null) user.setPatronymic(request.getPatronymic());

        return toResponse(userRepository.save(user));
    }

    @Transactional
    public void changePassword(Long userId, ChangePasswordRequest request) {
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw ApiException.badRequest("Пароли не совпадают");
        }

        User user = getById(userId);

        if (!passwordEncoder.matches(request.getCurrentPassword(), user.getPasshash())) {
            throw ApiException.badRequest("Неверный текущий пароль");
        }

        user.setPasshash(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);
    }

    public UserResponse toResponse(User user) {
        UserResponse response = new UserResponse();
        response.setId(user.getId());
        response.setSurname(user.getSurname());
        response.setName(user.getName());
        response.setPatronymic(user.getPatronymic());
        response.setEmail(user.getEmail());
        response.setRole(user.getRole().getName());
        response.setCreatedAt(user.getCreatedAt());
        return response;
    }

    public String getFullName(User user) {
        String name = user.getSurname() + " " + user.getName();
        if (user.getPatronymic() != null && !user.getPatronymic().isBlank()) {
            name += " " + user.getPatronymic();
        }
        return name;
    }
}
