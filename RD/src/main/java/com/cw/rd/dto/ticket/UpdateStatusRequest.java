package com.cw.rd.dto.ticket;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateStatusRequest {

    @NotBlank
    private String status;

    @Size(max = 500)
    private String comment;
}
