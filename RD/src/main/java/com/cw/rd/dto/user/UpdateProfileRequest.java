package com.cw.rd.dto.user;

import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateProfileRequest {

    @Size(min = 2, max = 50)
    private String surname;

    @Size(min = 2, max = 50)
    private String name;

    @Size(max = 50)
    private String patronymic;
}
