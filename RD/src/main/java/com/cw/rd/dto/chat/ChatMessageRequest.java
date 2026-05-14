package com.cw.rd.dto.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class ChatMessageRequest {

    @NotNull
    private Long ticketId;

    @NotBlank
    @Size(max = 1000)
    private String text;
}
