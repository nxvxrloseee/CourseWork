package com.cw.rd.dto.user;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class UserResponse {
    private Long id;
    private String surname;
    private String name;
    private String patronymic;
    private String email;
    private String role;
    private LocalDateTime createdAt;
}
