package com.cw.rd.service;

import com.cw.rd.dto.auth.*;
import com.cw.rd.entity.Role;
import com.cw.rd.entity.User;
import com.cw.rd.exception.ApiException;
import com.cw.rd.repository.RoleRepository;
import com.cw.rd.repository.UserRepository;
import com.cw.rd.security.JwtProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtProvider jwtProvider;
    private final StringRedisTemplate redisTemplate;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw ApiException.badRequest("Пароли не совпадают");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw ApiException.badRequest("Email уже зарегистрирован");
        }

        Role customerRole = roleRepository.findByName("CUSTOMER")
                .orElseThrow(() -> ApiException.notFound("Роль не найдена"));

        User user = User.builder()
                .surname(request.getSurname())
                .name(request.getName())
                .patronymic(request.getPatronymic())
                .email(request.getEmail())
                .passhash(passwordEncoder.encode(request.getPassword()))
                .role(customerRole)
                .build();

        userRepository.save(user);

        String token = jwtProvider.generateToken(user.getId(), user.getEmail(), user.getRole().getName());
        return new AuthResponse(token, user.getId(), user.getRole().getName());
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmailAndIsDeletedFalse(request.getEmail())
                .orElseThrow(() -> ApiException.badRequest("Неверный email или пароль"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasshash())) {
            throw ApiException.badRequest("Неверный email или пароль");
        }

        String token = jwtProvider.generateToken(user.getId(), user.getEmail(), user.getRole().getName());
        return new AuthResponse(token, user.getId(), user.getRole().getName());
    }

    public void logout(String token) {
        if (token.startsWith("Bearer ")) {
            token = token.substring(7);
        }
        redisTemplate.opsForValue().set("bl:" + token, "1", 24, TimeUnit.HOURS);
    }
}
